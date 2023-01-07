#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Created on 2018-10-27

Copyright 2018 Athanasios Natsis

@author:  Athanasios Natsis
@contact: natsisthanasis@gmail.com
@license: GPLv3
"""

#### Accept and decode notifications from other systems.
## Encryption with preshared keys

import sys
import pickle
import zlib
import base64
import datetime
import platform
import os
from socket import *
from tendo import singleton
# will sys.exit(-1) if other instance is running
lock = singleton.SingleInstance()


RANDOM  = "/home/athan/BASH/PARAMS/random.txt"
HOST    = platform.node()

PORT    = 13000
buf     = 1024
addr    = ("", PORT)
UDPSock = socket(AF_INET, SOCK_DGRAM)
UDPSock.bind(addr)
print("Waiting to receive messages...")



## Set a password from a list of pass ##
if (os.path.isfile(RANDOM)):
    print("found list")
else:
    sys.exit("Could not find file" + RANDOM)

with open(RANDOM) as f:
    PASSWORDS = f.readlines()
PASSWORDS = [x.strip() for x in PASSWORDS]


def password():
    """
    get correct password in each call
    """
    a_pass = PASSWORDS[int(datetime.datetime.utcnow().strftime("%j"))]
    if len(a_pass) < 5:
        sys.exit("Could not find proper password")
    return(a_pass)


def encode(key, clear):
    """
    Simple password encode message
    """
    enc = []
    for i in range(len(clear)):
        key_c = key[i % len(key)]
        enc_c = chr((ord(clear[i]) + ord(key_c)) % 256)
        enc.append(enc_c)
    return base64.urlsafe_b64encode("".join(enc))


def decode(key, enc):
    """
    Simple password decode message
    """
    dec = []
    enc = base64.urlsafe_b64decode(enc)
    for i in range(len(enc)):
        key_c = key[i % len(key)]
        dec_c = chr((256 + ord(enc[i]) - ord(key_c)) % 256)
        dec.append(dec_c)
    return "".join(dec)


check1 = ""
check2 = ""
try:
    while True:
        try:
            ## get message
            (packet, addr) = UDPSock.recvfrom(buf)
            len_encod = len(packet)
            ## decode message
            packet = decode(password(), packet)
            len_decod = len(packet)
            ## decompress message
            packet = zlib.decompress(packet)
            len_uncom = len(packet)
            ## unpack message
            date, host, user, summary, body, urgency, expire_time = pickle.loads(packet)

            ## ignore duplicate messages
            check1 = str(date)+HOST
            if check1 == check2:
                continue
            check2 = str(date)+HOST

            ## print message details
            print("")
            print("Date           : ", date)
            print("From host      : ", host)
            print("User           : ", user)
            print("Summary        : ", summary)
            print("Body           : ", body)
            print("Urgency        : ", urgency)
            print("Expiration time: ", expire_time)
            print("Address        : ", addr)
            print("Enc ", len_encod)
            print("Dec ", len_decod)
            print("Unc ", len_uncom)

        except:
            print("sub_messages.py Message parsing failed")


        ### run the local command
        #try:
        if host == HOST:
            print("Ignore message, remote and local the same")
            continue

        ## Build the local command ##
        command = "notify-send "

        if ( int(expire_time) > 0 ) :
            command += " -t " + str(int(expire_time))

        command += " -u " +  urgency
        command += ' "'   + host.upper() + ': ' +  summary + '" '
        command += ' "'   +  body    + '" '

        print("")
        print(command)
        print(os.popen(command).read())


## close socket on exit
finally:
    UDPSock.close()


os._exit(0)
## END ##
