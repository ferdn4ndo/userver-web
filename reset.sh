#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

sudo rm "$DIR/certs/*.crt" "$DIR/certs/*.key" "$DIR/certs/*.pem"

sudo rm "$DIR/nginx-proxy/conf/default.conf"

