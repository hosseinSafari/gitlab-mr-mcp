#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing GitLab MR Review Plugin...${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo -e "${RED}✗ Error: conda is not installed or not in PATH${NC}"
    echo "Please install Anaconda or Miniconda first:"
    echo "  https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found conda"

# Step 1: Create conda environment with Python 3.10
echo ""
echo -e "${BLUE}Step 1: Creating conda environment with Python 3.10${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

VENV_PATH="$SCRIPT_DIR/server/.venv"

if [ -d "$VENV_PATH" ]; then
    echo -e "${YELLOW}⚠${NC}  Virtual environment already exists at $VENV_PATH"
    read -p "Do you want to recreate it? (y/n): " RECREATE
    
    if [ "$RECREATE" = "y" ] || [ "$RECREATE" = "Y" ]; then
        echo "Removing old environment..."
        rm -rf "$VENV_PATH"
    else
        echo -e "${YELLOW}⚠${NC}  Using existing environment"
        SKIP_VENV_CREATE=true
    fi
fi

if [ "$SKIP_VENV_CREATE" != "true" ]; then
    echo "Creating conda environment at: $VENV_PATH"
    conda create -p "$VENV_PATH" python=3.10 -y
    echo -e "${GREEN}✓${NC} Conda environment created"
fi

# Step 2: Install dependencies
echo ""
echo -e "${BLUE}Step 2: Installing Python dependencies${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Activate the conda environment and install
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$VENV_PATH"

cd "$SCRIPT_DIR/server"

echo "Installing packages from pyproject.toml..."
pip install -e .

echo -e "${GREEN}✓${NC} Dependencies installed"

# Verify installation
echo ""
echo -e "${BLUE}Step 3: Verifying installation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if python -c "import httpx; from mcp.server.fastmcp import FastMCP; print('✓ All dependencies OK')" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Installation verified successfully"
else
    echo -e "${RED}✗ Warning: Could not verify installation${NC}"
fi

conda deactivate

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         GitLab MR Review Plugin Installed! 🎉              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Virtual Environment:${NC} $VENV_PATH"
echo -e "${BLUE}Python Version:${NC} 3.10"
echo ""

