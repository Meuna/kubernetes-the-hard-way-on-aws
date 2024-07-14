#!/bin/bash
myipv4=$(dig +short myip.opendns.com @resolver1.opendns.com -4)
echo "{\"myipv4\": \"$myipv4\"}"