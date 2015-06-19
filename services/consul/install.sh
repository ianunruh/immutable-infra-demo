#!/bin/bash
set -eux

sudo add-apt-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible

sudo mv /tmp/ansible /ansible

echo "localhost ansible_connection=local" | sudo tee /etc/ansible/hosts

sudo ansible-playbook /ansible/playbook.yml --tags install
