# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/python:3.0-python3.8-appservice
FROM mcr.microsoft.com/azure-functions/python:3.0-python3.8-slim

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true \
    PYTHONPATH=${PYTHONPATH}:/home/site/wwwroot

# copy sshd_config for vscode remote connection
# COPY .devcontainer/config/sshd/sshd_config /etc/ssh/

WORKDIR /home/site/wwwroot

COPY app/requirements.txt .

# Configure apt and install packages
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils \
    && apt-get install -y build-essential unixodbc-dev \
    # Add sftp server to known hosts
    # && ssh-keyscan -H download.webtrekk.com >> /etc/ssh/ssh_known_hosts \
    # upgrade pip
    && python -m pip install -U pip setuptools wheel \
    # install application requirements
    && python -m pip install -r requirements.txt --no-cache-dir

COPY app/ .

ARG TAG_NAME

ENV IMG_TAG=$TAG_NAME

# Switches to a non-root user and changes the ownership of the /app folder"
# RUN useradd appuser && chown -R appuser /home/site/wwwroot
# USER appuser
