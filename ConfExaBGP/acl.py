#!/usr/bin/env python

import os
import sys
import time
#from redis import Redis
#from rq import Queue
import json
from StringIO import StringIO
import pprint

# apt-get install -y python-redis python-pip
# pip install rq

# Run worker:
# rqworker  --path /usr/src/fastnetmon/src/scripts
exabgp_log = open("/tmp/exabgp.log", "a")

#import firewall_queue

#q = Queue(connection=Redis())


import subprocess
import pprint
import multiprocessing
import logging
import os

logging.basicConfig(filename='/tmp/firewall_queue_worker.log', level=logging.INFO)
#logging.basicConfig(filename='/var/log/firewall_queue_worker.log', level=logging.INFO)
logger = logging.getLogger(__name__)

# netmap-ipfw or iptables
firewall_backend = 'iptables'


firewall_comment_text = "Received from: "

# u'destination-ipv4': [u'10.0.0.2/32'],
# u'destination-port': [u'=3128'],
# u'protocol': [u'=tcp'],
# u'source-ipv4': [u'10.0.0.1/32'],
# u'string': u'flow destination-ipv4 10.0.0.2/32 source-ipv4 10.0.0.1/32 protocol =tcp destination-port =3128'}

class AbstractFirewall:
    def generate_rules(self, peer_ip, pyflow_list, policy):
        generated_rules = []
        for pyflow_rule in pyflow_list:
            flow_is_correct = self.check_pyflow_rule_correctness(pyflow_rule)

            if not flow_is_correct:
                return

            generated_rules.append(self.generate_rule(peer_ip, pyflow_rule, policy))

        return generated_rules
    def check_pyflow_rule_correctness(self, pyflow_rule):
        allowed_actions = [ 'allow', 'deny' ]
        allowed_protocols = [ 'udp', 'tcp', 'all', 'icmp' ]

        if not pyflow_rule['action'] in allowed_actions:
            logger.info("Bad action: " + pyflow_rule['action'])
            return False

        if not pyflow_rule['protocol'] in allowed_protocols:
            logger.info("Bad protocol: " + pyflow_rule['protocol'])
            return False

        if len (pyflow_rule['source_port']) > 0 and not pyflow_rule['source_port'].isdigit():
            logger.warning("Bad source port format")
            return False

        if len (pyflow_rule['packet_length']) > 0 and not pyflow_rule['packet_length'].isdigit():
            logger.warning("Bad packet length format")
            return False

        if len (pyflow_rule['target_port']) > 0 and not pyflow_rule['target_port'].isdigit():
            return "Bad target port: " + pyflow_rule['target_port']
            return False

        return True

class Iptables(AbstractFirewall):
    def __init__(self):
        self.iptables_path = '/sbin/iptables'
        # In some cases we could work on INPUT/OUTPUT
        #self.working_chain = 'FORWARD'
        self.working_chain = 'INPUT'
    def flush_rules(self, peer_ip, pyflow_list):
        # iptables -nvL FORWARD -x --line-numbers
        logger.info("We will flush all rules from peer " + peer_ip)
        #logger.info("Command iptables: --flush {0}".format(self.working_chain))

        if pyflow_list == None:
            execute_command_with_shell(self.iptables_path, [ '--flush', self.working_chain ])
            return True

        rules_list = self.generate_rules(peer_ip, pyflow_list, "-D")
        if rules_list != None and len(rules_list) > 0:
            for iptables_rule in rules_list:
                execute_command_with_shell(self.iptables_path, iptables_rule)
        else:
            logger.error("Generated rule list is blank!")

    def flush(self):
        logger.info("We will flush all rules from peer " + peer_ip)
        logger.info("Command iptables: --flush {0}".format(self.working_chain))
        execute_command_with_shell(self.iptables_path, [ '--flush', self.working_chain  ])
    def add_rules(self, peer_ip, pyflow_list):
        rules_list = self.generate_rules(peer_ip, pyflow_list, "-I")

        if rules_list != None and len(rules_list) > 0:
            for iptables_rule in rules_list:
                execute_command_with_shell(self.iptables_path, iptables_rule)
        else:
            logger.error("Generated rule list is blank!")
    def generate_rule(self, peer_ip, pyflow_rule, policy):
            iptables_arguments = [ policy, self.working_chain ]

            if pyflow_rule['protocol'] != 'all':
                iptables_arguments.extend(['-p', pyflow_rule['protocol']])

            if pyflow_rule['source_host'] != 'any':
                iptables_arguments.extend(['-s', pyflow_rule['source_host']])

            if pyflow_rule['target_host'] != 'any':
                iptables_arguments.extend(['-d', pyflow_rule['target_host']])

            # We have ports only for udp and tcp protocol
            if pyflow_rule['protocol'] == 'udp' or pyflow_rule['protocol'] == 'tcp':
                if 'source_port' in pyflow_rule and len(pyflow_rule['source_port']) > 0:
                    iptables_arguments.extend(['--sport', pyflow_rule['source_port']])

                if 'target_port' in pyflow_rule and len(pyflow_rule['target_port']) > 0:
                    iptables_arguments.extend(['--dport', pyflow_rule['target_port']])

            if 'tcp_flags' in pyflow_rule and len(pyflow_rule['tcp_flags']) > 0:
                # ALL means we check all flags for packet
                iptables_arguments.extend([ '--tcp-flags', 'ALL', ",".join(pyflow_rule['tcp_flags'])])

            if pyflow_rule['fragmentation']:
                iptables_arguments.extend(['--fragment'])


            iptables_arguments.extend([ '-m', 'comment', '--comment', firewall_comment_text + str(peer_ip) ])

            # We could specify only range here, list is not allowed
            if 'packet-length' in pyflow_rule:
                iptables_arguments.extend(['-m', 'length', '--length', pyflow_rule[packet-length] ])

            iptables_arguments.extend(['-j', 'DROP' ])

            pp = pprint.PrettyPrinter(indent=4)
            logger.info("Will run iptables command: " + pp.pformat(iptables_arguments))

            return iptables_arguments

