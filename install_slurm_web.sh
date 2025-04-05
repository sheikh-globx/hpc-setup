#!/bin/bash
# File: install_slurm_web.sh

# Install dependencies for Slurm Web
dnf install -y httpd httpd-devel mod_ssl php php-cli php-pdo php-gd php-xml php-json php-ldap mariadb-server php-mysqlnd git

# Start and enable MariaDB
systemctl enable mariadb
systemctl start mariadb

# Secure MariaDB installation (set root password)
mysql_secure_installation

# Create database for Slurm Web
mysql -u root -p << 'EOF'
CREATE DATABASE slurm_web;
CREATE USER 'slurm_web'@'localhost' IDENTIFIED BY 'slurm_web_password';
GRANT ALL PRIVILEGES ON slurm_web.* TO 'slurm_web'@'localhost';
FLUSH PRIVILEGES;
EOF

# Clone Slurm Web
cd /var/www/
git clone https://github.com/edf-hpc/slurm-web.git
cd slurm-web

# Set up configuration
cp conf/slurm-web.conf.example /etc/slurm-web.conf
cp conf/restapi.conf.example /etc/httpd/conf.d/slurm-web-restapi.conf
cp conf/dashboard.conf.example /etc/httpd/conf.d/slurm-web-dashboard.conf

# Configure database connection
sed -i 's/dbname=slurmweb/dbname=slurm_web/g' /etc/slurm-web.conf
sed -i 's/dbuser=slurmweb/dbuser=slurm_web/g' /etc/slurm-web.conf
sed -i 's/dbpassword=slurmweb/dbpassword=slurm_web_password/g' /etc/slurm-web.conf

# Initialize database
php rest/script/database.php

# Set up Apache configuration for Slurm Web
cat > /etc/httpd/conf.d/slurm-web.conf << 'EOF'
<VirtualHost *:80>
  ServerName controller
  
  # REST API
  ProxyPass /slurm-web-api http://localhost:8080
  ProxyPassReverse /slurm-web-api http://localhost:8080
  
  # Dashboard
  DocumentRoot /var/www/slurm-web/dashboard
  
  <Directory /var/www/slurm-web/dashboard>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF

# Start REST API service
cat > /etc/systemd/system/slurm-web-restapi.service << 'EOF'
[Unit]
Description=Slurm Web REST API
After=network.target

[Service]
Type=simple
User=apache
Group=apache
ExecStart=/usr/bin/php -S 0.0.0.0:8080 -t /var/www/slurm-web/rest
WorkingDirectory=/var/www/slurm-web/rest
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start and enable services
systemctl daemon-reload
systemctl enable slurm-web-restapi
systemctl start slurm-web-restapi
systemctl enable httpd
systemctl start httpd

echo "Slurm Web installed and configured at http://controller/slurm-web/"
