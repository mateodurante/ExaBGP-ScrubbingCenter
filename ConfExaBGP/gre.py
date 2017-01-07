#!/usr/bin/env python
import json
import os
from sys import stdin, stdout
from pymongo import MongoClient
import datetime

###  DB Setup ###
client = MongoClient('10.0.4.2', 27017)
db = client.exabgp_db
updates = db.bgp_updates

"""
{ "exabgp": "3.5.0", 
"type": "update", 
"header": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF002F02", "body": "000000144001010040020602010000163C400304A30AFC02182C0A00", 
"neighbor": { 
	"address": { "local": "10.0.9.10", "peer": "163.10.252.2" }, 
	"asn": { "local": "123", "peer": "5692" }, 
	"direction": "receive", 
	"message": { 
		"update": { 
			"attribute": { "origin": "igp", "as-path": [ 5692 ], "confederation-path": [] }, 
			"announce": { "ipv4 unicast": { "163.10.252.2": [ { "nlri": "44.10.0.0/24" } ] } } } } } 
}
"""

def create_gre(line):
	json_line = json.loads(line)
	try:
		if json_line["type"] == "update":
			neighbor = json_line["neighbor"]
			remote = neighbor["address"]["peer"]
			local = neighbor["address"]["local"]
			asn_remote = neighbor["asn"]["peer"]
			if "announce" in neighbor["message"]["update"].keys() and neighbor["direction"] == "receive":
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


counter = 0
while True:
	line = stdin.readline().strip()

	j_line = json.loads(line)
	if j_line["type"] == "update":		
		f = open('/home/redes/Documentos/workfile', 'a')
		f.write("Scrubbing: " + line + "\n")
		f.close()
	create_gre(line)

	# When the parent dies we are seeing continual newlines, so we only access so many before stopping
	if line == "":
		counter += 1
		if counter > 100:
			break
		continue
	counter = 0

#	updates.insert({"data": line}, check_keys=False)
