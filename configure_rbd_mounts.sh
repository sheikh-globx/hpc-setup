#!/bin/bash
# File: configure_rbd_mounts.sh

# Retrieve admin key for mounting
ADMIN_KEY=$(ceph auth get-key client.admin)

# Create directories for mount points on all nodes
for NODE in controller compute01 compute02 compute03; do
  ssh root@$NODE "mkdir -p /mnt/log_volume /mnt/common_volume"
done

# Create dedicated mount points on compute nodes
ssh root@compute01 "mkdir -p /mnt/compute01_volume"
ssh root@compute02 "mkdir -p /mnt/compute02_volume"
ssh root@compute03 "mkdir -p /mnt/compute03_volume"

# Install required packages on all nodes
for NODE in controller compute01 compute02 compute03; do
  ssh root@$NODE "dnf install -y ceph-common"
done

# Create RBD mapping script on all nodes
for NODE in controller compute01 compute02 compute03; do
  cat > map_rbd.sh << EOF
#!/bin/bash

# Map log volume
echo "$ADMIN_KEY" | sudo tee /etc/ceph/admin.key
sudo chmod 600 /etc/ceph/admin.key

# Map and mount log volume
sudo rbd map log_pool/log_volume --name client.admin --keyring /etc/ceph/admin.key
sudo mkfs.xfs /dev/rbd0 || true
sudo mount /dev/rbd0 /mnt/log_volume

# Map and mount common volume
sudo rbd map common_pool/common_volume --name client.admin --keyring /etc/ceph/admin.key
sudo mkfs.xfs /dev/rbd1 || true
sudo mount /dev/rbd1 /mnt/common_volume

# Add to fstab for persistence
grep -q "/mnt/log_volume" /etc/fstab || echo "/dev/rbd0 /mnt/log_volume xfs noauto,_netdev 0 0" | sudo tee -a /etc/fstab
grep -q "/mnt/common_volume" /etc/fstab || echo "/dev/rbd1 /mnt/common_volume xfs noauto,_netdev 0 0" | sudo tee -a /etc/fstab

# Create a systemd service for automatic mapping and mounting
cat > /etc/systemd/system/rbd-mount.service << 'EOL'
[Unit]
Description=RBD mounts
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash /root/map_rbd.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL

# Enable the service
systemctl daemon-reload
systemctl enable rbd-mount.service
systemctl start rbd-mount.service
EOF

  scp map_rbd.sh root@$NODE:/root/
  ssh root@$NODE "chmod +x /root/map_rbd.sh && /root/map_rbd.sh"
done

# Create dedicated volume mount script for compute nodes
for NODE in compute01 compute02 compute03; do
  NODE_NUM=${NODE#compute}
  
  cat > map_dedicated_rbd.sh << EOF
#!/bin/bash

# Map and mount dedicated volume
sudo rbd map compute${NODE_NUM}_pool/compute${NODE_NUM}_volume --name client.admin --keyring /etc/ceph/admin.key
sudo mkfs.xfs /dev/rbd2 || true
sudo mount /dev/rbd2 /mnt/compute${NODE_NUM}_volume

# Add to fstab for persistence
grep -q "/mnt/compute${NODE_NUM}_volume" /etc/fstab || echo "/dev/rbd2 /mnt/compute${NODE_NUM}_volume xfs noauto,_netdev 0 0" | sudo tee -a /etc/fstab

# Update the rbd-mount service to include the dedicated volume
sed -i "/ExecStart=/c\ExecStart=/bin/bash /root/map_rbd.sh && /bin/bash /root/map_dedicated_rbd.sh" /etc/systemd/system/rbd-mount.service

# Reload and restart the service
systemctl daemon-reload
systemctl restart rbd-mount.service
EOF

  scp map_dedicated_rbd.sh root@$NODE:/root/
  ssh root@$NODE "chmod +x /root/map_dedicated_rbd.sh && /root/map_dedicated_rbd.sh"
done

echo "RBD volumes mapped and mounted on all nodes"
