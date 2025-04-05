#!/bin/bash
# File: test_slurm.sh

# Check Slurm controller status
systemctl status slurmctld

# Check compute node status
for NODE in compute01 compute02 compute03; do
  ssh root@$NODE "systemctl status slurmd"
done

# Check node status in Slurm
sinfo

# If nodes are down, bring them up
scontrol update nodename=compute01,compute02,compute03 state=resume

# Run a test job
su - hpcuser -c "sbatch -o /mnt/common_volume/test_job.out -N 3 --wrap='srun hostname'"

# Check job status
su - hpcuser -c "squeue"

# Check output (after job completes)
su - hpcuser -c "cat /mnt/common_volume/test_job.out"

echo "Slurm configuration testing completed"
