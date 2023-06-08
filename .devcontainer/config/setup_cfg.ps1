#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the current user.
.EXAMPLE
.devcontainer/config/setup_cfg.ps1
#>
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'Ignore'

# *PowerShell profile
$psGetVer = (Find-Module PowerShellGet -AllowPrerelease).Version
for ($i = 0; $psGetVer -and ($psGetVer -notin (Get-InstalledModule -Name PowerShellGet -AllVersions).Version) -and $i -lt 10; $i++) {
    Write-Host 'installing PowerShellGet...'
    Install-Module PowerShellGet -AllowPrerelease -Force -SkipPublisherCheck
}
# install/update modules
if (Get-InstalledModule -Name PowerShellGet) {
    if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
        Write-Host 'setting PSGallery trusted...'
        Set-PSResourceRepository -Name PSGallery -Trusted
    }
    for ($i = 0; (Test-Path /usr/bin/git) -and -not (Get-Module posh-git -ListAvailable) -and $i -lt 10; $i++) {
        Write-Host 'installing posh-git...'
        Install-PSResource -Name posh-git
    }
}
