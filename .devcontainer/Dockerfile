# Find the Dockerfile for mcr.microsoft.com/azure-functions/python:3.0-python3.8-core-tools at this URL
# https://github.com/Azure/azure-functions-docker/blob/master/host/3.0/buster/amd64/python/python38/python38-core-tools.Dockerfile
FROM mcr.microsoft.com/vscode/devcontainers/python:3.9-buster

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN \
    #
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list \
    && curl -sL https://packages.microsoft.com/keys/microsoft.asc | (OUT=$(apt-key add - 2>&1) || echo $OUT) \
    #
    && apt-get update \
    && apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common lsb-release \
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | apt-key add - 2>/dev/null \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    && apt-get update && apt-get upgrade -y \
    # Install Azure Functions, .NET Core, and Azure CLI
    && apt-get install -y azure-cli dotnet-sdk-3.1 azure-functions-core-tools-3 \
    # Install Docker CE CLI (needed for publish with --build-native-deps)
    && apt-get install -y docker-ce-cli \
    # Install Microsoft ODBC driver for SQL Server
    # https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools unixodbc-dev \
    && apt-get install -y powershell \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/vscode/.local/share \
    && chown -R vscode /home/vscode

# Azure Functions Core Tools needs a place to save data
ENV XDG_DATA_HOME=/home/vscode/.local/share

# Install PowerShell modules
SHELL ["/usr/bin/pwsh", "-c"]
RUN $ErrorActionPreference='Stop'; \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name PSReadLine -AllowPrerelease -Force; \
    Install-Module -Name posh-git -Force; \
    Enable-ExperimentalFeature PSAnsiRenderingFileInfo

COPY src/profile.ps1 /root/.config/powershell/

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
