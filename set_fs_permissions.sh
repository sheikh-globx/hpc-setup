#!/bin/bash
# File: set_fs_permissions.sh

# Set permissions for log volume on all nodes
for NODE in controller compute01 compute02 compute03; do
  ssh root@$NODE "chown -R cephadm:cephadm /mnt/log_volume"
  ssh root@$NODE "chmod 775 /mnt/log_volume"
done

# Set permissions for common volume on all nodes
for NODE in controller compute01 compute02 compute03; do
  ssh root@$NODE "chown -R hpcuser:hpcuser /mnt/common_volume"
  ssh root@$NODE "chmod 775 /mnt/common_volume"
done

# Set permissions for dedicated volumes on compute nodes
ssh root@compute01 "chown -R hpcuser:hpcuser /mnt/compute01_volume && chmod 700 /mnt/compute01_volume"
ssh root@compute02 "chown -R hpcuser:hpcuser /mnt/compute02_volume && chmod 700 /mnt/compute02_volume"
ssh root@compute03 "chown -R hpcuser:hpcuser /mnt/compute03_volume && chmod 700 /mnt/compute03_volume"

echo "Filesystem permissions set on all volumes"
