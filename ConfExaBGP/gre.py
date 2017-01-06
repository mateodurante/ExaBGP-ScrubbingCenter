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


def create_gre(line):
	json_line = json.loads(line)
	remote = json_line["neighbor"]["address"]["remote"]
	local = json_line["neighbor"]["address"]["local"]
	asn_remote = json_line["neighbor"]["asn"]["peer"]
	if json_line["type"] == "update":
		if json_line["neighbor"]["direction"] == "receive":
			command = """
ip tunnel add unlp mode gre remote {0} local {1} ttl 255
ip link set {3} up
ip addr add 172.16.17.18 dev {3}
ip route add 172.19.20.0/24 dev {3}
"""
			os.system(command.format(remote, local, asn_remote))
			return True
	return None


counter = 0
while True:
	line = stdin.readline().strip()

	f = open('/home/redes/Documentos/workfile', 'a')
	f.write("Scrubbing: " + line + "\n")
	f.close()

    # When the parent dies we are seeing continual newlines, so we only access so many before stopping
    if line == "":
        counter += 1
        if counter > 100:
            break
        continue
    counter = 0

	updates.insert({"data": line}, check_keys=False)
