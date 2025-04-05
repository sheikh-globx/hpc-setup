#!/bin/bash
# File: setup_hosts.sh

# Define the cluster nodes
CONTROLLER="controller"
COMPUTE01="compute01"
COMPUTE02="compute02"
COMPUTE03="compute03"

CONTROLLER_IP="10.10.140.40"
COMPUTE01_IP="10.10.140.41"
COMPUTE02_IP="10.10.140.42"
COMPUTE03_IP="10.10.140.43"

# Set hostname on controller
hostnamectl set-hostname $CONTROLLER

# Create hosts file content
HOSTS_CONTENT="127.0.0.1   localhost
$CONTROLLER_IP $CONTROLLER
$COMPUTE01_IP $COMPUTE01
$COMPUTE02_IP $COMPUTE02
$COMPUTE03_IP $COMPUTE03"

# Update hosts file on controller
echo "$HOSTS_CONTENT" > /etc/hosts

# Create a script to update compute nodes
cat > update_compute.sh << 'EOF'
#!/bin/bash
# Set hostname
hostnamectl set-hostname $1

# Update hosts file
cat > /etc/hosts << 'EOL'
127.0.0.1   localhost
10.10.140.40 controller
10.10.140.41 compute01
10.10.140.42 compute02
10.10.140.43 compute03
EOL

# Disable firewalld (or configure it appropriately)
systemctl disable firewalld
systemctl stop firewalld

# Disable SELinux for simplicity (you may want to configure it properly in production)
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
EOF

# Make the script executable
chmod +x update_compute.sh

# Copy and execute the script on compute nodes
for NODE in $COMPUTE01 $COMPUTE02 $COMPUTE03; do
  NODE_IP=${NODE}_IP
  scp update_compute.sh rocky@${!NODE_IP}:/tmp/
  ssh rocky@${!NODE_IP} "sudo bash /tmp/update_compute.sh $NODE"
done

# Clean up
rm update_compute.sh

# Disable firewalld on controller (or configure it appropriately)
systemctl disable firewalld
systemctl stop firewalld

# Disable SELinux for simplicity
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

echo "Host configuration completed on all nodes"
