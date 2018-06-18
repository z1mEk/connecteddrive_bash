#!/bin/sh

case $1 in
    "climate") COMMAND="RCN" ;;
    "lock") COMMAND="RDL" ;;
    "unlock") COMMAND="RDU" ;;
    "light") COMMAND="RLF" ;;
    "horn") COMMAND="RHB" ;;
    *) echo "Command $1 not recognized" ; exit 1 ;;
esac

USERNAME="username"
PASSWORD="password"
VIN="XXXXXXXXXXXXXXXXX"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:57.0) Gecko/20100101 Firefox/57.0"
CONNECTED_DRIVE_URL="https://www.bmw-connecteddrive.pl"

curl \
    -s \
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

service_url="$CONNECTED_DRIVE_URL/api/vehicle/remoteservices/v1/$VIN/$COMMAND"

service_out=$(curl \
		-s \
		-H "Content-Type: application/json" \
		-H "User-agent: $USER_AGENT" \
		-H "Authorization: Bearer $ACCESS_TOKEN" \
		-H "Content-Length: 0" \
		--request POST $service_url)

status=$(echo $service_out | grep -oPm1 "(?<=<remoteServiceStatus>)[^<]+")
get_status_url="$CONNECTED_DRIVE_URL/api/vehicle/remoteservices/v1/$VIN/state/execution"

if [ $status = 'PENDING' ]
then
    for i in `seq 1 9`
    do
	sleep 10
	
	status_out=$(curl \
			-s \
			-H "Content-Type: application/json" \
			-H "User-agent: $USER_AGENT" \
			-H "Authorization: Bearer $ACCESS_TOKEN" \
			$get_status_url)
	
	status=$(echo $status_out | grep -oPm1 "(?<=<remoteServiceStatus>)[^<]+")

	if [ $status = 'EXECUTED' ]
	then
	    echo $status
	    exit 1
	fi
    done
fi

echo 'ERROR'
