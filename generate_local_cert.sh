#!/bin/bash

echo "WARNING: This script will generate a self-signed certificate to be used by nginx to serve HTTPS under local environment."
read -p "Continue (y/n)?" CONT
if [ "$CONT" = "y" ]; then
    # from https://letsencrypt.org/docs/certificates-for-localhost/
    openssl req -x509 -out ./certs/default.crt -keyout ./certs/default.key \
        -newkey rsa:2048 -nodes -sha256 \
        -subj '/CN=localhost' -extensions EXT -config <( \
        printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
    echo "Saved cert files to default.crt and default.key"
else
  echo "No changes were made.";
fi
