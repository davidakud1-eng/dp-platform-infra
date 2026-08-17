#!/bin/bash

set -euxo pipefail

dnf update -y

dnf install -y \
git \
wget \
unzip \
tar \
vim \
tree \
jq \
python3 \
python3-pip \
python3-virtualenv

dnf clean all

echo "Bootstrap completed successfully on $(date)" > /var/log/dp-bootstrap.log