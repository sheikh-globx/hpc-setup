#!/bin/bash
# File: install_ceph.sh

# Install Ceph repository on controller
cat > /etc/yum.repos.d/ceph.repo << 'EOF'
[ceph]
name=Ceph packages
baseurl=https://download.ceph.com/rpm-19.0.0/el9/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-19.0.0/el9/noarch/
enabled=1
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF

# Install cephadm
dnf install -y cephadm

# Create a script for compute nodes
cat > install_ceph_repo.sh << 'EOF'
#!/bin/bash

# Add Ceph repository
cat > /etc/yum.repos.d/ceph.repo << 'EOL'
[ceph]
name=Ceph packages
baseurl=https://download.ceph.com/rpm-19.0.0/el9/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-19.0.0/el9/noarch/
enabled=1
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOL

# Install ceph packages
dnf install -y ceph ceph-common
EOF

# Make the script executable
chmod +x install_ceph_repo.sh

# Copy and execute the script on compute nodes
for NODE_IP in 10.10.140.41 10.10.140.42 10.10.140.43; do
  scp install_ceph_repo.sh root@$NODE_IP:/tmp/
  ssh root@$NODE_IP "bash /tmp/install_ceph_repo.sh"
done

# Clean up
rm install_ceph_repo.sh

echo "Ceph repositories added to all nodes"
