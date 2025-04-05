#!/bin/bash
# File: install_prometheus.sh

# Define versions
PROMETHEUS_VERSION="2.46.0"
NODE_EXPORTER_VERSION="1.6.1"

# Download and install Prometheus on controller
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64

# Create directories
mkdir -p /opt/prometheus/data
mkdir -p /etc/prometheus

# Copy binaries and configuration
cp prometheus promtool /usr/local/bin/
cp -r consoles/ console_libraries/ /etc/prometheus/
cp prometheus.yml /etc/prometheus/

# Configure Prometheus
cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval:     15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'node_exporters'
    static_configs:
    - targets: ['controller:9100', 'compute01:9100', 'compute02:9100', 'compute03:9100']
EOF

# Create Prometheus service
cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus Time Series Collection and Processing Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/opt/prometheus/data \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Create prometheus user
useradd --no-create-home --shell /bin/false prometheus

# Set ownership
chown -R prometheus:prometheus /etc/prometheus /opt/prometheus /usr/local/bin/{prometheus,promtool}

# Install Node Exporter on controller
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cd node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64
cp node_exporter /usr/local/bin/

# Create Node Exporter service
cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Create node_exporter user
useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Enable and start services
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
systemctl enable node_exporter
systemctl start node_exporter

# Create script for Node Exporter deployment to compute nodes
cat > deploy_node_exporter.sh << 'EOF'
#!/bin/bash

# Download and install Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
cd node_exporter-1.6.1.linux-amd64
cp node_exporter /usr/local/bin/

# Create Node Exporter service
cat > /etc/systemd/system/node_exporter.service << 'EOL'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOL

# Create node_exporter user
useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Enable and start service
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
EOF

# Deploy Node Exporter to compute nodes
for NODE in compute01 compute02 compute03; do
  scp deploy_node_exporter.sh root@$NODE:/tmp/
  ssh root@$NODE "bash /tmp/deploy_node_exporter.sh"
done

# Clean up
rm deploy_node_exporter.sh

echo "Prometheus and Node Exporter installed and configured"
