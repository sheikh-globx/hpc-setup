#!/bin/bash
# File: configure_ceph_osds.sh

# Get the list of available devices on each node
# In a real-world scenario, you'd identify the correct devices

# Deploy OSDs on controller node (assuming /dev/sdb and /dev/sdc are the 8TB drives)
ceph orch daemon add osd controller:/dev/sdb
ceph orch daemon add osd controller:/dev/sdc

# Deploy OSDs on compute nodes
for NODE in compute01 compute02 compute03; do
  ceph orch daemon add osd $NODE:/dev/sdb
  ceph orch daemon add osd $NODE:/dev/sdc
done

# Wait for OSDs to be deployed
sleep 60

# Check OSD status
ceph osd status
ceph -s

echo "Ceph OSDs configured on all nodes"
