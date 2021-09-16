#!/usr/bin/env sh

nginx

echo "Starting the stats watcher fo every $REFRESH_EVERY_SECONDS second(s)"
nohup watch -n"$REFRESH_EVERY_SECONDS" 'sh /etc/monitor/refresh.sh' > /dev/null
