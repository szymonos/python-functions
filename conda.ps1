#!/usr/bin/pwsh -nop
#Requires -Version 6.0
<#
.SYNOPSIS
Script for creating and managing conda environments.
.EXAMPLE
./conda.ps1     # *Create/update environment
./conda.ps1 -a  # *Activate environment
./conda.ps1 -d  # *Deactivate environment
./conda.ps1 -r  # *Remove environment
./conda.ps1 -c  # *Update conda
./conda.ps1 -l  # *List environments
#>
[CmdletBinding()]
param (
    [Alias('a')][switch]$ActivateEnv,
    [Alias('d')][switch]$DeactivateEnv,
    [Alias('r')][switch]$RemoveEnv,
    [Alias('c')][switch]$CondaUpdate,
    [Alias('l')][switch]$ListEnv
)

# const
$ENV_FILE = 'conda.yaml'
# calculate script variables
$envName = (Select-String '^name:' $ENV_FILE -Raw).Split(':')[1].Trim()
$envExists = $envName -in ((conda env list --json | ConvertFrom-Json).envs | Split-Path -Leaf)

if (-not $ListEnv) {
    conda deactivate
}

# *Create/update environment
if (-not ($RemoveEnv -or $ActivateEnv -or $DeactivateEnv -or $ListEnv -or $CondaUpdate)) {
    if (-not $envExists) {
        "`e[92mCreating `e[1m$envName`e[0;92m environment.`e[0m"
        # create environment
        conda env create --file $ENV_FILE --verbose
    } else {
        $msg = "`nEnvironment `e[1m$envName`e[0m already exists.`nDo you want to update (Y/N)?"
        if ((Read-Host -Prompt $msg).ToLower() -eq 'y') {
            # update packages in existing environment
            conda env update --file $ENV_FILE --prune
        } else {
            'Done!'
        }
    }
}

# *Remove environment
if ($RemoveEnv -and $envExists) {
    # remove environment
    conda env remove --name $envName
}

# *List environments
if ($ListEnv) {
    # list existing environments
    conda env list
}

# *Update conda
if ($CondaUpdate) {
    # update conda packages
    conda update --name base conda
    conda update --all
}

# *Activate environment
if (-not ($RemoveEnv -or $DeactivateEnv -or $ListEnv)) {
    conda activate $envName
}
