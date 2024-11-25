FROM --platform=$TARGETPLATFORM debian:bookworm@sha256:eaace54a93d7b69c7c52bb8ddf9b3fcba0c106a497bc1fdbb89a6299cf945c63

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Set up non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY scripts/*/*.sh /tmp/
RUN bash /tmp/non-root-user.sh "${USERNAME}" "${USER_UID}" "${USER_GID}" && rm /tmp/non-root-user.sh

ARG CI_JOB_TOKEN
# Terraform versions
ARG TERRAFORM_VERSION=1.9.1
ARG TF_DOCS_VERSION=0.16.0
ARG TFLINT_VERSION=0.54.0
ARG INSPEC_VERSION=5.12.2
ARG TFENV_VERSION=3.0.0
ARG TARGETARCH

# This is the SSL Intercepting proxy in use at DWP. Requests made by tools will
# return with an insecure certificate without this added to the CA Store.
COPY assets/zscaler.pem /usr/local/share/ca-certificates/Zscaler_Root_CA.crt

RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    /home/$USERNAME/.vscode-server-insiders/extensions \
    && chown -R $USERNAME \
    /home/$USERNAME/.vscode-server \
    /home/$USERNAME/.vscode-server-insiders
    

RUN mkdir -p /home/$USERNAME/.ssh 
RUN chown -R $USERNAME /home/$USERNAME/.ssh

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    zsh \
    apt-utils \
    dialog \
    icu-devtools \
    git\
    wget\
    vim \
    openssh-client \
    less \
    curl \
    procps \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    bash-completion\
    sudo \
    make \
    gnupg \
    apt-transport-https \
    figlet \
    # install `column` via bsdmainutils
    bsdmainutils \ 
    # Networking tools (ifconfig, ping, dig)
    net-tools \
    iputils-ping \
    dnsutils \
    python3-pip \
    # Install the DWP ZScaler certificate
    && update-ca-certificates

# setup Azure CLI source
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
    && AZ_REPO=$(lsb_release -cs) \
    && echo "deb [arch=$TARGETARCH] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get -y install azure-cli --no-install-recommends \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform, tflint, Inspec, Flyway
RUN mkdir -p /tmp/dc-downloads \
    && curl -sSL -o /tmp/dc-downloads/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip \
    && unzip /tmp/dc-downloads/terraform.zip \
    && mv terraform /usr/local/bin \
    && terraform -install-autocomplete \
    # Install tflint
    && curl -sSL -o /tmp/dc-downloads/tflint.zip https://github.com/wata727/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${TARGETARCH}.zip \
    && unzip /tmp/dc-downloads/tflint.zip \
    && mv tflint /usr/local/bin \
    # Install Inspec
    && curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec -v ${INSPEC_VERSION} \
    # Install Terraform-docs
    && curl -Lo /tmp/dc-downloads/terraform-docs https://github.com/terraform-docs/terraform-docs/releases/download/v${TF_DOCS_VERSION}/terraform-docs-v${TF_DOCS_VERSION}-$(uname | tr '[:upper:]' '[:lower:]')-${TARGETARCH} \
    && chmod +x /tmp/dc-downloads/terraform-docs \
    && mv /tmp/dc-downloads/terraform-docs /usr/local/bin \
    # # Install tfEnv
    # && wget -O /tmp/tfenv.tar.gz "https://github.com/tfutils/tfenv/archive/refs/tags/v${TFENV_VERSION}.tar.gz" \
    # && tar -C /tmp -xf /tmp/tfenv.tar.gz \
    # && mv "/tmp/tfenv-${TFENV_VERSION}/bin"/* /usr/local/bin/ \
    # && mkdir -p /usr/local/lib/tfenv \
    # && mv "/tmp/tfenv-${TFENV_VERSION}/lib" /usr/local/lib/tfenv/ \
    # && mv "/tmp/tfenv-${TFENV_VERSION}/libexec" /usr/local/lib/tfenv/ \
    # && mkdir -p /usr/local/share/licenses \
    # && mv "/tmp/tfenv-${TFENV_VERSION}/LICENSE" /usr/local/share/licenses/tfenv \
    # && rm -rf /tmp/tfenv* \
    # && mkdir /usr/local/lib/tfenv/versions \
    # && chown -R $USERNAME /usr/local/lib/tfenv/ \
    # Clean up downloaded files
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && cd ~ \ 
    && rm -rf /tmp/dc-downloads

#TFENV Vars
ENV TFENV_ROOT /usr/local/lib/tfenv

# Default to latest; user-specifiable
# ENV TFENV_TERRAFORM_VERSION latest

# Install Python packages (ansible, service-deployment etc)
COPY requirements.txt /tmp/requirements.txt
# RUN git config --global url."https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.com".insteadOf ssh://git@gitlab.com \

#  commenting pip install out as it fails due to python error
# RUN pip install --no-cache-dir --requirement /tmp/requirements.txt && rm /tmp/requirements.txt

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# switch to user
USER $USERNAME
