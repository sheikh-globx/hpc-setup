#!/bin/bash
# File: create_users.sh

# Define user list with details
declare -A USERS=(
  ["cephadm"]="Ceph Administrator:5001:/bin/bash"
  ["slurm"]="Slurm Workload Manager:5002:/bin/bash"
  ["munge"]="MUNGE Authentication:5003:/sbin/nologin"
  ["hpcadmin"]="HPC Administrator:5004:/bin/bash"
  ["hpcuser"]="HPC Regular User:5005:/bin/bash"
)

# Create users on controller
for USER in "${!USERS[@]}"; do
  IFS=':' read -r COMMENT UID SHELL <<< "${USERS[$USER]}"
  
  # Create user
  useradd -u $UID -m -c "$COMMENT" -s $SHELL $USER
  
  # Set password (you should change this in production)
  echo "${USER}:${USER}123" | chpasswd
  
  # Generate SSH key if user has a login shell
  if [[ "$SHELL" == "/bin/bash" ]]; then
    sudo -u $USER ssh-keygen -t rsa -N "" -f /home/$USER/.ssh/id_rsa
  fi
done

# Create a script to add users on compute nodes
cat > add_users.sh << 'EOF'
#!/bin/bash

# Create users
useradd -u 5001 -m -c "Ceph Administrator" -s /bin/bash cephadm
useradd -u 5002 -m -c "Slurm Workload Manager" -s /bin/bash slurm
useradd -u 5003 -m -c "MUNGE Authentication" -s /sbin/nologin munge
useradd -u 5004 -m -c "HPC Administrator" -s /bin/bash hpcadmin
useradd -u 5005 -m -c "HPC Regular User" -s /bin/bash hpcuser

# Set passwords
echo "cephadm:cephadm123" | chpasswd
echo "slurm:slurm123" | chpasswd
echo "hpcadmin:hpcadmin123" | chpasswd
echo "hpcuser:hpcuser123" | chpasswd

# Create .ssh directories
for USER in cephadm slurm hpcadmin hpcuser; do
  mkdir -p /home/$USER/.ssh
  chmod 700 /home/$USER/.ssh
  chown $USER:$USER /home/$USER/.ssh
done
EOF

# Make the script executable
chmod +x add_users.sh

# Copy and execute the script on compute nodes
for NODE_IP in 10.10.140.41 10.10.140.42 10.10.140.43; do
  scp add_users.sh root@$NODE_IP:/tmp/
  ssh root@$NODE_IP "bash /tmp/add_users.sh"
done

# Configure SSH keys for all users on all nodes
for USER in cephadm slurm hpcadmin hpcuser; do
  # Skip if user has no login shell
  if [[ "${USERS[$USER]}" == *"/sbin/nologin"* ]]; then
    continue
  fi
  
  # Get the public key
  PUBLIC_KEY=$(cat /home/$USER/.ssh/id_rsa.pub)
  
  # Copy the public key to all compute nodes
  for NODE_IP in 10.10.140.41 10.10.140.42 10.10.140.43; do
    ssh root@$NODE_IP "echo '$PUBLIC_KEY' > /home/$USER/.ssh/authorized_keys && chmod 600 /home/$USER/.ssh/authorized_keys && chown $USER:$USER /home/$USER/.ssh/authorized_keys"
  done
done

# Clean up
rm add_users.sh

echo "User setup completed on all nodes"
