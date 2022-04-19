FROM ubuntu:20.04

ENV TZ=Europe/London \
    DEBIAN_FRONTEND=noninteractive

LABEL Name="azadmin"

# ADD assets/zscaler.pem /usr/local/share/ca-certificates/zscaler.crt
# RUN chmod 644 /usr/local/share/ca-certificates/zscaler.crt && \
#   apt-get update && apt-get install -y ca-certificates  &&\
#   update-ca-certificates

# ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN cd /tmp && \
    apt update && \
    apt-get install -y wget unzip curl lsb-release gnupg python3-pip python3-minimal && \
    apt-get install -y git 

# Install Azure CLI
RUN apt-get update && apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg && \
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null && \
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=arm64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y azure-cli && \
    az extension add --name azure-devops
    

# ADD assets/zscaler.pem /tmp/zscaler.pem
# RUN chmod 644 /tmp/zscaler.pem && cat /tmp/zscaler.pem >> /opt/az/lib/python3.6/site-packages/certifi/cacert.pem
    
RUN wget https://releases.hashicorp.com/terraform/1.1.8/terraform_1.1.8_linux_amd64.zip --no-check-certificate && \
    unzip ./terraform_1.1.8_linux_amd64.zip -d /usr/local/bin/

# Install powershell
RUN apt-get update && apt-get install -y wget apt-transport-https software-properties-common ca-certificates && \
    wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb --no-check-certificate  && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y powershell && \
    pwsh -command "Install-Module -Name Az -AllowClobber -Force -Confirm:\$false && Import-Module -Name Az"

# install vim
RUN apt-get update \
    && apt-get install vim -y