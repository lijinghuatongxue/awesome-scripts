#!/bin/bash

ps -fC mysqld |grep "mysql/bin/mysqld"

if [[ $? -ne 0 ]]; then
    exit 1
fi

exit 0