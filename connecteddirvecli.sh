#!/bin/sh

USERNAME="username"
PASSWORD="password"
VIN="XXXXXXXXXXXXXXXXX"

COMMAND="RHB" #'climate': 'RCN','lock': 'RDL','unlock': 'RDU','light': 'RLF','horn': 'RHB'
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:57.0) Gecko/20100101 Firefox/57.0"

curl \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "User-agent: $USER_AGENT" \
    --request POST https://customer.bmwgroup.com/gcdm/oauth/authenticate \
    --dump-header /tmp/header_bmw \
    --data-urlencode "username=$USERNAME" \
    --data-urlencode "password=$PASSWORD" \
    --data-urlencode "client_id=dbf0a542-ebd1-4ff0-a9a7-55172fbfce35" \
    --data-urlencode "redirect_uri=https://www.bmw-connecteddrive.com/app/default/static/external-dispatch.html" \
    --data-urlencode "response_type=token" \
    --data-urlencode "scope=authenticate_user fupo" \
    --data-urlencode "state=eyJtYXJrZXQiOiJkZSIsImxhbmd1YWdlIjoiZGUiLCJkZXN0aW5hdGlvbiI6ImxhbmRpbmdQYWdlIn0" \
    --data-urlencode "locale=PL-pl"

ACCESS_TOKEN=$(cat /tmp/header_bmw | grep -e Location | cut -d'=' -f 3 | cut -d'&' -f 1)
#expires_in=$(cat /tmp/header_bmw | grep -e Location | cut -d'=' -f 5 | cut -d'$' -f 1)

service_url="https://www.bmw-connecteddrive.pl/api/vehicle/remoteservices/v1/$VIN/$COMMAND"

curl \
    -H "Content-Type: application/json" \
    -H "User-agent: $USER_AGENT" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Length: 0" \
    --request POST $service_url
