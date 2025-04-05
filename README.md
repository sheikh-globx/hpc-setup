# HPC Cluster Setup README

This document provides a step-by-step guide for setting up the HPC cluster with Rocky Linux 9, Slurm 24.x, Ceph 19.x, and OpenMPI according to the detailed configuration document.

## Prerequisites

- Rocky Linux 9.5 is already installed on all nodes
- The following users already exist: `root` and `rocky`
- Network connectivity is established between all nodes
- All nodes have the following IPs configured:
  - Controller Node: 10.10.140.40
  - Compute Node 1: 10.10.140.41
  - Compute Node 2: 10.10.140.42
  - Compute Node 3: 10.10.140.43

## Installation Process

Follow these steps in order. All scripts should be run from the controller node (10.10.140.40) as the root user.

### 1. Initial System Configuration

1. **Set up hostnames and configure /etc/hosts**
   ```bash
   bash setup_hosts.sh
   ```
   This configures the hostname and /etc/hosts file on all nodes, disables firewalld, and disables SELinux.

2. **Configure SSH passwordless access**
   ```bash
   bash setup_ssh.sh
   ```
   This sets up passwordless SSH access between all nodes for the root and rocky users.

3. **Create required users**
   ```bash
   bash create_users.sh
   ```
   This creates the cephadm, slurm, munge, hpcadmin, and hpcuser accounts on all nodes.

4. **Install base packages**
   ```bash
   bash install_base_packages.sh
   ```
   This installs all the necessary base packages on all nodes.

### 2. Ceph Installation and Configuration

5. **Install Ceph repository and tools**
   ```bash
   bash install_ceph.sh
   ```
   This adds the Ceph 19.x repositories and installs the necessary Ceph packages on all nodes.

6. **Bootstrap Ceph cluster and add nodes**
   ```bash
   bash bootstrap_ceph.sh
   ```
   This bootstraps the Ceph cluster on the controller node and adds all other nodes to the cluster.

7. **Configure OSDs for storage**
   ```bash
   bash configure_ceph_osds.sh
   ```
   This configures the storage drives as Ceph OSDs on all nodes.

8. **Create Ceph pools and RBD volumes**
   ```bash
   bash create_ceph_pools.sh
   ```
   This creates the necessary Ceph pools for logs, dedicated compute storage, and common storage.

9. **Configure RBD client and mount points**
   ```bash
   bash configure_rbd_mounts.sh
   ```
   This configures RBD mapping and mounting on all nodes.

10. **Set filesystem permissions**
    ```bash
    bash set_fs_permissions.sh
    ```
    This sets appropriate permissions on all mounted filesystems.

### 3. Slurm Installation and Configuration

11. **Install MUNGE authentication service**
    ```bash
    bash install_munge.sh
    ```
    This installs and configures the MUNGE authentication service required by Slurm.

12. **Install Slurm 24.x**
    ```bash
    bash install_slurm.sh
    ```
    This installs and configures Slurm on all nodes.

13. **Install and configure Slurm Web**
    ```bash
    bash install_slurm_web.sh
    ```
    This installs the web interface for Slurm.

### 4. OpenMPI Installation and Configuration

14. **Install OpenMPI**
    ```bash
    bash install_openmpi.sh
    ```
    This installs OpenMPI on all nodes.

15. **Configure OpenMPI integration with Slurm**
    ```bash
    bash configure_openmpi_slurm.sh
    ```
    This configures OpenMPI to work with Slurm and creates a test MPI job script.

### 5. Monitoring Tools Setup

16. **Install Prometheus and Node Exporter**
    ```bash
    bash install_prometheus.sh
    ```
    This installs Prometheus on the controller node and Node Exporter on all nodes.

17. **Install Grafana**
    ```bash
    bash install_grafana.sh
    ```
    This installs Grafana on the controller node for visualization.

### 6. Testing and Verification

18. **Test Slurm configuration**
    ```bash
    bash test_slurm.sh
    ```
    This verifies that Slurm is functioning correctly.

19. **Test Ceph RBD mounts**
    ```bash
    bash test_ceph_mounts.sh
    ```
    This verifies that all Ceph RBD volumes are properly mounted and accessible.

20. **Test OpenMPI with Slurm**
    ```bash
    bash test_openmpi.sh
    ```
    This tests OpenMPI integration with Slurm by running a sample MPI job.

## Accessing the Services

After installation, you can access the services at:

- **Slurm Web Interface**: http://controller/
- **Grafana Dashboard**: http://controller:3000/ (default login: admin/admin)
- **Ceph Dashboard**: https://controller:8443/ (credentials set during bootstrap)

## Verification

After completing all steps, verify your configuration:

1. Check the status of all services:
   ```bash
   systemctl status slurmctld munge prometheus grafana-server
   ```

2. Verify Slurm nodes are up:
   ```bash
   sinfo
   ```

3. Verify Ceph health:
   ```bash
   ceph -s
   ```

4. Verify all RBD mounts are accessible:
   ```bash
   df -h | grep "/mnt"
   ```

5. Submit a test job to Slurm:
   ```bash
   sudo -u hpcuser sbatch -o /mnt/common_volume/test_job.out -N 3 --wrap='srun hostname'
   ```

## Troubleshooting

- **Slurm Issues**: Check logs at `/var/log/slurm/`
- **Ceph Issues**: Use `ceph status`, `ceph health detail`, and check logs at `/var/log/ceph/`
- **Mount Issues**: Verify using `mount`, `dmesg`, and `rbd status`
- **Network Issues**: Check using `ping`, `traceroute`, and `iptables -L`

If you need to restart services after configuration changes:
```bash
systemctl restart slurmctld  # On controller
systemctl restart slurmd     # On compute nodes
```
