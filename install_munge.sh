#!/bin/bash
# File: install_munge.sh

# Install MUNGE on the controller
dnf install -y munge munge-libs munge-devel

# Create MUNGE key
/usr/sbin/create-munge-key -r

# Set permissions
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key

# Start and enable MUNGE service
systemctl enable munge
systemctl start munge

# Copy MUNGE key to compute nodes
for NODE in compute01 compute02 compute03; do
  scp /etc/munge/munge.key root@$NODE:/etc/munge/
  ssh root@$NODE "dnf install -y munge munge-libs munge-devel && \
    chown munge:munge /etc/munge/munge.key && \
    chmod 400 /etc/munge/munge.key && \
    systemctl enable munge && \
    systemctl start munge"
done

# Test MUNGE authentication
for NODE in compute01 compute02 compute03; do
  munge -n | ssh $NODE unmunge
  if [ $? -eq 0 ]; then
    echo "MUNGE authentication working with $NODE"
  else
    echo "MUNGE authentication failed with $NODE"
    exit 1
  fi
done

echo "MUNGE authentication service installed and configured on all nodes"
