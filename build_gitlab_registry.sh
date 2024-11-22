#!/bin/bash
# This script builds a docker container used to deploy this environemnt and pushes it to the GitLab registry ready for the pipelines to use
keydest=assets/zscaler.pem
mkdir assets
security find-certificate -a -e support@zscaler.com -p >$keydest

retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error - copy of the zScaler public key failed"
    exit $retVal
fi




# You need to create a PAT token under Access Tokens in your preferences. Make sure it has read_registry, write_registry roles as a minimum. Use your fristname.lastname format of your engineering account
docker login registry.gitlab.com

echo "Building docker container"
# docker build -t azadmin:latest --platform linux/x86_64  -f dockerfile .
docker build -t registry.gitlab.com/dwp/engineering/platform/hybrid-cloud-services/azure-vmware-solution:latest --platform linux/x86_64  -f dockerfile .
docker push registry.gitlab.com/dwp/engineering/platform/hybrid-cloud-services/azure-vmware-solution -a

retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error - Docker build failed"
    exit $retVal
fi
