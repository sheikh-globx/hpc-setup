#!/bin/bash
# File: setup_ssh.sh

# Generate SSH key for root if it doesn't exist
if [ ! -f /root/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
fi

# Generate SSH key for rocky if it doesn't exist
if [ ! -f /home/rocky/.ssh/id_rsa ]; then
  sudo -u rocky ssh-keygen -t rsa -N "" -f /home/rocky/.ssh/id_rsa
fi

# Copy root SSH key to all nodes
for IP in 10.10.140.41 10.10.140.42 10.10.140.43; do
  sshpass -p "your_root_password" ssh-copy-id -o StrictHostKeyChecking=no root@$IP
done

# Copy rocky SSH key to all nodes
for IP in 10.10.140.41 10.10.140.42 10.10.140.43; do
  sudo -u rocky sshpass -p "your_rocky_password" ssh-copy-id -o StrictHostKeyChecking=no rocky@$IP
done

echo "SSH passwordless access configured for root and rocky users"
