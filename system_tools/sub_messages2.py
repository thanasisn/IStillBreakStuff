#!/usr/bin/python2
# -*- coding: utf-8 -*-
"""
Created on 2018-10-27

Copyright 2018 Athanasios Natsis

@author:  Athanasios Natsis
@contact: natsisthanasis@gmail.com
@license: GPLv3
"""

## read all messages from other systems and display them on local


# Save as client.py
# Message Sender
import os
from socket import *
import datetime
import time

host = "127.0.0.1" # set to IP address of target computer
host = "10.12.12.1" # set to IP address of target computer
port = 13000
addr = (host, port)
UDPSock = socket(AF_INET, SOCK_DGRAM)
while True:
    #data = raw_input("Enter message to send or type 'exit': ")
    data = "Blue" + str(datetime.datetime.now())
    UDPSock.sendto(data, addr)
    if data == "exit":
        break
    time.sleep(.7)
UDPSock.close()
os._exit(0)


import sys

sys.exit()



import sys
import os
import pickle
import zmq
import time
#from simplecrypt import encrypt, decrypt
import base64
import zlib
import datetime
import commands

#### UI socket
# Socket to hear from server
PORT     = "45401"
RANDOM   = "/home/athan/BASH/PARAMS/random.txt"

## Set a password from a list of pass ##
command = "tail -n+" + datetime.datetime.utcnow().strftime("%j") + " " + RANDOM + " | head -n1"
res, PASSWORD = commands.getstatusoutput(command)

print res, PASSWORD

if ( os.path.isfile(RANDOM) ):
    print "found list"
else:
    sys.exit("Could not find file " + RANDOM )

if (res == 0) & (len(PASSWORD) > 10 ):
    print "got a password"
else:
    sys.exit("Could not find proper password")




def encode(key, clear):
    enc = []
    for i in range(len(clear)):
        key_c = key[i % len(key)]
        enc_c = chr((ord(clear[i]) + ord(key_c)) % 256)
        enc.append(enc_c)
    return base64.urlsafe_b64encode("".join(enc))

def decode(key, enc):
    dec = []
    enc = base64.urlsafe_b64decode(enc)
    for i in range(len(enc)):
        key_c = key[i % len(key)]
        dec_c = chr((256 + ord(enc[i]) - ord(key_c)) % 256)
        dec.append(dec_c)
    return "".join(dec)



host = "localhost"
host = "155.207.9.18"


context = zmq.Context()
global socket

socket = context.socket(zmq.SUB)
socket.connect("tcp://%s:%s" % (host, PORT))
socket.setsockopt(zmq.SUBSCRIBE, '')



while True:
    packet = socket.recv()
    #packet = zlib.decompress(packet)
    #packet = decode(password, packet)

    date, host, summary, body, urgency, expire_time = pickle.loads(packet)

    print ""
    print "Date           : ", date
    print "From host      : ", host
    print "Summary        : ", summary
    print "Body           : ", body
    print "Urgency        : ", urgency
    print "Expiration time: ", expire_time

    print datetime.datetime.now()
    time.sleep(0.3)



