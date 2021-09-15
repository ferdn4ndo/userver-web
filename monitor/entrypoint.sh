#!/usr/bin/env sh

nginx
nohup watch -n5 'sh /etc/monitor/refresh.sh' > /dev/null
