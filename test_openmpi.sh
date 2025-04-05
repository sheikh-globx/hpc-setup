#!/bin/bash
# File: test_openmpi.sh

# Submit the MPI test job as hpcuser
su - hpcuser -c "cd /mnt/common_volume && sbatch /home/hpcuser/mpi_test.sh"

# Check job status
su - hpcuser -c "squeue"

# Wait for job to complete
echo "Waiting for MPI test job to complete..."
sleep 10

# Check the output
su - hpcuser -c "ls -la /mnt/common_volume/mpi_test_*.out"
su - hpcuser -c "cat /mnt/common_volume/mpi_test_*.out"

echo "OpenMPI with Slurm testing completed"
