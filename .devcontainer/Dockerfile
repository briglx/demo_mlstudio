# Python 3.10.0
# Debian 11 (bullseye)
FROM mcr.microsoft.com/devcontainers/python:3.10-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        git \
        gnupg \
        gnupg2 \
        lsb-release \
        jq \
        lsb-release \
        shellcheck \
        vim \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI latest (2.51.0)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install wslu
RUN curl https://pkg.wslutiliti.es/public.key | sudo tee -a /etc/apt/trusted.gpg.d/wslu.asc && \
    echo "deb https://pkg.wslutiliti.es/debian bullseye main" | sudo tee -a /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    wslu \
    && rm -rf /var/lib/apt/lists/*

# Helpful aliases
RUN echo 'alias ll='"'"'ls $LS_OPTIONS -al'"'"'' >> /etc/bash.bashrc

# Copy requirements.txt
COPY ./requirements.txt .
COPY ./requirements_dev.txt .

# Install requirements.txt
RUN pip3 install -r requirements_dev.txt
