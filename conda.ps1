#!/usr/bin/pwsh
#Requires -PSEdition Core
<#
.SYNOPSIS
Script for managing conda environments.
.EXAMPLE
./conda.ps1     # *Create/update environment
./conda.ps1 -a  # *Activate environment
./conda.ps1 -d  # *Deactivate environment
./conda.ps1 -l  # *List packages
./conda.ps1 -e  # *List environments
./conda.ps1 -c  # *Clean conda
./conda.ps1 -u  # *Update conda
./conda.ps1 -r  # !Remove environment
#>
[CmdletBinding()]
param (
    [Alias('a')][switch]$ActivateEnv,
    [Alias('d')][switch]$DeactivateEnv,
    [Alias('l')][switch]$ListPackages,
    [Alias('e')][switch]$ListEnv,
    [Alias('c')][switch]$CondaClean,
    [Alias('u')][switch]$CondaUpdate,
    [Alias('r')][switch]$RemoveEnv
)

# const
$ENV_FILE = 'conda.yaml'
# calculate script variables
$envName = (Select-String '^name:' $ENV_FILE).Line.Split(' ')[1]
$isActivEnv = $null -ne $env:CONDA_DEFAULT_ENV -and -not $DeactivateEnv -and -not $RemoveEnv
if (-not $PSBoundParameters.Count -or $RemoveEnv) {
    $envExists = $envName -in (conda env list | Select-String '^(?!#)\S+').Matches.Value
}

# *Deactivate environment
if (-not ($ListPackages -or $ListEnv)) {
    conda deactivate
}

# *Check mamba installation
if (-not $PSBoundParameters.Count -or $CondaClean -or $CondaUpdate) {
    $mamba = $env:CONDA_EXE -replace ('\bconda', 'mamba')
    if (-not (Test-Path $mamba)) {
        'mamba not found, installing...'
        conda install -n base -c conda-forge mamba
    }
}

# *Create/update environment
if (-not $PSBoundParameters.Count) {
    if ($envExists) {
        $msg = "`nEnvironment `e[1;4m$envName`e[0m already exists.`nProceed to update ([y]/n)?"
        if ((Read-Host -Prompt $msg).ToLower() -in @('', 'y')) {
            # update packages in existing environment
            & $mamba env update --file $ENV_FILE --prune
        } else {
            'Done!'
        }
    } else {
        "`e[92mCreating `e[1;4m$envName`e[0;92m environment.`e[0m"
        # create environment
        & $mamba env create --file $ENV_FILE
    }
}

# *List packages
if ($ListPackages) {
    conda list
}

# *List environments
if ($ListEnv) {
    conda env list
}

# *Clean conda
if ($CondaClean) {
    & $mamba clean --all
}

# *Update conda
if ($CondaUpdate) {
    & $mamba update --name base conda
    & $mamba update --all
}

# *Remove environment
if ($RemoveEnv -and $envExists) {
    conda env remove --name $envName
}

# *Activate environment
if (-not $PSBoundParameters.Count -or $ActivateEnv -or $isActivEnv) {
    conda activate $envName
}
