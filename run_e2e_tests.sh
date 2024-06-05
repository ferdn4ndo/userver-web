#!/bin/bash

set -e
set -o pipefail

echo "Starting E2E tests!"

totalErrors=0

echo "Getting uServer-Monitor container output using cURL"
monitorOutput=$(curl -s "http://monitor.userver.lan/" || true)

echo "Checking for the uServer-Monitor 'title' HTML element"
heartbeatBoxLine=$(echo "$monitorOutput" | grep "<title>Docker Containers Monitor</title>" || true)
if [ "$heartbeatBoxLine" == "" ]; then
    echo "Failed finding the HTML title 'Docker Containers Monitor' in the uServer-Monitor cURL response!"
    ((totalErrors+=1))
else
    echo "Successfully found the HTML title 'Docker Containers Monitor' in the uServer-Monitor cURL response!"
fi

echo "Getting uServer-Whoami container output using cURL"
whoamiOutput=$(curl -s "http://whoami.userver.lan/" || true)

echo "Checking for the uServer-Whoami 'Host' response"
statusLine=$(echo "$whoamiOutput" | grep "Host: whoami.userver.lan" || true)
if [ "$statusLine" == "" ]; then
    echo "Failed finding the host line containing 'whoami.userver.lan' in the uServer-Whoami cURL response!"
    ((totalErrors+=1))
else
    echo "Successfully found the host line containing 'whoami.userver.lan' in the uServer-Whoami cURL response!"
fi

if [ "$totalErrors" -gt "0" ]; then
  echo "A total of $totalErrors occurred when running the tests. Please check the logs.";
  exit 1
fi

echo "E2E Tests successfully executed!"
