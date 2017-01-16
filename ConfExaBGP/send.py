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

'''
{ "exabgp": "3.5.0", "time": 1483038526.92, "host" : "n32", "pid" : 176, "ppid" : 29, "counter": 10, "type": "keepalive", "header": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF001304", "neighbor": { "address": { "local": "163.10.252.2", "peer": "10.0.9.10" }, "asn": { "local": "5692", "peer": "123" }, "direction": "receive"  } }exabgp 4.0.0
'''

counter = 0
while True:
    line = stdin.readline().strip()

    j_line = json.loads(line)
    #if j_line["type"] == "update":      
    f = open('/home/redes/Documentos/workfile', 'a')
    f.write("UNLP: " + line + "\n")
    f.close()


    # When the parent dies we are seeing continual newlines, so we only access so many before stopping
    if line == "":
        counter += 1
        if counter > 100:
            break
        continue
    counter = 0

#   updates.insert({"data": line}, check_keys=False)
