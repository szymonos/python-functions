#!/usr/bin/pwsh -nop
#Requires -Version 7.0
<#
.SYNOPSIS
Setup Python virtual environment in the project and much more...
.EXAMPLE
./pysetup.ps1 -Venv         # *Setup python virtual environment
./pysetup.ps1 -DelVenv      # *Delete python virtual environment
./pysetup.ps1 -CleanUp      # *Delete all cache folders
./pysetup.ps1 -PurgeCache   # *Purge pip cache
./pysetup.ps1 -Reqs         # *Install requirements
./pysetup.ps1 -Upgrade      # *Upgrade installed python modules
./pysetup.ps1 -SshKey       # *Generate key pairs for SSH
./pysetup.ps1 -SslTrust     # *Trust SSL connection to pypi.org
./pysetup.ps1 -SetEnv       # *Set environment variables
./pysetup.ps1 -GetEnv       # *Get environment variables
./pysetup.ps1 -List         # *List installed modules
./pysetup.ps1 -Activate     # *Activate virtual environment
./pysetup.ps1 -Deactivate   # *Deactivate virtual environment
#>

param (
    [switch]$Venv,
    [switch]$DelVenv,
    [switch]$CleanUp,
    [switch]$PurgeCache,
    [switch]$Reqs,
    [switch]$Upgrade,
    [switch]$SshKey,
    [switch]$SslTrust,
    [switch]$SetEnv,
    [switch]$GetEnv,
    [switch]$List,
    [switch]$Activate,
    [switch]$Deactivate
)

# *Root directory of the application.
$APP_DIR = 'app'

# constants
$VENV_DIR = '.venv'
$GITIGNORE = 'https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore'

# calculate script variables
[array]$req_files = 'requirements.txt'
if ($APP_DIR) {
    $appReq = [IO.Path]::Combine($APP_DIR, $req_files[0])
    if (Test-Path $appReq) {
        $req_files += $appReq
    }
}
$req = @{
    name  = $req_files[0]
    value = "black`nflake8`nipykernel`nnotebook`npydocstyle`npylint`npypath-magic`n"
}
$localSettings = [IO.Path]::Combine($APP_DIR, 'local.settings.json')
$activateScript = [IO.Path]::Combine($VENV_DIR, ($IsWindows ? 'Scripts' : 'bin'), 'Activate.ps1')
$venvCreated = Test-Path $activateScript
$initScript = [IO.Path]::Combine('.vscode', 'init.ps1')

# *Activate virtual environment.
if ($Activate -or $Upgrade -or $Venv) {
    if ($null -eq $env:VIRTUAL_ENV -and $venvCreated) {
        & $activateScript
    }
}

# *Deactivate virtual environment.
if ($Deactivate -and $env:VIRTUAL_ENV) {
    deactivate
}

# *Setup python virtual environment.
if ($Venv) {
    # create virtual environment
    if ($null -eq $env:VIRTUAL_ENV) {
        "`e[96mSet up Python environment.`e[0m"
        if (!$venvCreated) {
            python -m venv $VENV_DIR
        }
        # activate virtual environment
        & $activateScript
    } else {
        "`e[96mVirtual environment already set.`e[0m"
    }
    # add files to the project
    if (!(Test-Path '.gitignore')) {
        "`e[95madd Python.gitignore`e[0m"
        (New-Object System.Net.WebClient).DownloadFile($GITIGNORE, '.gitignore')
    }
    if (!(Test-Path $req.name)) {
        "`e[95madd requirements.txt with dev modules`e[0m"
        New-Item $req.name -Value $req.value | Out-Null
    }
    if (!(Test-Path $initScript)) {
        "`e[95mcreate init.ps1 for virtual environment activation`e[0m"
        $initContent = (
            "#!/usr/bin/pwsh -nop`n#Requires -Version 7.0" +
            "`$activateScript = [IO.Path]::Combine('$VENV_DIR', (`$IsWindows ? 'Scripts' : 'bin'), 'Activate.ps1')`n" +
            "if (Test-Path `$activateScript) {`n`t& `$activateScript`n}`n"
        )
        New-Item -Path $initScript -Value $initContent -Force | Out-Null
        if ($IsLinux) {
            chmod +x $initScript
        }
    }
    if (!(Get-Command func)) {
        "`e[95minstall Azure Functions Core Tools`e[0m"
        if ($IsWindows) {
            winget.exe install Microsoft.AzureFunctionsCoreTools
        } elseif ($IsLinux) {
            curl 'https://packages.microsoft.com/keys/microsoft.asc' | gpg --dearmor > microsoft.gpg
            sudo mv microsoft.gpg '/etc/apt/trusted.gpg.d/microsoft.gpg'
            sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
            sudo apt-get update
            sudo apt-get install azure-functions-core-tools-3
        }
    }
}

# *Delete python virtual environment.
if ($DelVenv) {
    if ($env:VIRTUAL_ENV) {
        deactivate
    }
    if ($venvCreated) {
        "`e[96mDelete virtual environment.`e[0m"
        Remove-Item $VENV_DIR -Recurse -Force
    } else {
        "`e[96mVirtual environment not exists.`e[0m"
    }
}

