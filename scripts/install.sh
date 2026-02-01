#!/bin/bash
#==============================================================#
# File      :   install.sh
# Mtime     :   2026-02-01
# Desc      :   Install observability.svc.plus
# Usage     :   curl ... | bash -s <VERSION> <DOMAIN>
#==============================================================#

# Default parameters
VERSION="${1:-main}"
DOMAIN="${2:-$(hostname)}"
REPO_URL="https://github.com/cloud-neutral-toolkit/observability.svc.plus.git"
INSTALL_DIR="${HOME}/pigsty"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing observability.svc.plus...${NC}"
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
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "${INSTALL_DIR}"
        git clone -b "${VERSION}" "${REPO_URL}" "${INSTALL_DIR}"
    else
        echo -e "${BLUE}Updating existing repo...${NC}"
        cd "${INSTALL_DIR}"
        git fetch origin
        git checkout "${VERSION}" || echo -e "${RED}Version ${VERSION} not found${NC}"
        git pull origin "${VERSION}"
    fi
else
    git clone -b "${VERSION}" "${REPO_URL}" "${INSTALL_DIR}"
fi

cd "${INSTALL_DIR}"

# Run Bootstrap
if [ -f "./bootstrap" ]; then
    echo -e "${BLUE}Running bootstrap...${NC}"
    ./bootstrap
else
    echo -e "${RED}bootstrap script not found!${NC}"
fi

echo -e "${GREEN}Installation successful!${NC}"
echo -e "Next steps:"
echo -e "  cd ${INSTALL_DIR}"
echo -e "  ./configure # Generate config"
echo -e "  ./deploy.yml # Install"
