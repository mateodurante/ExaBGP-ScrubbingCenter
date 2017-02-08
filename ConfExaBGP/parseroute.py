#!/usr/bin/env python
import json
import os
from sys import stdin, stdout
import datetime
import requests

counter = 0
peer = {}
red = {}
while True:

	line = stdin.readline().strip()
	
	# When the parent dies we are seeing continual newlines, so we only access so many before 	  #stopping
	if line == "":
		counter += 1
		if counter > 100:
			break
	
		continue
	counter = 0
	
	
	 
	message = json.loads(line)

	if message["type"] == "update":
		
		try:	
			peer = message['neighbor']['address']['peer']
			net  = message['neighbor']['message']['update']['announce']['ipv4 unicast'][peer]
			ip = net[0]['nlri']
			asn = message['neighbor']['asn']['peer']
	 		
				
		 	# log some shit
			f = open('/home/redes/Desktop/workfile', 'a+')			
			f.write("\n LOG:" + str(message)+"\n")
			f.close()
		

			# Announce received ExaBGP-route trough Quagga peering	
			if (ip):
				value = "announce route "+ ip + " next-hop self"
				post = requests.post('http://localhost:5000/', data = {'command':value})
				out = os.system("ip route add "+str(ip)+" dev "+str(asn))
		
		 		# log some shit
				#f = open('/home/redes/Desktop/workfile', 'a+')			
				#f.write(str(out))
				#f.close()
		except KeyError: 
			continue
		
			
		

