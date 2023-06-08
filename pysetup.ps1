#!/usr/bin/env -S pwsh -nop
#Requires -Version 7.0
<#
.SYNOPSIS
Setup Python virtual environment in the project and much more...
.EXAMPLE
./pysetup.ps1 venv        # *Setup python virtual environment
./pysetup.ps1 delvenv     # *Delete python virtual environment
./pysetup.ps1 clean       # *Delete all cache folders
./pysetup.ps1 purge       # *Purge pip cache
./pysetup.ps1 reqs        # *Install requirements
./pysetup.ps1 update      # *Update installed python modules
./pysetup.ps1 sshkey      # *Generate key pairs for SSH
./pysetup.ps1 ssltrust    # *Trust SSL connection to pypi.org
./pysetup.ps1 setenv      # *Set environment variables
./pysetup.ps1 getenv      # *Get environment variables
./pysetup.ps1 list        # *List installed modules
./pysetup.ps1 activate    # *Activate virtual environment
./pysetup.ps1 deactivate  # *Deactivate virtual environment
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('venv', 'delvenv', 'clean', 'purge', 'reqs', 'update', 'sshkey', 'ssltrust', 'setenv', 'getenv', 'list', 'activate', 'deactivate')]
    [string]$Option,

    [Alias('p')]
    [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
    [string]$AppPath
)

# constants
$VENV_DIR = '.venv'
$GITIGNORE = 'https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore'
$SKIP_MODS_UPDATE = @('dbus-python')

# calculate script variables
$req_files = [Collections.Generic.List[string]]::new([string[]]@('requirements.txt'))
if ($AppPath) {
    $appReq = [IO.Path]::Combine($AppPath, 'requirements.txt')
    if (Test-Path $appReq) {
        $req_files.Add($appReq)
    }
}
$req = @{
    name  = $req_files[0]
    value = "black`nflake8`nipykernel`nnotebook`npydocstyle`npylint`npypath-magic`n"
}
$localSettings = [IO.Path]::Combine($AppPath, 'local.settings.json')
$activateScript = [IO.Path]::Combine($VENV_DIR, ($IsWindows ? 'Scripts' : 'bin'), 'Activate.ps1')
$venvCreated = Test-Path $activateScript
$initScript = [IO.Path]::Combine('.vscode', 'init.ps1')

# get environment variables from local.settings.json file
if ($option -in @('setenv', 'getenv')) {
    if (Test-Path $localSettings) {
        Write-Host "`e[96mUsing variables configured in local.settings.json.`e[0m"
        $envVars = (Get-Content ([IO.Path]::Combine($AppPath, 'local.settings.json')) | ConvertFrom-Json).Values
    } else {
        Write-Warning "File `e[1;3mlocal.settings.json`e[23m not exists!`n`t Set environment variables there."
        exit
    }
}