# *Delete all cache folders
if ($CleanUp) {
    $dirs = Get-ChildItem -Directory -Exclude '.venv'
    foreach ($d in $dirs) {
        if ($d.Name -match '_cache$|__pycache__') {
            Remove-Item $d -Recurse -Force
        } else {
            @('*_cache', '__pycache__') | ForEach-Object {
                [IO.Directory]::GetDirectories($d.FullName, $_, 1) | `
                    Remove-Item -Recurse -Force
            }
        }
    }
}

# *Purge pip cache.
if ($PurgeCache) {
    pip cache purge
}

# *Upgrade pip, wheel and setuptools.
if ($Reqs -or $Venv -or $Upgrade) {
    "`e[95mupgrade pip, wheel and setuptools`e[0m"
    python -m pip install -U pip wheel setuptools
}

# *Install requirements.
if ($Reqs -or $Venv) {
    if (Test-Path $req.name) {
        # get modules from requirements files
        $modules = $req_files | ForEach-Object { Get-Content $_ }
    }
    if ($modules) {
        "`e[95install requirements`e[0m"
        $reqs_temp = 'reqs_temp.txt'
        Set-Content -Path $reqs_temp -Value $modules
        python -m pip install -U -r $reqs_temp
        Remove-Item $reqs_temp
    }
    # add project path in virtual environment
    if ($env:VIRTUAL_ENV -and 'pypath-magic' -in $modules) {
        pypath add ([IO.Path]::Combine($PWD, $APP_DIR)) 2>$null
        pypath add $PWD 2>$null
    }
}

# *Upgrade all modules.
if ($Upgrade) {
    $modules = (python -m pip list --format=json | ConvertFrom-Json).name
    if ($modules) {
        "`e[95mupgrade all modules`e[0m"
        $reqs_temp = 'reqs_temp.txt'
        Set-Content -Path $reqs_temp -Value $modules
        python -m pip install -U -r $reqs_temp
        Remove-Item $reqs_temp
    }
}

# *Generate key pairs for SSH authentication in remote repository.
if ($SshKey) {
    if ($IsLinux) {
        if (!(Test-Path '~/.ssh/id_rsa.pub')) {
            # create new authentication key pairs for SSH if not exist
            sh -c "ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''"
        }
        "`e[95mAdd below key to the repository's SSH keys:`e[0m"
        Get-Content '~/.ssh/id_rsa.pub'
    } elseif ($IsWindows) {
        "`e[96mYou don't need to crete key for SSH, use HTTPS.`e[0m`n"
    }
}

# *Trust SSL connection to pypi.org.
if ($SslTrust) {
    if ($IsWindows) {
        $pipLocation = "$env:APPDATA\pip\pip.ini"
    } elseif ($IsLinux -or $IsMacOS) {
        $pipLocation = "$env:HOME/.config/pip/pip.conf"
    }
    $pipConfDir = [IO.Path]::GetDirectoryName($pipLocation)
    if (!(Test-Path $pipConfDir)) { New-Item $pipConfDir -ItemType Directory | Out-Null }
    Set-Content $pipLocation -Value "[global]`ntrusted-host = pypi.org`n`tpypi.python.org`n`tfiles.pythonhosted.org"
}

# *Project environment variables.
if ($SetEnv -or $GetEnv) {
    if (Test-Path $localSettings) {
        "`e[96mUsing variables configured in local.settings.json.`e[0m"
        $envVars = (Get-Content ([IO.Path]::Combine($APP_DIR, 'local.settings.json')) | ConvertFrom-Json).Values
        # set environment user variables used in the project
        if ($SetEnv) {
            # set environment targed depending on host system
            foreach ($prop in $envVars.PSObject.Properties) {
                if ($IsWindows) {
                    [Environment]::SetEnvironmentVariable($prop.Name, $prop.Value, 'User')
                    # refresh environment
                    try {
                        RefreshEnv.cmd
                    } catch {
                        taskkill.exe /F /IM explorer.exe; Start-Process explorer.exe
                    }
                } else {
                    if (!([Environment]::GetEnvironmentVariable($prop.Name))) {
                        "export $($prop.Name)=""$($prop.Value)""" >> ~/.profile
                    }
                }
            }
        }
        # get environment user variables used in the project
        if ($GetEnv) {
            foreach ($prop in $envVars.PSObject.Properties) {
                [PSCustomObject]@{
                    Variable = $prop.Name;
                    Value    = [Environment]::GetEnvironmentVariable($prop.Value)
                }
            }
        }
    } else {
        Write-Warning "File 'local.settings.json' not exists!`n`t Set environment variables there."
    }
}

# *List installed modules.
if ($List) {
    python -m pip list --format=json | ConvertFrom-Json | Tee-Object -Variable modules
    $pipPath = (python -m pip -V) -replace ('^.*from |pip \(.*$', '')
    "`n`e[96m$(python -V) `e[0m|`e[96m $($modules.Count) modules installed in `e[1;34m$pipPath`e[0m"
}
