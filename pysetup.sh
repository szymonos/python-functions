#!/bin/bash
# *Setup Python environment in the project.
: '
bash ./pysetup.sh venv     # *Setup python virtual environment
bash ./pysetup.sh upgrade  # *Install requirements and upgrade modules
bash ./pysetup.sh sshkey   # *Generate key pairs for SSH
bash ./pysetup.sh getenv   # *Get environment variables
bash ./pysetup.sh list     # *List installed modules
veactivate                 # *Activate virtual environment
deactivate                 # *Deactivate virtual environment
'

# *Root directory of the application.
APP_DIR='app'

# calculate script variables
venvPath="$APP_DIR/.venv"
activateScript="$venvPath/bin/activate"
localSettings="$APP_DIR/local.settings.json"
[ -f $activateScript ] && venvCreated=true || venvCreated=false
req_files=("requirements.txt")
[ -n "$APP_DIR" ] && req_files=(${req_files[@]} "$APP_DIR/requirements.txt")

# *Setup python virtual environment.
if [ $1 = 'venv' ]; then
    printf "\033[95mupgrade existing modules\033[0m\n"
    if $venvCreated; then
        printf "\033[94mVirtual environment already set.\033[0m\n"
    else
        printf "\033[95mcreate virtual environment\033[0m\n"
        python -m venv $venvPath
        source $activateScript
    fi
fi

# *Upgrade all modules.
if [ $1 = 'venv' ] || [ $1 = 'upgrade' ]; then
    python -m pip install -U pip
    printf "\033[95minstall project requirements\033[0m\n"
    mods=($(python -m pip freeze | grep -v '^\-e' | cut -d = -f 1))
    declare -a reqs
    for val in ${req_files[@]}; do
        [ -f $val ] && reqs=(${reqs[@]} $(cat $val))
    done
    # combine requirements packages with all packages
    mods=(${mods[@]} ${reqs[@]})
    # save unique list of packages into temp reqs file
    reqs_temp='reqs_temp.txt'
    printf "%s\n" "${mods[@]}" | sort -u >>$reqs_temp
    python -m pip install -U -r $reqs_temp --use-feature=2020-resolver
    rm -f $reqs_temp
    pypath add "$PWD/$APP_DIR" 2>/dev/null
fi

# *Generate key pairs for SSH authentication in remote repository.
if [ $1 = 'sshkey' ]; then
    if ! [ -f '/root/.ssh/id_rsa.pub' ]; then
        # create new authentication key pairs for SSH if not exist
        ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''
    fi
    printf "\033[95mAdd below key to the repository's SSH keys:\033[0m\n"
    cat '/root/.ssh/id_rsa.pub'
fi

# *Get environment variables.
if [ $1 = 'getenv' ]; then
    keys=$(jq '.Values | keys | @sh' $localSettings | sed 's/"//g' | sed "s/'//g" | sed 's/ /|/g')
    printenv | grep -E $keys | sort
fi

# *List installed modules.
if [ $1 = 'list' ]; then
    python -m pip list
    modsCnt=$(python -m pip freeze | wc -l)
    pipPath=$(python -m pip -V | cut -d ' ' -f 4)
    printf "\n\033[96m$(python -V) \033[94m|\033[96m $modsCnt modules installed in \033[94m${pipPath/pip/}\033[0m\n\n"
fi
