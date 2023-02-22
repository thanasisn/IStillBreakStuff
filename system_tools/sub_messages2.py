#!/usr/bin/python2
# -*- coding: utf-8 -*-
"""
Created on 2018-10-27

Copyright 2018 Athanasios Natsis

@author:  Athanasios Natsis
@contact: natsisphysicist@gmail.com
@license: GPLv3
"""

## read all messages from other systems and display them on local

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
# lock = singleton.SingleInstance()

from cryptography.fernet import Fernet


RANDOM  = "/home/athan/BASH/PARAMS/random.txt"
HOST    = platform.node()


## Read list of passwords ##
if ( os.path.isfile(RANDOM) ):
    print("found list")
    with open(RANDOM) as f:
        PASSWORDS = f.readlines()
    PASSWORDS = [x.strip() for x in PASSWORDS]
else:
    sys.exit("Could not find file" + RANDOM )


def passwordf():
    """
    get correct password in each call
    """
    a_pass = PASSWORDS[int(datetime.datetime.utcnow().strftime("%j"))]
    if len(a_pass) < 5:
        sys.exit("Could not find proper password")
    return(a_pass)


import secrets

from base64 import urlsafe_b64encode as b64e, urlsafe_b64decode as b64d

from cryptography.fernet import Fernet
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

backend = default_backend()
iterations = 100_000

def _derive_key(password: bytes, salt: bytes, iterations: int = iterations) -> bytes:
    """Derive a secret key from a given password and salt"""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(), length=32, salt=salt,
        iterations=iterations, backend=backend)
    return b64e(kdf.derive(password))

def password_encrypt(message: bytes, password: str, iterations: int = iterations) -> bytes:
    salt = secrets.token_bytes(16)
    key = _derive_key(password.encode(), salt, iterations)
    return b64e(
        b'%b%b%b' % (
            salt,
            iterations.to_bytes(4, 'big'),
            b64d(Fernet(key).encrypt(message)),
        )
    )

def password_decrypt(token: bytes, password: str) -> bytes:
    decoded = b64d(token)
    salt, iter, token = decoded[:16], decoded[16:20], b64e(decoded[20:])
    iterations = int.from_bytes(iter, 'big')
    key = _derive_key(password.encode(), salt, iterations)
    return Fernet(key).decrypt(token)

message = 'John Doe'
password = 'mypass'

token = password_encrypt(message.encode(), password)
print(token)
mm = password_decrypt(token, password).decode()
print(mm)