# Ban specific protocol:
# ipfw add deny udp from any to 10.10.10.221/32

# Block fragmentation:
# ipfw add deny all from any to 10.10.10.221/32 frag

# Block all traffic:
# ipfw add deny all from any to 10.10.10.221/32

# Black traffic from specific port:
# ipfw add deny udp from any 53 to 10.10.10.221/32

# Block traffic to specific port:
# ipfw add deny udp from any to 10.10.10.221/32 8080

# command_name - is absolute path to binary
# arguments - array of arguments, one argument per element
def execute_command_with_shell(command_name, arguments):
    args = [ command_name ]

    if arguments != None:
        args.extend( arguments )

    subprocess.Popen( args );

class Ipfw(AbstractFirewall):
    def __init__(self):
        logger.info( "We have following number of processors: " + str(multiprocessing.cpu_count()) )

        self.number_of_netmap_instances = multiprocessing.cpu_count()
        self.netmap_path = '/usr/src/netmap-ipfw/ipfw/ipfw'
        self.netmap_initial_port = 5550
        self.netmap_env_port_name = 'IPFW_PORT'

    def execute_command_for_all_ipfw_backends(self, ipfw_command):
        for instance_number in range(0, self.number_of_netmap_instances - 1):
            port_for_current_instance = self.netmap_initial_port + instance_number

            args = [ self.netmap_path ]
            # split interpret multiple spaces as single
            args.extend( ipfw_command )

            new_env = os.environ.copy()
            # Will fail without explicit conversion:
            #  TypeError: execve() arg 3 contains a non-string value
            new_env[ self.netmap_env_port_name ] = str(port_for_current_instance)

            subprocess.Popen( args, env=new_env)
    def flush_rules(self, peer_ip):
        # If we got blank flow we should remove all rules for this peer
        logger.info("We will flush all rules from peer " + peer_ip)
        # TODO: switch to another code parser
        self.execute_command_for_all_ipfw_backends("-f flush")
    def add_rules(self, peer_ip, pyflow_list):
        generated_rules = self.generate_rules(peer_ip, pyflow_list)

        for rule in generated_text_rules:
            self.execute_command_for_all_ipfw_backends(rule)
    def generate_rule(self, peer_ip, pyflow_rule):
        # Add validity check for IP for source and target hosts
        ipfw_command = "add %(action) %(protocol) from %(source_host) %(source_port) to %(target_host) %(target_port)".format(pyflow_rule)

        if pyflow_rule['fragmentation']:
            ipfw_command += " frag"

        if 'tcp_flags' in pyflow_rule and len(pyflow_rule['tcp_flags']) > 0:
            ipfw_command += " tcpflags " + ','.join(pyflow_rule['tcp_flags']).lower()

        # We could specify multiple values here
        if 'packet-length' in pyflow_rule:
            ipfw_command += " iplen " + pyflow_rule['packet-length']

        # Add comment
        ipfw_command += '//' + firewall_comment_text + peer_ip

        # Add skip for multiple spaces to single
        logger.info( "We generated this command: " + ipfw_command )

        return ipfw_command.split()

firewall = None;

if (firewall_backend == 'netmap-ipfw'):
    firewall = Ipfw()
elif firewall_backend == 'iptables':
    firewall = Iptables()
