#!/usr/bin/env python

import os
import sys
import requests

net = sys.argv[1]

#IP del peering remote
ip_remote = "10.0.9.10"
# IP del peering local
ip_local = "163.10.252.2"
# El asn remoto para identificarlo en el tunel GRE
asn_remote = "123" 

# Announce received ExaBGP-route trough Quagga peering	
value = "announce route " + net + " next-hop self"
post = requests.post('http://localhost:5000/', data = {'command':value})

if post.status_code == 200:
	command = """
ip tunnel add {2} mode gre remote {0} local {1} ttl 255
ip link set {2} up
ip addr add 172.19.20.21 dev {2}
ip route add 172.16.17.0/24 dev {2}
"""
	os.system(command.format(ip_remote, ip_local, asn_remote))
	print ("Comando enviado a Scrubbing.")

