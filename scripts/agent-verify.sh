#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_info() { echo -e "${NC}[INFO] $1"; }

echo "---------------------------------------------------"
echo " Verifying Observability Agent Installation"
echo "---------------------------------------------------"

# 1. Check Systemd Services
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        log_success "Service '$service' is running"
    else
        log_fail "Service '$service' is NOT running"
        systemctl status "$service" --no-pager | head -n 10
    fi
}

log_info "Checking Services..."
check_service "node_exporter"
check_service "process_exporter"
check_service "vector"

# 2. Check Ports
check_port() {
    local port=$1
    local name=$2
    if ss -tulnA | grep -q ":$port "; then
        log_success "Port $port ($name) is listening"
    else
        log_fail "Port $port ($name) is NOT listening"
    fi
}

echo ""
log_info "Checking Ports..."
check_port 9100 "Node Exporter"
check_port 9256 "Process Exporter"

# 3. Check Vector Connectivity / Logs
echo ""
log_info "Checking Vector Logs (Last 10 lines)..."
# Check for errors in the last few logs
if journalctl -u vector -n 20 --no-pager | grep -iE "error|fail"; then
    log_warn "Possible errors found in Vector logs:"
    journalctl -u vector -n 20 --no-pager | grep -iE "error|fail"
else
    log_success "No recent errors found in Vector logs."
fi

echo ""
log_info "Vector Status Summary:"
journalctl -u vector -n 5 --no-pager

echo ""
echo "---------------------------------------------------"
echo " Verification Complete."
echo " If all services are OK, data should appear in your infrastructure dashboard."
echo "---------------------------------------------------"
