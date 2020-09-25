# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/python:3.0-python3.8-appservice
FROM mcr.microsoft.com/azure-functions/python:3.0-python3.8-appservice

# Configure apt and install packages
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y build-essential unixodbc-dev

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true \
    PYTHONPATH=${PYTHONPATH}:/home/site/wwwroot

COPY .devcontainer/src/sshd_config /etc/ssh/
COPY app/ /home/site/wwwroot/
RUN python -m pip install -U pip && \
    python -m pip install -r /home/site/wwwroot/requirements.txt --use-feature=2020-resolver
