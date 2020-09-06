#!/bin/bash

# *Activate virtual environment.
if [ $1 = "activate" ]; then
    echo "execute: source app/.venv/bin/activate"
    source app/.venv/bin/activate
fi

# *Deactivate virtual environment.
if [ $1 = "deactivate" ]; then
    echo "execute: deactivate"
    deactivate
fi

: '
zsh ./test.sh activate
zsh ./test.sh deactivate
./test.sh activate
sh ./test.sh deactivate
sh ./test.sh deactivate
'
