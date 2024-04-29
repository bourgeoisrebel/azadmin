#!/bin/bash

keydest=assets/zscaler.pem
mkdir assets
security find-certificate -a -e support@zscaler.com -p >$keydest

retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error - copy of the zScaler public key failed"
    exit $retVal
fi

echo "Building docker container"
docker build -t azadmin:latest --platform linux/x86_64  -f dockerfile .

retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error - Docker build failed"
    exit $retVal
fi
