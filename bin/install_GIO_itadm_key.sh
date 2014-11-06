#!/bin/bash

usage_func() {
    echo 
    echo "Usage: "`basename $0`" [Environment (preprod|prod)] [region] echo_only"
    echo 
    echo "example: " `basename $0` "preprod us-east-1"
    echo 
    exit 1
}

environment=$1
region=$2
echo_only=$3

if [ "$environment" = "" -o "$region" = "" ]; then
    usage_func
fi

. ~/bin/setenv.sh $environment

echo "Generating Inventory..."
~/aws-ansible/bin/ec2.py --list > ~/aws-ansible/inventory/$environment/hosts.gen
echo "Generating group_vars files..."
~/aws-ansible/bin/createGroupVars.pl $environment $region
rm -f ~/aws-ansible/inventory/$environment/hosts.gen

if [ "$region" = "us-east-1" ]; then
    limit='--limit 10.241.*'
fi

while read key_name
do
  if [ "$echo_only" = "Y" -o "$echo_only" = "y" ]; then
    echo ansible-playbook -i ~/aws-ansible/inventory/$environment/hosts $limit --extra-vars \"region=$region key_name=$key_name\" ~/aws-ansible/playbooks/install_GIO_itasm_key.yml
  else
    ansible-playbook -i ~/aws-ansible/inventory/$environment/hosts $limit --extra-vars "region=$region key_name=$key_name" ~/aws-ansible/playbooks/install_GIO_itasm_key.yml
  fi
done < ~/aws-ansible/bin/$region'_keys.dat'
