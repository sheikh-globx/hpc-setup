#!/bin/bash
# File: configure_openmpi_slurm.sh

# Update Slurm configuration to work with OpenMPI
cat >> /etc/slurm/slurm.conf << 'EOF'

# MPI Configuration
MpiDefault=pmi2
EOF

# Create example MPI job script
cat > /home/hpcuser/mpi_test.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=mpi_test
#SBATCH --output=mpi_test_%j.out
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --time=00:05:00

# Load OpenMPI module
module load mpi/openmpi-4.1.5

# Run MPI job
srun --mpi=pmi2 hostname

# MPI Hello World example
cat > hello_world.c << 'EOL'
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);

    printf("Hello world from processor %s, rank %d out of %d processors\n",
           processor_name, world_rank, world_size);

    MPI_Finalize();
    return 0;
}
EOL

# Compile MPI program
mpicc -o hello_world hello_world.c

# Run MPI program
srun --mpi=pmi2 ./hello_world

# Cleanup
rm hello_world.c
EOF

# Set proper ownership and permissions
chown hpcuser:hpcuser /home/hpcuser/mpi_test.sh
chmod +x /home/hpcuser/mpi_test.sh

# Copy Slurm configuration to compute nodes
for NODE in compute01 compute02 compute03; do
  scp /etc/slurm/slurm.conf root@$NODE:/etc/slurm/
  ssh root@$NODE "systemctl restart slurmd"
done

# Restart Slurm controller
systemctl restart slurmctld

echo "OpenMPI integration with Slurm configured"