else:
    logger.error("Firewall" + firewall_backend + " is not supported")
    sys.exit("Firewall" + firewall_backend + " is not supported")

def manage_flow(action, peer_ip, flow, firewall):
    allowed_actions = [ 'withdrawal', 'announce' ]
    logger.warning("Action " + action + " checking...")

    if action not in allowed_actions:
        logger.warning("Action " + action + " is not allowed")
        return False

    pp = pprint.PrettyPrinter(indent=4)
    logger.info(pp.pformat(flow))

    if action == 'withdrawal' and flow == None:
    	# Esto es lo que no tenemos que romper nunca mas:
    	logger.info("Call flush_rules flow None")	
        firewall.flush_rules(peer_ip, None)
        #firewall.flush_rules(peer_ip)
        return True
    elif action == 'withdrawal' and flow != None:
        py_flow_list = convert_exabgp_to_pyflow(flow)
        logger.info("Call flush_rules non None") 
        logger.info("PyFlow: "+str(py_flow_list))
        firewall.flush_rules(peer_ip, py_flow_list)
        return True

    py_flow_list = convert_exabgp_to_pyflow(flow)
    #py_flow_list = convert_exabgp_to_pyflow(flow)
    logger.info("Call add_rules")
    logger.info("PyFlow: "+str(py_flow_list))
    #logger.info("PyFlow: "+str(py_flow_list))
    return firewall.add_rules(peer_ip, py_flow_list)

def convert_exabgp_to_pyflow(flow):
    # Flow in python format, here
    # We use customer formate because ExaBGP output is not so friendly for firewall generation
    logger.info("In convert: "+str(flow))
    current_flow = {
        'action'        : 'deny',
        'protocol'      : 'all',
        'source_port'   : '',
        'source_host'   : 'any',
        'target_port'   : '',
        'target_host'   : 'any',
        'fragmentation' : False,
        'packet_length' : '',
        'tcp_flags'     : [],
    }

    # But we definitely could have MULTIPLE ports here
    if 'packet-length' in flow:
        current_flow['packet_length'] = flow['packet-length'][0].lstrip('=')

    # We support only one subnet for source and destination
    if 'source-ipv4' in flow:
        current_flow['source_host'] = flow["source-ipv4"][0]

    if 'destination-ipv4' in flow:
        current_flow['target_host'] = flow["destination-ipv4"][0]

    if 'tcp-flags' in flow and len(flow['tcp-flags']) > 0:
        for tcp_flag in flow['tcp-flags']:
            current_flow['tcp_flags'].append(tcp_flag.lstrip('='))

    if current_flow['source_host'] == "any" and current_flow['target_host'] == "any":
        logger.info( "We can't process this rule because it will drop whole traffic to the network" )
        return False

    if 'destination-port' in flow:
        current_flow['target_port'] = flow['destination-port'][0].lstrip('=')

    if 'source-port' in flow:
        current_flow['source_port'] = flow['source-port'][0].lstrip('=');

    if 'fragment' in flow:
        if '=is-fragment' in flow['fragment']:
            current_flow['fragmentation'] = True

    pyflow_list = []

    if 'protocol' in flow:
        global_result = True

        for current_protocol in flow['protocol']:
            current_flow['protocol'] = current_protocol.lstrip('=')
            pyflow_list.append(current_flow)
    else:
        current_flow['protocol'] = 'all'
        pyflow_list.append(current_flow)

    return pyflow_list


# Funcion para crear el tunel GRE en Scrubbing (por alguna razon, no funciona correctamente en un archivo separado)
def create_gre(line):
    json_line = json.loads(line)
    try:
        if json_line["type"] == "update":
            neighbor = json_line["neighbor"]
            remote = neighbor["address"]["peer"]
            local = neighbor["address"]["local"]
            asn_remote = neighbor["asn"]["peer"]
            if "announce" in neighbor["message"]["update"].keys() and neighbor["direction"] == "receive":
                if "ipv4 unicast" in neighbor["message"]["update"]["announce"].keys():
                    command = """
ip tunnel add {2} mode gre remote {0} local {1} ttl 255
ip link set {2} up
ip addr add 172.16.17.18 dev {2}
ip route add 172.19.20.0/24 dev {2}
"""
                    os.system(command.format(remote, local, asn_remote))
                    return True
    except KeyError:
        pass
    return None



while True:
    try:
        line = sys.stdin.readline().strip()
        # print >> sys.stderr, "GOT A LINE"

        sys.stdout.flush()
        counter = 0

