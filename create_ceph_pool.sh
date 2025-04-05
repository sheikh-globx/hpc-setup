#!/bin/bash
# File: create_ceph_pools.sh

# Create pools for different storage needs
# Common log space pool (1.3TB)
ceph osd pool create log_pool 64
ceph osd pool set log_pool size 2  # Replication factor 2

# Compute node dedicated pools (2TB each)
ceph osd pool create compute01_pool 64
ceph osd pool create compute02_pool 64
ceph osd pool create compute03_pool 64
ceph osd pool set compute01_pool size 2
ceph osd pool set compute02_pool size 2
ceph osd pool set compute03_pool size 2

# Common storage pool for job outputs
ceph osd pool create common_pool 128
ceph osd pool set common_pool size 3  # Higher replication for important job outputs

# Initialize pools for RBD
for POOL in log_pool compute01_pool compute02_pool compute03_pool common_pool; do
  ceph osd pool application enable $POOL rbd
  rbd pool init $POOL
done

# Create RBD volumes
# Log RBD (1.3TB)
rbd create --size 1300G --pool log_pool --image log_volume

# Compute dedicated RBDs (2TB each)
rbd create --size 2048G --pool compute01_pool --image compute01_volume
rbd create --size 2048G --pool compute02_pool --image compute02_volume
rbd create --size 2048G --pool compute03_pool --image compute03_volume

# Common storage RBD (use remaining space, assume about 16TB total with replication)
REMAINING_GB=16384  # Approximate calculation
rbd create --size ${REMAINING_GB}G --pool common_pool --image common_volume

echo "Ceph pools and RBD volumes created"
