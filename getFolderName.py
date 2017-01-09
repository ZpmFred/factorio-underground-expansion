#!/bin/python3

import sys, json 

info = json.load(open("info.json")) 

print(info['name'] + "_" + info['version'])


