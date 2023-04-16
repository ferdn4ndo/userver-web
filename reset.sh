#!/usr/bin/env bash

echo "WARNING: THIS PROCESS WILL DELETE THE EXISTING CERTIFICATES FOR EVERY HOST!"
echo "THIS IS IRREVERSIBLE!"

echo ""
echo "Are you sure you want to continue? (LAST CHANCE!)"
read -p "Type 'Y' to continue or any other key to abort:" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborting."
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

sudo rm "$DIR/certs/*.crt" "$DIR/certs/*.key" "$DIR/certs/*.pem"

sudo rm "$DIR/nginx-proxy/conf/default.conf"
