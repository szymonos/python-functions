# Find the Dockerfile for mcr.microsoft.com/azure-functions/python:3.0-python3.8-core-tools at this URL
# https://github.com/Azure/azure-functions-docker/blob/master/host/3.0/buster/amd64/python/python38/python38-core-tools.Dockerfile
FROM mcr.microsoft.com/azure-functions/python:3.0-python3.8-core-tools

# Install PowerShell
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell

# Install PowerShell modules
SHELL ["/usr/bin/pwsh", "-c"]
RUN $ErrorActionPreference='Stop'; \
    Start-Transcript -Path /Dockerfile.log -Append -IncludeInvocationHeader; \
    $PSVersionTable | Write-Output; \
    Install-Module posh-git -AllowPrerelease -Force; \
    Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease; \
    New-Item /root/.config/powershell/ -Type Directory -Force; \
    Stop-Transcript;

# Copy pwsh profile
COPY library-scripts/profile.ps1 /opt/microsoft/powershell/7/

# Default commands to pwsh
ENTRYPOINT ["pwsh","-c"]
