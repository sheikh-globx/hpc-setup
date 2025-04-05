#!/bin/bash
# File: install_base_packages.sh

# Update the controller node
dnf update -y
dnf install -y epel-release
dnf install -y wget git vim chrony net-tools bind-utils sshpass \
    yum-utils device-mapper-persistent-data lvm2 parted \
    nfs-utils python3 python3-pip gcc gcc-c++ make \
    openssl openssl-devel pam-devel numactl \
    numactl-devel hwloc hwloc-devel lua lua-devel \
    readline-devel rrdtool-devel ncurses-devel \
    man man-pages mlocate rsync

# Start and enable chronyd
systemctl start chronyd
systemctl enable chronyd

# Create a script for compute nodes
cat > install_compute_packages.sh << 'EOF'
#!/bin/bash

# Update system
dnf update -y
dnf install -y epel-release
dnf install -y wget git vim chrony net-tools bind-utils \
    yum-utils device-mapper-persistent-data lvm2 parted \
    nfs-utils python3 python3-pip gcc gcc-c++ make \
    openssl openssl-devel pam-devel numactl \
    numactl-devel hwloc hwloc-devel lua lua-devel \
    readline-devel rrdtool-devel ncurses-devel \
    man man-pages mlocate rsync

# Start and enable chronyd
systemctl start chronyd
systemctl enable chronyd
EOF

# Make the script executable
chmod +x install_compute_packages.sh

# Copy and execute the script on compute nodes
for NODE_IP in 10.10.140.41 10.10.140.42 10.10.140.43; do
  scp install_compute_packages.sh root@$NODE_IP:/tmp/
  ssh root@$NODE_IP "bash /tmp/install_compute_packages.sh"
done

# Clean up
rm install_compute_packages.sh

echo "Base packages installed on all nodes"
