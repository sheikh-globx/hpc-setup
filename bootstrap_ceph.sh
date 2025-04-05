#!/bin/bash
# File: bootstrap_ceph.sh

# Generate an SSH key for the cephadm user if needed
if [ ! -f /home/cephadm/.ssh/id_rsa ]; then
  sudo -u cephadm ssh-keygen -t rsa -N "" -f /home/cephadm/.ssh/id_rsa
fi

# Bootstrap the Ceph cluster
cephadm bootstrap --mon-ip 10.10.140.40 \
  --initial-dashboard-user admin \
  --initial-dashboard-password adminpassword \
  --dashboard-password-noupdate \
  --allow-fqdn-hostname

# Wait for the bootstrap to complete
sleep 30

# Add all nodes to the cluster
for NODE in controller compute01 compute02 compute03; do
  ssh-copy-id -f -i /etc/ceph/ceph.pub root@$NODE
  ceph orch host add $NODE
done

# Set the admin key in all nodes
ADMIN_KEY=$(cat /etc/ceph/ceph.client.admin.keyring)

for NODE in compute01 compute02 compute03; do
  ssh root@$NODE "mkdir -p /etc/ceph"
  echo "$ADMIN_KEY" | ssh root@$NODE "cat > /etc/ceph/ceph.client.admin.keyring"
  scp /etc/ceph/ceph.conf root@$NODE:/etc/ceph/
done

echo "Ceph cluster bootstrap completed"
