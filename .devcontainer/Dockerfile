# Find the Dockerfile at this URL
# https://github.com/Azure/azure-functions-docker/blob/dev/host/4/bullseye/amd64/python/python310/python310-core-tools.Dockerfile
FROM mcr.microsoft.com/azure-functions/python:4-python3.10-core-tools

COPY config/pwsh_cfg/* /tmp/pwsh_cfg/

RUN \
    # install powershell profile
    mkdir -p /opt/microsoft/powershell/7 \
    && install -m 0644 /tmp/pwsh_cfg/profile.ps1 /opt/microsoft/powershell/7 \
    # install powershell aliases
    && mkdir -p /usr/local/share/powershell/Scripts \
    && install -m 0644 /tmp/pwsh_cfg/_aliases_common.ps1 /usr/local/share/powershell/Scripts \
    && install -m 0644 /tmp/pwsh_cfg/_aliases_linux.ps1 /usr/local/share/powershell/Scripts \
    # cleanup
    && rm -rf /tmp/pwsh_cfg
