#!/bin/bash
#* Setup Python virtual environment in the project.
: '
zsh ./pysetup.sh venv     #* Setup python virtual environment
zsh ./pysetup.sh upgrade  #* Upgrade installed python modules
zsh ./pysetup.sh sshkey   #* Generate key pairs for SSH
zsh ./pysetup.sh list     #* List installed modules
veactivate                #* Activate virtual environment
deactivate                #* Deactivate virtual environment
'

#* Root directory of the application.
APP_DIR='app'

# calculate script variables
venvPath="$APP_DIR/.venv"
activateScript="$venvPath/bin/activate"
req_files=("requirements.txt" "$APP_DIR/requirements.txt")
if [ -f $activateScript ]; then
    venvCreated=true
else
    venvCreated=false
fi

#* Setup python virtual environment.
if [ $1 = 'venv' ]; then
    echo "\e[95mupgrade existing modules\e[0m"
    if $venvCreated; then
        echo "\e[94mVirtual environment already set.\e[0m"
    else
        echo "\e[95mcreate virtual environment\e[0m"
        python -m venv $venvPath
        source $activateScript
    fi
fi

#* Upgrade all modules.
if [ $1 = 'venv' ] || [ $1 = 'upgrade' ]; then
    python -m pip install -U pip
    echo "\e[95minstall project requirements\e[0m"
    for val in $req_files[*]; do
        python -m pip install -U -r $val --use-feature=2020-resolver
    done
    pypath add "$PWD/$APP_DIR" 2>/dev/null
fi

#* Generate key pairs for SSH authentication in remote repository.
if [ $1 = 'sshkey' ]; then
    if ! [ -f '/root/.ssh/id_rsa.pub' ]; then
        # create new authentication key pairs for SSH if not exist
        ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''
    fi
    echo "\e[95mAdd below key to the repository's SSH keys:\e[0m"
    cat '/root/.ssh/id_rsa.pub'
fi

#* List installed modules.
if [ $1 = 'list' ]; then
    mods=$(python -m pip list | grep -v '^\-e' | cut -d = -f 1); echo $mods
    modsCnt=$(expr $(echo $mods | wc -l) - 2)
    pipPath=$(python -m pip -V | cut -d ' ' -f 4)
    echo "\n\e[96m$(python -V) \e[94m|\e[96m $modsCnt modules installed in \e[94m${pipPath/pip/}\e[0m\n"
fi
