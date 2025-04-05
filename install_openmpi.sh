#!/bin/bash
# File: install_openmpi.sh

# Define OpenMPI version
OPENMPI_VERSION="4.1.5"

# Install dependencies on controller
dnf install -y gcc gcc-c++ make libtool autoconf automake valgrind valgrind-devel

# Download and extract OpenMPI
cd /tmp
wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-${OPENMPI_VERSION}.tar.gz
tar -xzf openmpi-${OPENMPI_VERSION}.tar.gz
cd openmpi-${OPENMPI_VERSION}

# Configure and build OpenMPI
./configure --prefix=/opt/openmpi --with-slurm --enable-mpi-fortran
make -j $(nproc)
make install

# Create modulefile for OpenMPI
mkdir -p /usr/share/Modules/modulefiles/mpi
cat > /usr/share/Modules/modulefiles/mpi/openmpi-${OPENMPI_VERSION} << EOF
#%Module 1.0
#
#  OpenMPI ${OPENMPI_VERSION} module for use with 'environment-modules' package:
#
conflict mpi
prepend-path    PATH            /opt/openmpi/bin
prepend-path    LD_LIBRARY_PATH /opt/openmpi/lib
prepend-path    MANPATH         /opt/openmpi/share/man
setenv          MPI_HOME        /opt/openmpi
setenv          MPI_BIN         /opt/openmpi/bin
setenv          MPI_SYSCONFIG   /opt/openmpi/etc
setenv          MPI_FORTRAN_MOD_DIR   /opt/openmpi/lib
setenv          MPI_INCLUDE     /opt/openmpi/include
setenv          MPI_LIB         /opt/openmpi/lib
setenv          MPI_MAN         /opt/openmpi/share/man
setenv          MPI_COMPILER    openmpi-x86_64
setenv          MPI_SUFFIX      _openmpi
setenv          MPI_HOME        /opt/openmpi
EOF

# Install environment-modules package
dnf install -y environment-modules

# Create script to deploy OpenMPI to compute nodes
cat > deploy_openmpi.sh << 'EOF'
#!/bin/bash

# Create OpenMPI directory
mkdir -p /opt/openmpi

# Install dependencies
dnf install -y gcc gcc-c++ make environment-modules
EOF

# Deploy to compute nodes
for NODE in compute01 compute02 compute03; do
  scp deploy_openmpi.sh root@$NODE:/tmp/
  ssh root@$NODE "bash /tmp/deploy_openmpi.sh"
  
  # Copy compiled OpenMPI
  scp -r /opt/openmpi/* root@$NODE:/opt/openmpi/
  
  # Copy modulefile
  ssh root@$NODE "mkdir -p /usr/share/Modules/modulefiles/mpi"
  scp /usr/share/Modules/modulefiles/mpi/openmpi-${OPENMPI_VERSION} root@$NODE:/usr/share/Modules/modulefiles/mpi/
done

# Clean up
rm deploy_openmpi.sh

echo "OpenMPI installed and configured on all nodes"
