#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Created on 2018-10-27

Copyright 2018 Athanasios Natsis

@author:  Athanasios Natsis
@contact: natsisthanasis@gmail.com
@license: GPLv3
"""

#### Send a notifications to other machine

## TODO send to multiple ips or read from multiple ips


import os
import sys
import platform
import datetime
import argparse
import pickle
import zlib
import base64

from socket import *


## variables

## set to IP address of target computers
SEND_TO = ["127.0.0.1",
           "localhost",
           "10.12.12.1",    # crane
           "10.12.12.2",    # blue
           "10.12.12.3",    # lap46
           "10.12.12.4",    # kostas
           "10.12.12.5",    # sagan
           "10.12.12.6",    # tyler
           "10.12.12.7",    # victor
           "10.12.12.101"   # yperos
           ]



## Variables
PORT      = 13000
HOST      = platform.node()
RANDOM    = "/home/athan/BASH/PARAMS/random.txt"
USER      = os.environ.get('USER')
SEND_DATE = datetime.datetime.utcnow()


#$ notify-send --help
#Usage:
#  notify-send [OPTION...] <SUMMARY> [BODY] - create a notification
#
#Help Options:
#  -?, --help                        Show help options
#
#Application Options:
#  -u, --urgency=LEVEL               Specifies the urgency level (low, normal, critical).
#  -t, --expire-time=TIME            Specifies the timeout in milliseconds at which to expire the notification.
#  -a, --app-name=APP_NAME           Specifies the app name for the icon
#  -i, --icon=ICON[,ICON...]         Specifies an icon filename or stock icon to display.
#  -c, --category=TYPE[,TYPE...]     Specifies the notification category.
#  -h, --hint=TYPE:NAME:VALUE        Specifies basic extra data to pass. Valid types are int, double, string and byte.
#  -v, --version                     Version of the package.


## parse arguments from command line similar to notify-send command

parser = argparse.ArgumentParser()

parser.add_argument("SUMMARY",
                    help="The summary of the notification")

parser.add_argument("BODY",
                    nargs='?', default="",
                    help="The body of the notification")

parser.add_argument("-u", "--urgency",
                    default = 'normal',
                    choices = ['low', 'normal', 'critical'],
                    help    = "Specifies the urgency level.")

parser.add_argument("-t", "--expire_time",
                    type    = int,
                    default = -9,
                    help    = "Specifies the timeout in milliseconds at which to expire the notification.")

args = parser.parse_args()

print("")
print("Summary        : ", args.SUMMARY    )
print("Body           : ", args.BODY       )
print("Urgency        : ", args.urgency    )
print("Expiration time: ", args.expire_time)


## Read list of passwords ##
if ( os.path.isfile(RANDOM) ):
    print("found list")
    with open(RANDOM) as f:
        PASSWORDS = f.readlines()
    PASSWORDS = [x.strip() for x in PASSWORDS]
else:
    sys.exit("Could not find file" + RANDOM )



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




## Build the local command ##
command = "notify-send "

if ( int(args.expire_time) > 0 ) :
    command += " -t " + str(int(args.expire_time))

command += " -u " +  args.urgency
command += ' "'   +  args.SUMMARY + '" '
command += ' "'   +  args.BODY    + '" '


## run a local notification
print("")
print(command)
print(os.popen(command).read())


## send notification to all machines
for host in SEND_TO:
    print("Trying ",host)

    # try:
    ## open socket to send remote notification
    addr    = (host, PORT)
    UDPSock = socket(AF_INET, SOCK_DGRAM)

    ## serialize data
    packet = pickle.dumps([ SEND_DATE,
                            HOST,
                            USER,
                            args.SUMMARY,
                            args.BODY,
                            args.urgency,
                            args.expire_time ])
    ## compress data
    packet = zlib.compress(packet)
    ## encode data
    packet = encode(password(), packet)
    ## send data
    UDPSock.sendto(packet, addr)

    ## close connection
    UDPSock.close()
    # except:
    #     print("Failed fpr: " + host)

os._exit(0)

## END ##
