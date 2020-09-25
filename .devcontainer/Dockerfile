# Find the Dockerfile for mcr.microsoft.com/azure-functions/python:3.0-python3.8-core-tools at this URL
# https://github.com/Azure/azure-functions-docker/blob/master/host/3.0/buster/amd64/python/python38/python38-core-tools.Dockerfile
FROM mcr.microsoft.com/azure-functions/python:3.0-python3.8-core-tools

    # Download and register the Microsoft repository GPG keys
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    # Install Microsoft ODBC driver for SQL Server
    # https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools unixodbc-dev && \
    # Install PowerShell and Neofetch
    # https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux
    apt-get install -y powershell neofetch

# Install PowerShell modules
SHELL ["/usr/bin/pwsh", "-c"]
RUN $ErrorActionPreference='Stop'; \
    Start-Transcript -Path /Dockerfile.log -Append -IncludeInvocationHeader; \
    $PSVersionTable | Write-Output; \
    Install-Module posh-git -AllowPrerelease -Force; \
    Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease; \
    New-Item /root/.config/powershell/ -Type Directory -Force; \
    Stop-Transcript;

# Copy shell profiles
COPY src/profile.ps1 /opt/microsoft/powershell/7/
COPY src/.zshrc /root/

# Default commands to pwsh
ENTRYPOINT ["zsh","-c"]
