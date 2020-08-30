<#
.SYNOPSIS
Setup virtual environment in the project and set environment variables.
.EXAMPLE
.\pysetup.ps1 -Venv            # *Setup python virtual environment
.\pysetup.ps1 -AzureFuncTools  # *Instal Azure Functions Core Tools
.\pysetup.ps1 -AddFiles        # *Add .gitignore, requirements and init to the project
.\pysetup.ps1 -SetEnv          # *Set environment variables
.\pysetup.ps1 -Upgrade         # *Upgrade installed python modules
.\pysetup.ps1 -List            # *List installed modules
.\pysetup.ps1 -Activate        # *Activate virtual environment
.\pysetup.ps1 -Deactivate      # *Deactivate virtual environment
#>

param (
    [switch]$Venv,
    [switch]$AzureFuncTools,
    [switch]$AddFiles,
    [switch]$SetEnv,
    [switch]$Upgrade,
    [switch]$List,
    [switch]$Activate,
    [switch]$Deactivate
)

# Configuration variables
$PROJ_PATH = ''

# Static script variables
[array]$REQ_FILES = 'requirements.txt'
if ($PROJ_PATH) { $REQ_FILES += [IO.Path]::Combine($PROJ_PATH, $REQ_FILES[0]) }
$VENV_PATH = [IO.Path]::Combine($PROJ_PATH, '.venv')
$activeatePath = if ($IsWindows) { 'Scripts' } else { 'bin' }
$ACTIVATE_SCRIPT = [IO.Path]::Combine($VENV_PATH, $activeatePath, 'Activate.ps1')
$INIT_SCRIPT = [IO.Path]::Combine('.vscode', 'init.ps1')
$GITIGNORE = 'https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore'
$REQ = @{
    NAME  = $REQ_FILES[0]
    VALUE = "autopep8`nipykernel`nnotebook`npycodestyle`npytest`npylint`nisort`nlazy-object-proxy`nparso`npypath-magic`n"
}

# Activate virtual environment
if ($Activate -or $Upgrade) {
    if ($null -eq $env:VIRTUAL_ENV -and $VENV_CREATED) {
        & $ACTIVATE_SCRIPT
    }
}

# Deactivate virtual environment
if ($Deactivate -and $env:VIRTUAL_ENV) {
    deactivate
}

# Add .gitignore, requirements.txt and init.ps1 files to project
if ($AddFiles -or $Venv) {
    # add python .gitignore if not exists
    if (!(Test-Path '.gitignore')) {
        (New-Object System.Net.WebClient).DownloadFile($GITIGNORE, '.gitignore')
    }
    # add requirements.txt with dev modules if not exists
    if (!(Test-Path $REQ.NAME)) {
        New-Item $REQ.NAME -Value $REQ.VALUE | Out-Null
    }
    # add init.ps1 calling venv activation script
    if (!(Test-Path $INIT_SCRIPT)) {
        $initContent = ('$activatePath = if ($IsWindows) { ''Scripts'' } else { ''bin'' }' + "`n" +
            '$activateScript = [IO.Path]::Combine(''{0}'', ''.venv'', $activatePath, ''Activate.ps1'')' -f $PROJ_PATH +
            "`n" + 'if (Test-Path $activateScript) { & $activateScript }' + "`n")
        New-Item -Path $INIT_SCRIPT -Value $initContent -Force | Out-Null
    }
}

# Setup python virtual environment
if ($Venv) {
    if ($null -eq $env:VIRTUAL_ENV) {
        # create a virtual environment
        if (!$VENV_CREATED) {
            python -m venv $VENV_PATH
        }
        # activate virtual environment
        & $ACTIVATE_SCRIPT
        # Upgrade pip
        python -m pip install --upgrade pip
        # Install project requirements
        foreach ($req in $REQ_FILES) {
            python -m pip install -r $req --use-feature=2020-resolver
        }
    } else {
        "`nVirtual environment already set.`n"
    }
}

# Upgrade all modules
if ($Upgrade -or $Venv) {
    # Upgrade pip and modules from requirements
    if (!($Venv)) {
        python -m pip install --upgrade pip
        foreach ($req in $REQ_FILES) {
            python -m pip install -r $req -U --use-feature=2020-resolver
        }
    }
    # Upgrade all other modules
    $req_modules = foreach ($req in $REQ_FILES) {
        Get-Content $req | ForEach-Object { ($_ -split ('=='))[0] }
    }
    $outdated = (python -m pip list -o --format=json | ConvertFrom-Json).name | `
        Where-Object { $_ -notin $req_modules }
    if ($outdated.Count -gt 0) {
        $outdated | ForEach-Object {
            python -m pip install -U --use-feature=2020-resolver $_
        }
    } else {
        "`nAll modules are up to date.`n"
    }
    # Add project path to environment
    if ('pypath-magic' -in $req_modules) {
        pypath add ([IO.Path]::Combine($PWD, $PROJ_PATH)) 2>$null
    }
}

if ($AzureFuncTools) {
    if ($IsWindows) {
        choco install azure-functions-core-tools-3 --params "'/x64'" -y
    } else {
        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
        sudo apt-get update
        sudo apt-get install azure-functions-core-tools-3
    }
}

# Set environment user variables for the project
if ($SetEnv) {
    [Environment]::SetEnvironmentVariable('ENV_NAME', 'value', 'User')   # !set value
}

# list installed modules
if ($List) {
    $modules = python -m pip list --format=json | ConvertFrom-Json; $modules
    $pipPath = ((python -m pip -V) -split (' '))[3] -replace ('\\pip', '')
    "`n({0}) modules installed in '{1}'" -f $modules.Count, $pipPath
}
