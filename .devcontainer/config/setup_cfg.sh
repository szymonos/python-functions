#!/usr/bin/env bash
: '
.devcontainer/config/setup_cfg.sh
'
# copy bash aliases
cp .devcontainer/config/bash_cfg/.bash_aliases "$HOME"

# setup powershell
pwsh -nop .devcontainer/config/setup_cfg.ps1

# setup python venv
./pysetup.sh venv
