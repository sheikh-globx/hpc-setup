#!/bin/bash
# File: test_ceph_mounts.sh

# Check mount points on all nodes
for NODE in controller compute01 compute02 compute03; do
  echo "Checking mounts on $NODE"
  ssh root@$NODE "df -h | grep -E '/mnt/(log|common|compute)'"
  
  # Test write access
  ssh root@$NODE "echo 'Test file from $NODE' > /mnt/log_volume/test_${NODE}.txt"
  ssh root@$NODE "echo 'Test file from $NODE' > /mnt/common_volume/test_${NODE}.txt"
  
  # For compute nodes, test dedicated volumes
  if [[ $NODE =~ compute ]]; then
    NODE_NUM=${NODE#compute}
    ssh root@$NODE "echo 'Test file from $NODE' > /mnt/compute${NODE_NUM}_volume/test_${NODE}.txt"
  fi
done

# Verify files are accessible from all nodes
for NODE in controller compute01 compute02 compute03; do
  echo "Verifying files on $NODE"
  ssh root@$NODE "ls -la /mnt/log_volume/test_*.txt"
  ssh root@$NODE "ls -la /mnt/common_volume/test_*.txt"
done

echo "Ceph RBD mount testing completed"