# { "exabgp": "3.5.0", "time": 1431716393, "host" : "synproxied.fv.ee", "pid" : 2599, "ppid" : 2008, "counter": 1, "type": "update", "neighbor": { "address": { "local": "10.0.3.115", "peer": "10.0.3.114" }, "asn": { "local": "1234", "peer": "65001" }, "direction": "receive", "message": { "update": { "attribute": { "origin": "igp", "as-path": [ 65001 ], "confederation-path": [], "extended-community": [ 9225060886715039744 ] }, "announce": { "ipv4 flow": { "no-nexthop": { "flow-0": { "destination-ipv4": [ "10.0.0.2/32" ], "source-ipv4": [ "10.0.0.1/32" ], "protocol": [ "=tcp" ], "destination-port": [ "=3128" ], "string": "flow destination-ipv4 10.0.0.2/32 source-ipv4 10.0.0.1/32 protocol =tcp destination-port =3128" } } } } } } } }
# { "exabgp": "3.5.0", "time": 1431716393, "host" : "synproxied.fv.ee", "pid" : 2599, "ppid" : 2008, "counter": 11, "type": "update", "neighbor": { "address": { "local": "10.0.3.115", "peer": "10.0.3.114" }, "asn": { "local": "1234", "peer": "65001" }, "direction": "receive", "message": { "eor": { "afi" : 11.22.33.44

# u'destination-ipv4': [u'10.0.0.2/32'],
# u'destination-port': [u'=3128'],
# u'protocol': [u'=tcp'],
# u'source-ipv4': [u'10.0.0.1/32'],
# u'string': u'flow destination-ipv4 10.0.0.2/32 source-ipv4 10.0.0.1/32 protocol =tcp destination-port =3128'}

# Peer shutdown notification:
# { "exabgp": "3.5.0", "time": 1431900440, "host" : "filter.fv.ee", "pid" : 8637, "ppid" : 8435, "counter": 21, "type": "state", "neighbor": { "address": { "local": "10.0.3.115", "peer": "10.0.3.114" }, "asn": { "local": "1234", "peer": "65001" }, "state": "down", "reason": "in loop, peer reset, message [closing connection] error[the TCP connection was closed by the remote end]" } }

        # Llamado a crear GRE tunnel, se verifica dentro de la funcion el tipo de mensaje recibido:
        create_gre(line)

        # Fix bug: https://github.com/Exa-Networks/exabgp/issues/269
        line = line.replace('0x800900000000000A', '"0x800900000000000A"')
        io = StringIO(line)
        print >> sys.stderr, line
        decoded_update = json.load(io)

        pp = pprint.PrettyPrinter(indent=4, stream=sys.stderr)
        pp.pprint(decoded_update)

        try:
            current_flow_announce = decoded_update["neighbor"]["message"]["update"]["announce"]["ipv4 flow"]
            peer_ip = decoded_update['neighbor']['address']['peer']

            for next_hop in current_flow_announce:
                flow_announce_with_certain_hop = current_flow_announce[next_hop]

                for flow in flow_announce_with_certain_hop:
                    #pp.pprint(flow)
                    pp.pprint(flow)
                    #q.enqueue(firewall_queue.manage_flow, 'announce', peer_ip, flow)
                    manage_flow('announce', peer_ip, flow, firewall)
        except KeyError:
            pass

        # Withdraws routes from specified peer
        # TODO: Borra todos los flows de un peer, no se puede seleccionar que flow borrar, hay que modificar funcion manage_flow
#        try:
#            if decoded_update["neighbor"]["message"]["update"]["withdraw"]:
#                flow = decoded_update["neighbor"]["message"]["update"]["withdraw"]["ipv4 flow"]
#                peer_ip = decoded_update['neighbor']['address']['peer']
#                manage_flow('withdrawal', peer_ip, flow, firewall)	
#
#    	except KeyError:
#    		pass

        try:
            current_flow_withdraw = decoded_update["neighbor"]["message"]["update"]["withdraw"]["ipv4 flow"]
            peer_ip = decoded_update['neighbor']['address']['peer']
            for flow in current_flow_withdraw:
                pp.pprint(flow)
                manage_flow('withdrawal', peer_ip, flow, firewall)
        except KeyError:
            pass

        # We got notification about neighbor status
        if 'type' in decoded_update and decoded_update['type'] == 'state':
            if 'state' in decoded_update['neighbor'] and decoded_update['neighbor']['state'] == 'down':
                peer_ip = decoded_update['neighbor']['address']['peer']
                print >> sys.stderr, "We received notification about peer down for: " + peer_ip

                #q.enqueue(firewall_queue.manage_flow, 'withdrawal', peer_ip, None)
                manage_flow('withdrawal', peer_ip, None, firewall)

        exabgp_log.write(line + "\n")
    except KeyboardInterrupt:
        pass
    except IOError:
        # most likely a signal during readline
        pass
