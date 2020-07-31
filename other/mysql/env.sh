#!/usr/bin/env bash
_easyadmin_wd=$(pwd -L)

if [ -f /etc/profile ];then
    source /etc/profile
fi

if [ -f ~/.bash_profile ];then
    source ~/.bash_profile
elif [ -f ~/.bash_login ];then
    source ~/.bash_login
elif [ -f ~/.profile ];then
    source ~/.profile
fi

if [[ $(pwd -L) != "$_easyadmin_wd" ]]; then
    cd "$_easyadmin_wd"
fi
