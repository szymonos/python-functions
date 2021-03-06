#!/bin/bash
# *Setup Python environment in the project.
: '
bash .azure-pipelines/scripts/pysetup.sh venv     # *Setup python virtual environment
bash .azure-pipelines/scripts/pysetup.sh delvenv  # *Delete python virtual environment
bash .azure-pipelines/scripts/pysetup.sh reqs     # *Install requirements
bash .azure-pipelines/scripts/pysetup.sh upgrade  # *Upgrade all modules
bash .azure-pipelines/scripts/pysetup.sh sshkey   # *Generate key pairs for SSH
bash .azure-pipelines/scripts/pysetup.sh getenv   # *Get environment variables
bash .azure-pipelines/scripts/pysetup.sh list     # *List installed modules
veactivate                                        # *Activate virtual environment
deactivate                                        # *Deactivate virtual environment
'

# *Root directory of the application.
APP_DIR='app'

# constants
VENV_PATH=".venv"

# calculate script variables
activateScript="$VENV_PATH/bin/activate"
localSettings="$APP_DIR/local.settings.json"
[ -f $activateScript ] && venvCreated=true || venvCreated=false
req_files=("requirements.txt")
[ -n "$APP_DIR" ] && req_files=(${req_files[@]} "$APP_DIR/requirements.txt")

# *Setup python virtual environment.
if [ $1 = 'venv' ]; then
    if $venvCreated; then
        printf "\033[96mVirtual environment already set.\033[0m\n"
    else
        printf "\033[96mSet up Python environment.\033[0m\n"
        python -m venv $VENV_PATH
        source $activateScript
    fi
fi

# *Delete python virtual environment.
if [ $1 = 'delvenv' ]; then
    if $venvCreated; then
        printf "\033[96mDelete virtual environment.\033[0m\n"
        rm -fr $VENV_PATH
    else
        printf "\033[96mVirtual environment not exists.\033[0m\n"
    fi
fi

# *Upgrade pip, wheel and setuptools.
if [ $1 = 'venv' ] || [ $1 = 'reqs' ] || [ $1 = 'upgrade' ]; then
    printf "\033[95mupgrade pip, wheel and setuptools\033[0m\n"
    python -m pip install -U pip wheel setuptools
fi

# *Install requirements.
if [ $1 = 'venv' ] || [ $1 = 'reqs' ]; then
    printf "\033[95minstall project requirements\033[0m\n"
    declare -a reqs
    for val in ${req_files[@]}; do
        [ -f $val ] && reqs=(${reqs[@]} $(cat $val))
    done
    # save unique list of packages into temp reqs file
    reqs_temp='reqs_temp.txt'
    printf "%s\n" "${reqs[@]}" | sort -u >>$reqs_temp
    python -m pip install -U -r $reqs_temp
    rm -f $reqs_temp
    pypath add "$PWD/$APP_DIR" 2>/dev/null
    pypath add $PWD 2>/dev/null
fi

# *Upgrade all modules.
if [ $1 = 'upgrade' ]; then
    mods=($(python -m pip freeze | grep -v '^\-e' | cut -d = -f 1))
    # save list of packages into temp reqs file
    reqs_temp='reqs_temp.txt'
    printf "%s\n" "${mods[@]}" >>$reqs_temp
    python -m pip install -U -r $reqs_temp
    rm -f $reqs_temp
fi

# *Generate key pairs for SSH authentication in remote repository.
if [ $1 = 'sshkey' ]; then
    if ! [ -f '/root/.ssh/id_rsa.pub' ]; then
        # create new authentication key pairs for SSH if not exist
        ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''
    fi
    printf "\033[96mAdd below key to the repository's SSH keys:\033[0m\n"
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
