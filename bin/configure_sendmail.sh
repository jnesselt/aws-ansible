#!/bin/bash

usage_func() {
    echo 
    echo "Usage: "`basename $0`" [Environment (preprod|prod)] [target] echo_only refresh_cache"
    echo 
    echo "example: " `basename $0` "preprod tag_Name_SES-Test"
    echo 
    exit 1
}

environment=$1
target=$2
echo_only=$3
refresh_cache=$4

if [ "$environment" = "" -o "$target" = "" ]; then
    usage_func
fi

. ~/bin/setenv.sh $environment

ansible-playbook -i ~/aws-ansible/inventory/$environment/hosts --extra-vars "target=$target" ~/aws-ansible/playbooks/configure-sendmail.yml -v