switch ($Option) {
    # *Activate virtual environment.
    { $_ -in @('activate', 'update', 'venv') -and -not $env:VIRTUAL_ENV -and $venvCreated } {
        & $activateScript
        if ($Option -eq 'activate') {
            break
        }
    }

    # *Deactivate virtual environment.
    { $_ -eq 'deactivate' -and $env:VIRTUAL_ENV } {
        deactivate
        break
    }

    # *Delete python virtual environment.
    delvenv {
        if ($env:VIRTUAL_ENV) {
            deactivate
        }
        if (Test-Path $VENV_DIR) {
            Write-Host "`e[96mDelete virtual environment.`e[0m"
            Remove-Item $VENV_DIR -Recurse -Force
        } else {
            Write-Host "`e[96mVirtual environment not exists.`e[0m"
        }
        break
    }

    # *Delete all cache folders
    clean {
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
        break
    }

    # *Purge pip cache.
    purge {
        pip cache purge
        break
    }

    # *Generate key pairs for SSH authentication in remote repository.
    sshkey {
        if ($IsLinux) {
            if (!(Test-Path '~/.ssh/id_rsa.pub')) {
                # create new authentication key pairs for SSH if not exist
                sh -c "ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''"
            }
            Write-Host "`e[95mAdd below key to the repository's SSH keys:`e[0m"
            Get-Content '~/.ssh/id_rsa.pub'
        } elseif ($IsWindows) {
            Write-Host "`e[96mYou don't need to crete key for SSH, use HTTPS.`e[0m`n"
        }
        break
    }

    # *Trust SSL connection to pypi.org.
    ssltrust {
        if ($IsWindows) {
            $pipLocation = "$env:APPDATA\pip\pip.ini"
        } elseif ($IsLinux -or $IsMacOS) {
            $pipLocation = "$env:HOME/.config/pip/pip.conf"
        }
        $pipConfDir = [IO.Path]::GetDirectoryName($pipLocation)
        if (!(Test-Path $pipConfDir)) { New-Item $pipConfDir -ItemType Directory | Out-Null }
        Set-Content $pipLocation -Value "[global]`ntrusted-host = pypi.org`n`tpypi.python.org`n`tfiles.pythonhosted.org"
        break
    }

    # *Set project environment variables.
    setenv {
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
        break
    }

    # *Get project environment variables.
    getenv {
        foreach ($prop in $envVars.PSObject.Properties) {
            [PSCustomObject]@{
                Variable = $prop.Name;
                Value    = [Environment]::GetEnvironmentVariable($prop.Value)
            }
        }
        break
    }

    # *List installed modules.
    list {
        python -m pip list --format=json | ConvertFrom-Json | Tee-Object -Variable modules | Format-Table
        $pipPath = (python -m pip -V) -replace '^.*from |pip \(.*$'
        Write-Host "`e[96m$(python -V) `e[0m|`e[96m $($modules.Count) modules installed in `e[1;34m$pipPath`e[0m"
        break
    }

    # *Setup python virtual environment.
    venv {
        # create virtual environment
        if ($null -eq $env:VIRTUAL_ENV) {
            Write-Host "`e[96mSet up Python environment.`e[0m"
            if (-not $venvCreated) {
                python -m venv $VENV_DIR
            }
            # activate virtual environment
            & $activateScript
        } else {
            Write-Host "`e[96mVirtual environment already set.`e[0m"
        }
        # add files to the project
        if (-not (Test-Path '.gitignore')) {
            Write-Host "`e[95madd Python .gitignore`e[0m"
            [Net.WebClient]::new().DownloadFile($GITIGNORE, '.gitignore')
        }
        if (-not (Test-Path $req.name)) {
            Write-Host "`e[95madd `e[1;3mrequirements.txt`e[22;23m with dev modules`e[0m"
            New-Item $req.name -Value $req.value | Out-Null
        }
        if (-not (Test-Path $initScript)) {
            Write-Host "`e[95mcreate `e[1;3minit.ps1`e[22;23m for virtual environment activation`e[0m"
            $initContent = (
                "#!/usr/bin/env -S pwsh -nop`n#Requires -Version 7.0`n" +
                "`$activateScript = [IO.Path]::Combine('$VENV_DIR', (`$IsWindows ? 'Scripts' : 'bin'), 'Activate.ps1')`n" +
                "if (Test-Path `$activateScript) {`n`t& `$activateScript`n}`n"
            )
            New-Item -Path $initScript -Value $initContent -Force | Out-Null
            if ($IsLinux) {
                chmod +x $initScript
            }
        }
    }

    # *Update pip, wheel and setuptools.
    { $_ -in @('reqs', 'venv', 'update') } {
        Write-Host "`e[95mupdate pip, wheel and setuptools`e[0m"
        python -m pip install -U pip wheel setuptools
    }

    # *Install requirements.
    { $_ -in @('reqs', 'venv') } {
        if (Test-Path $req.name) {
            # get modules from requirements files
            $modules = $req_files | ForEach-Object { Get-Content $_ }
        }
        if ($modules) {
            Write-Host "`e[95install requirements`e[0m"
            $reqs_temp = 'reqs_temp.txt'
            Set-Content -Path $reqs_temp -Value $modules
            python -m pip install -U -r $reqs_temp
            Remove-Item $reqs_temp
        }
        # add project path in virtual environment
        if ($env:VIRTUAL_ENV -and 'pypath-magic' -in $modules) {
            pypath add ([IO.Path]::Combine($PWD, $AppPath)) 2>$null
            pypath add $PWD 2>$null
        }
        break
    }

    # *Update all modules.
    update {
        $modules = (python -m pip list --format=json | ConvertFrom-Json).name.Where({ $_ -notin $SKIP_MODS_UPDATE })
        if ($modules) {
            Write-Host "`e[95mupdate all modules`e[0m"
            $reqs_temp = 'reqs_temp.txt'
            Set-Content -Path $reqs_temp -Value $modules
            python -m pip install -U -r $reqs_temp
            Remove-Item $reqs_temp
        }
        break
    }
}
