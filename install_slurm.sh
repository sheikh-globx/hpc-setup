#!/bin/bash
# File: install_slurm.sh

# Set Slurm version
SLURM_VERSION="24.05.0"

# Download and extract Slurm on the controller
cd /tmp
wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
tar xvjf slurm-${SLURM_VERSION}.tar.bz2
cd slurm-${SLURM_VERSION}

# Install build dependencies
dnf install -y rpm-build
dnf groupinstall -y "Development Tools"
dnf install -y mariadb-devel mariadb-server pam-devel \
    numactl numactl-devel hwloc hwloc-devel lua lua-devel \
    readline-devel rrdtool-devel ncurses-devel man2html \
    libibmad libibumad perl-ExtUtils-MakeMaker

# Build RPMs
./configure --prefix=/usr --sysconfdir=/etc/slurm --enable-pam \
    --with-pam_dir=/lib64/security/ --without-shared-libslurm
make -j $(nproc)
make install

# Create necessary directories
mkdir -p /etc/slurm
mkdir -p /var/spool/slurm/{ctld,d}
mkdir -p /var/log/slurm

# Set ownership
chown -R slurm:slurm /var/spool/slurm/
chown -R slurm:slurm /var/log/slurm/

# Create slurm.conf
cat > /etc/slurm/slurm.conf << 'EOF'
# slurm.conf
ClusterName=hpc-cluster
ControlMachine=controller
ControlAddr=10.10.140.40
AuthType=auth/munge
CryptoType=crypto/munge
SlurmUser=slurm
SlurmdUser=root
SlurmctldPort=6817
SlurmdPort=6818
StateSaveLocation=/var/spool/slurm/ctld
SlurmdSpoolDir=/var/spool/slurm/d
SwitchType=switch/none
MpiDefault=none
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmdPidFile=/var/run/slurmd.pid
ProctrackType=proctrack/linuxproc
ReturnToService=1
SlurmctldTimeout=300
SlurmdTimeout=300
InactiveLimit=0
MinJobAge=300
KillWait=30
Waittime=0
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core
AccountingStorageType=accounting_storage/none

# Node configurations
NodeName=compute[01-03] CPUs=96 RealMemory=256000 State=UNKNOWN
# Actual CPU count would be 2 processors × 48 cores each = 96 total cores

# Partition configuration
PartitionName=normal Default=YES Nodes=compute[01-03] MaxTime=INFINITE State=UP
EOF

# Create cgroup.conf
cat > /etc/slurm/cgroup.conf << 'EOF'
CgroupMountpoint="/sys/fs/cgroup"
CgroupAutomount=yes
CgroupReleaseAgentDir="/etc/slurm/cgroup"
AllowedDevicesFile="/etc/slurm/cgroup_allowed_devices_file.conf"
ConstrainCores=yes
ConstrainRAMSpace=yes
ConstrainSwapSpace=yes
ConstrainDevices=yes
EOF

# Create slurmd systemd service file
cat > /etc/systemd/system/slurmd.service << 'EOF'
[Unit]
Description=Slurm node daemon
After=network.target munge.service
ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/slurmd
ExecStart=/usr/sbin/slurmd $SLURMD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/slurmd.pid
KillMode=process
LimitNOFILE=131072
LimitMEMLOCK=infinity
LimitSTACK=infinity
Delegate=yes

[Install]
WantedBy=multi-user.target
EOF

# Create slurmctld systemd service file
cat > /etc/systemd/system/slurmctld.service << 'EOF'
[Unit]
Description=Slurm controller daemon
After=network.target munge.service
ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/slurmctld
ExecStart=/usr/sbin/slurmctld $SLURMCTLD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/slurmctld.pid
KillMode=process
LimitNOFILE=131072
LimitMEMLOCK=infinity
LimitSTACK=infinity

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Install Slurm on compute nodes
for NODE in compute01 compute02 compute03; do
  # Copy the built binaries and configuration
  ssh root@$NODE "mkdir -p /etc/slurm /var/spool/slurm/d /var/log/slurm"
  scp /usr/sbin/slurmd root@$NODE:/usr/sbin/
  scp /usr/bin/srun root@$NODE:/usr/bin/
  scp /usr/bin/sbatch root@$NODE:/usr/bin/
  scp /usr/bin/sinfo root@$NODE:/usr/bin/
  scp /usr/bin/squeue root@$NODE:/usr/bin/
  scp /usr/lib64/libslurm* root@$NODE:/usr/lib64/
  scp /etc/slurm/slurm.conf root@$NODE:/etc/slurm/
  scp /etc/slurm/cgroup.conf root@$NODE:/etc/slurm/
  scp /etc/systemd/system/slurmd.service root@$NODE:/etc/systemd/system/

  # Set permissions
  ssh root@$NODE "chown -R slurm:slurm /var/spool/slurm/d /var/log/slurm"
  
  # Enable and start slurmd
  ssh root@$NODE "systemctl daemon-reload && systemctl enable slurmd && systemctl start slurmd"
done

# Start Slurm controller on the controller node
systemctl enable slurmctld
systemctl start slurmctld

echo "Slurm installed and configured on all nodes"
