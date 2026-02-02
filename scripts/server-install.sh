#!/bin/bash
#==============================================================#
# File      :   install.sh
# Mtime     :   2026-02-01
# Desc      :   Install observability.svc.plus
# Usage     :   curl ... | bash -s <VERSION> <DOMAIN>
#==============================================================#

# Default parameters
VERSION="main"
DOMAIN="$(hostname)"

# Handle flags
AUTO_YES=false
while [[ "$#" -gt 0 && "$1" == -* ]]; do
    case "$1" in
        -y|--yes) AUTO_YES=true; shift ;;
        *) break ;;
    esac
done

if [[ -n "$1" ]]; then
    # if $1 looks like a version/branch (main, master, v1.0, etc.)
    if [[ "$1" == "main" || "$1" == "master" || "$1" == v[0-9]* ]]; then
        VERSION="$1"
        DOMAIN="${2:-$(hostname)}"
    else
        # assume $1 is the DOMAIN
        DOMAIN="$1"
    fi
fi

REPO_URL="https://github.com/cloud-neutral-toolkit/observability.svc.plus.git"
REPO_NAME=$(basename "${REPO_URL}" .git)
INSTALL_DIR="${HOME}/${REPO_NAME}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing ${REPO_NAME}...${NC}"
echo -e "${BLUE}Version : ${VERSION}${NC}"
echo -e "${BLUE}Domain  : ${DOMAIN}${NC}"
echo -e "${BLUE}Repo    : ${REPO_URL}${NC}"
echo -e "${BLUE}Dir     : ${INSTALL_DIR}${NC}"

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    echo "Please install git first (yum install git / apt install git)"
    exit 1
fi

# Clone or Update
if [ -d "${INSTALL_DIR}" ]; then
    echo -e "${BLUE}Directory ${INSTALL_DIR} already exists.${NC}"
    if [ "$AUTO_YES" = true ]; then
        REPLY="y"
    else
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "${INSTALL_DIR}"
        if ! git clone -b "${VERSION}" "${REPO_URL}" "${INSTALL_DIR}"; then
            echo -e "${RED}Error: Failed to clone repository.${NC}"
            exit 1
        fi
    else
        echo -e "${BLUE}Updating existing repo...${NC}"
        cd "${INSTALL_DIR}"
        git fetch origin
        if ! git checkout "${VERSION}"; then
             echo -e "${RED}Error: Version ${VERSION} not found${NC}"
             exit 1
        fi
        git pull origin "${VERSION}"
    fi
else
    if ! git clone -b "${VERSION}" "${REPO_URL}" "${INSTALL_DIR}"; then
        echo -e "${RED}Error: Failed to clone repository.${NC}"
        exit 1
    fi
fi

cd "${INSTALL_DIR}"

# Fix root SSH access if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${BLUE}Ensuring root SSH access...${NC}"
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q
    fi
    PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
    if ! grep -q "$PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    fi
    # Also ensure SSH daemon allows root login via key
    if grep -q "PermitRootLogin" /etc/ssh/sshd_config; then
        sed -i 's/^.*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    else
        echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
    fi
    systemctl reload ssh &>/dev/null || systemctl reload sshd &>/dev/null
fi

# Run Bootstrap
if [ -f "./bootstrap" ]; then
    echo -e "${BLUE}Running bootstrap...${NC}"
    ./bootstrap || { echo -e "${RED}Error: Bootstrap failed${NC}"; exit 1; }
elif [ -f "./configure" ]; then
    echo -e "${BLUE}Found configure script, but no bootstrap. Proceeding...${NC}"
else
    echo -e "${RED}Warning: Primary setup scripts not found! Check repo content.${NC}"
fi

# Run Configure automatically
if [ -f "./configure" ]; then
    echo -e "${BLUE}Running configure (forcing 127.0.0.1)...${NC}"
    ./configure -n -i 127.0.0.1 || { echo -e "${RED}Error: Configure failed${NC}"; exit 1; }
fi

echo -e "${GREEN}Installation and configuration successful!${NC}"
echo -e "Next steps:"
echo -e "  cd ${INSTALL_DIR}"
echo -e "  ./deploy.yml # Run this to start the actual deployment"
