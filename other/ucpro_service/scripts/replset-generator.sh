#!/bin/bash

replset_key=$1
openssl rand -base64 723 > ${replset_key}
chmod 600 ${replset_key}
