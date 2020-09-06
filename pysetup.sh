#!/bin/bash
# *Setup Python virtual environment in the project and much more...
# sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"  #* install ohmyzsh
# code ~/.zshrc  #* configure zsh
: 'EXAMPLE
zsh ./pysetup.sh venv           #* Setup python virtual environment
zsh ./pysetup.sh upgrade        #* Upgrade installed python modules
zsh ./pysetup.sh list           #* List installed modules
source app/.venv/bin/activate   #* Activate virtual environment
deactivate                      #* Deactivate virtual environment
'

# *Root directory of the application.
APP_DIR='app'

# calculate script variables
venvPath="$APP_DIR/.venv"
req_files=("requirements.txt" "app/requirements.txt")
if [ -d $venvPath ]; then
    venvCreated=true
else
    venvCreated=false
fi

# *Setup python virtual environment.
if [ $1 = 'venv' ]; then
    if [ $venvCreated ]; then
        echo "\e[94mVirtual environment already set.\e[0m"
    else
        python -m venv $venvPath
    fi
fi

# *Upgrade all modules..
if [ $1 = 'venv' ] || [ $1 = 'upgrade' ]; then
    echo "\e[95mupgrade pip\e[0m"
    python -m pip install --upgrade pip
    for val in $req_files[*]; do
        echo "\e[95minstall project requirements\e[0m"
        python -m pip install -U -r $val --use-feature=2020-resolver
    done
fi

# *List installed modules.
if [ $1 = 'list' ]; then
    mods=$(pip3 list --format=freeze | grep -v '^\-e' | cut -d = -f 1); echo $mods
    modsCnt=$(echo $mods | wc -l)
    pipPath=$(python -m pip -V | cut -d ' ' -f 4)
    ver=$(python -V)
    echo "\e[96m$ver \e[94m|\e[96m $modsCnt modules installed in \e[94m${pipPath/\/pip/}\e[0m"
fi
