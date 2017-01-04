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

def get_neighbor(line):
	json_line = json.loads(line)
	neighbor = json_line["neighbor"]["address"]["peer"]
	return neighbor + "\n"


def message_parser(line):
    # Parse JSON string  to dictionary
    temp_message = json.loads(line)

    # Convert Unix timestamp to python datetime
    timestamp = temp_message['time']

    if temp_message['type'] == 'state':
        message = {
            'type': 'state',
            'time': timestamp,
            'peer': temp_message['neighbor']['ip'],
            'state': temp_message['neighbor']['state'],
        }

        return message

    if temp_message['type'] == 'keepalive':
        message = {
            'type': 'keepalive',
            'time': timestamp,
            'peer': temp_message['neighbor']['ip'],
        }

        return message


    # If message is a different type, ignore
    return None

def dame_algo(line):
	return "Probando probando"

counter = 0
while True:
#    try:
        line = stdin.readline().strip()

        f = open('/home/redes/Documentos/workfile', 'a')
        
	#f.write(get_neighbor(line))
        f.write(line + "\n")
	f.write(dame_algo(line) + "\n")
#	f.write(get_neighbor(line) + "vecino \n")	

	f.close()

        # When the parent dies we are seeing continual newlines, so we only access so many before stopping
        if line == "":
            counter += 1
            if counter > 100:
                break
            continue
        counter = 0

        # Parse message, and if it's the correct type, store in the database
        #message = message_parser(line)
#        if message:
        updates.insert({"data": line}, check_keys=False)

