#!/bin/bash
self=$(dirname "$0")
if [[ $self == "." ]]; then
    base=".."
else
    base=$(dirname ${self})
fi

if [[ ! -d ${base}/data ]]; then
    mkdir ${base}/data
fi

ssh-keygen -t rsa -N "" -f ${base}/data/id_rsa -C "easyuc from easyops"
