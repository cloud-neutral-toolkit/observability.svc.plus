#!/bin/bash
set -e

# Default Configuration
DEFAULT_ENDPOINT="https://infra.svc.plus/ingest/otlp"
INSTALL_DIR="/opt/observability"
BIN_DIR="$INSTALL_DIR/bin"
CONFIG_DIR="$INSTALL_DIR/config"
DATA_DIR="$INSTALL_DIR/data"

# Versions
NODE_EXPORTER_VERSION="1.7.0"
PROCESS_EXPORTER_VERSION="0.7.10"
VECTOR_VERSION="0.36.0"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect Architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH_NODE="amd64"
        ARCH_PROCESS="amd64"
        ARCH_VECTOR="x86_64"
        ;;
    aarch64|arm64)
        ARCH_NODE="arm64"
        ARCH_PROCESS="arm64"
        ARCH_VECTOR="aarch64"
        ;;
    *)
        log_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Parse Arguments
ENDPOINT="$DEFAULT_ENDPOINT"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --endpoint) ENDPOINT="$2"; shift ;;
        *) log_error "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

log_info "Starting Observability Agent Installation"
log_info "Target Endpoint: $ENDPOINT"
log_info "Installation Directory: $INSTALL_DIR"

# Prepare Directories
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$DATA_DIR"

# --- 1. Install Node Exporter ---
install_node_exporter() {
    if systemctl is-active --quiet node_exporter; then
        log_info "Node Exporter is already running. Skipping installation."
        return
    fi
    
    log_info "Installing Node Exporter v${NODE_EXPORTER_VERSION}..."
    
    local URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH_NODE}.tar.gz"
    local TMP_DIR=$(mktemp -d)
    
    curl -L --progress-bar "$URL" -o "$TMP_DIR/node_exporter.tar.gz"
    tar -xzf "$TMP_DIR/node_exporter.tar.gz" -C "$TMP_DIR"
    mv "$TMP_DIR/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH_NODE}/node_exporter" "$BIN_DIR/"
    rm -rf "$TMP_DIR"
    
    # Create Systemd Service
    cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=$BIN_DIR/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now node_exporter
    log_success "Node Exporter installed and started."
}

# --- 2. Install Process Exporter ---
install_process_exporter() {
    if systemctl is-active --quiet process_exporter; then
        log_info "Process Exporter is already running. Skipping installation."
        return
    fi

    log_info "Installing Process Exporter v${PROCESS_EXPORTER_VERSION}..."
    
    local URL="https://github.com/ncabatoff/process-exporter/releases/download/v${PROCESS_EXPORTER_VERSION}/process-exporter-${PROCESS_EXPORTER_VERSION}.linux-${ARCH_PROCESS}.tar.gz"
    local TMP_DIR=$(mktemp -d)
    
    curl -L --progress-bar "$URL" -o "$TMP_DIR/process_exporter.tar.gz"
    tar -xzf "$TMP_DIR/process_exporter.tar.gz" -C "$TMP_DIR"
    mv "$TMP_DIR/process-exporter-${PROCESS_EXPORTER_VERSION}.linux-${ARCH_PROCESS}/process-exporter" "$BIN_DIR/"
    rm -rf "$TMP_DIR"
    
    # Configure Process Exporter
    cat <<EOF > "$CONFIG_DIR/process-config.yaml"
process_names:
  - name: "{{.Comm}}"
    cmdline:
    - '.+'
EOF

    # Create Systemd Service
    cat <<EOF > /etc/systemd/system/process_exporter.service
[Unit]
Description=Process Exporter
After=network.target

[Service]
User=root
ExecStart=$BIN_DIR/process-exporter -config.path $CONFIG_DIR/process-config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now process_exporter
    log_success "Process Exporter installed and started."
}

# --- 3. Install Vector ---
install_vector() {
    log_info "Installing Vector v${VECTOR_VERSION}..."
    
    # Vector installation via script is robust but let's use direct binary download to be consistent
    local URL="https://packages.timber.io/vector/${VECTOR_VERSION}/vector-${VECTOR_VERSION}-${ARCH_VECTOR}-unknown-linux-gnu.tar.gz"
    local TMP_DIR=$(mktemp -d)
    
    curl -L --progress-bar "$URL" -o "$TMP_DIR/vector.tar.gz"
    tar -xzf "$TMP_DIR/vector.tar.gz" -C "$TMP_DIR"
    mv "$TMP_DIR/vector-${ARCH_VECTOR}-unknown-linux-gnu/bin/vector" "$BIN_DIR/"
    rm -rf "$TMP_DIR"
    
    # Configure Vector
    log_info "Configuring Vector to push to $ENDPOINT..."
    
    cat <<EOF > "$CONFIG_DIR/vector.yaml"
data_dir: "$DATA_DIR/vector"

sources:
  node_exporter:
    type: prometheus_scrape
    endpoints:
      - http://localhost:9100/metrics
    scrape_interval_secs: 15

  process_exporter:
    type: prometheus_scrape
    endpoints:
      - http://localhost:9256/metrics
    scrape_interval_secs: 15

sinks:
  otlp_out:
    type: opentelemetry
    inputs: ["node_exporter", "process_exporter"]
    endpoint: "$ENDPOINT"
    protocol: http
    compression: gzip
    encoding:
      codec: protobuf
EOF

    # Create Systemd Service
    cat <<EOF > /etc/systemd/system/vector.service
[Unit]
Description=Vector
Documentation=https://vector.dev
After=network-online.target
Requires=network-online.target

[Service]
User=root
ExecStart=$BIN_DIR/vector --config $CONFIG_DIR/vector.yaml
Restart=always
RestartSec=5
AmbientCapabilities=CAP_NET_BIND_SERVICE
Environment="VECTOR_LOG=info"

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now vector
    
    # Restart to apply new config if it was already running
    systemctl restart vector
    log_success "Vector installed and started."
}

# --- Check Permissions ---
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root" 
   exit 1
fi

# --- Execution ---
install_node_exporter
install_process_exporter
install_vector

echo ""
log_success "---------------------------------------------------"
log_success " Agent installation complete!"
log_success " Data is being pushed to: $ENDPOINT"
log_success "---------------------------------------------------"
