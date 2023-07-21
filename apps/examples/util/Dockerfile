FROM ubuntu:20.04
LABEL description="Util image using Ubuntu"
ARG KUBECTL_VERSION="v1.21.3"
ARG TF_VERSION="1.5.1"
ARG HELM_VERSION="v3.3.4"
ARG ARGOCD_VERSION="v1.7.7"
ARG KUBESEAL_VERSION="v0.12.6"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends sudo

# Utils
RUN apt-get update && apt-get install -y --no-install-recommends wget curl unzip vim openssh-client httpie jq tcpdump dnsutils traceroute nmap

# Google Repo
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg trusted=yes] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN apt-get update &&  apt-get install -y --no-install-recommends  apt-transport-https ca-certificates gnupg
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Programming tools
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip python3-setuptools git php npm 

# DB tools
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-client mysql-client

# Ansible
RUN pip install ansible


# AWS cli
RUN pip install --upgrade awscli

# PIP Packages
RUN pip install --upgrade awscli pylint yamllint

# Terraform
RUN wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip -O /tmp/terraform_${TF_VERSION}_linux_amd64.zip 
RUN unzip /tmp/terraform_${TF_VERSION}_linux_amd64.zip -d /usr/local/bin
RUN mv /usr/local/bin/terraform /usr/local/bin/terraform12
RUN ln -s /usr/local/bin/terraform12 /usr/local/bin/terraform

# Gcloud SDK
RUN apt-get update &&  apt-get install -y --no-install-recommends  google-cloud-sdk
RUN gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version

# Kubectl
RUN apt-get update && apt-get install -y --no-install-recommends kubectl

# Helm
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz  -O /tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz 
RUN cd /tmp && tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz  linux-amd64/helm && mv linux-amd64/helm /usr/local/bin

# Argocd
RUN wget https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64 -O /usr/local/bin/argocd
RUN chmod +x /usr/local/bin/argocd

# Kubeseal
RUN wget https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-linux-amd64 -O /tmp/kubeseal
RUN install -m 755 /tmp/kubeseal /usr/local/bin/kubeseal

# Docker
RUN apt-get update && apt-get install -y --no-install-recommends docker.io

CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"