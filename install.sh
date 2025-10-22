#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   GitLab MR Review Plugin - Installation Script           ║"
echo "║   For Claude Code                                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect shell and config file
SHELL_CONFIG=""
SHELL_NAME=""

# First, try to detect by shell version
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    fi
    SHELL_NAME="bash"
fi

# If no config found, check what files exist
if [ -z "$SHELL_CONFIG" ]; then
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
        SHELL_NAME="zsh"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
        SHELL_NAME="bash"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
        SHELL_NAME="bash"
    elif [ -f "$HOME/.profile" ]; then
        SHELL_CONFIG="$HOME/.profile"
        SHELL_NAME="bash"
    else
        # No config file exists, create one based on default shell
        if [[ "$SHELL" == */zsh ]]; then
            SHELL_CONFIG="$HOME/.zshrc"
            SHELL_NAME="zsh"
        else
            SHELL_CONFIG="$HOME/.bashrc"
            SHELL_NAME="bash"
        fi
        echo -e "${YELLOW}⚠${NC}  No shell config file found. Will create: ${SHELL_CONFIG}"
        touch "$SHELL_CONFIG"
    fi
fi

echo -e "${GREEN}✓${NC} Detected shell: ${SHELL_NAME}"
echo -e "${GREEN}✓${NC} Shell config: ${SHELL_CONFIG}"
echo ""

# Step 1: Get GitLab Personal Access Token
echo -e "${BLUE}Step 1: GitLab Configuration${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You need a GitLab Personal Access Token with 'read_api' scope."
echo ""
echo "To create one:"
echo "  1. Go to GitLab → Settings → Access Tokens → Personal Access Tokens"
echo "  2. Click 'Add new token'"
echo "  3. Name it 'Claude Code MR Review'"
echo "  4. Select 'read_api' scope"
echo "  5. Create and copy the token"
echo ""

read -p "Enter your GitLab Personal Access Token: " GITLAB_TOKEN

if [ -z "$GITLAB_TOKEN" ]; then
    echo -e "${RED}✗ Error: Token cannot be empty${NC}"
    exit 1
fi

echo ""
read -p "Enter your GitLab API URL [https://gitlab.com/api/v4]: " GITLAB_URL
GITLAB_URL=${GITLAB_URL:-https://gitlab.com/api/v4}

echo ""
echo -e "${GREEN}✓${NC} GitLab token configured"
echo -e "${GREEN}✓${NC} API URL: ${GITLAB_URL}"
echo ""

# Step 2: Add to shell config
echo -e "${BLUE}Step 2: Configuring Environment Variables${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if variables already exist in config
if grep -q "GITLAB_PERSONAL_ACCESS_TOKEN" "$SHELL_CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC}  GitLab variables already exist in $SHELL_CONFIG"
    read -p "Do you want to update them? (y/n): " UPDATE_VARS

    if [ "$UPDATE_VARS" = "y" ] || [ "$UPDATE_VARS" = "Y" ]; then
        # Remove old entries
        sed -i.bak '/GITLAB_PERSONAL_ACCESS_TOKEN/d' "$SHELL_CONFIG"
        sed -i.bak '/GITLAB_API_URL/d' "$SHELL_CONFIG"
        echo -e "${GREEN}✓${NC} Removed old configuration"
    else
        echo -e "${YELLOW}⚠${NC}  Skipping environment variable update"
        SKIP_ENV_UPDATE=true
    fi
fi

if [ "$SKIP_ENV_UPDATE" != "true" ]; then
    echo "" >> "$SHELL_CONFIG"
    echo "# GitLab MR Review Plugin Configuration" >> "$SHELL_CONFIG"
    echo "export GITLAB_PERSONAL_ACCESS_TOKEN=\"$GITLAB_TOKEN\"" >> "$SHELL_CONFIG"
    echo "export GITLAB_API_URL=\"$GITLAB_URL\"" >> "$SHELL_CONFIG"

    echo -e "${GREEN}✓${NC} Environment variables added to $SHELL_CONFIG"
fi

# Export for current session
export GITLAB_PERSONAL_ACCESS_TOKEN="$GITLAB_TOKEN"
export GITLAB_API_URL="$GITLAB_URL"

echo ""

# Step 3: Copy plugin
echo -e "${BLUE}Step 3: Installing Plugin${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PLUGIN_DIR="$HOME/.claude/plugins/gitlab-mr-review"

if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${YELLOW}⚠${NC}  Plugin directory already exists at $PLUGIN_DIR"
    read -p "Do you want to overwrite it? (y/n): " OVERWRITE

    if [ "$OVERWRITE" = "y" ] || [ "$OVERWRITE" = "Y" ]; then
        rm -rf "$PLUGIN_DIR"
        echo -e "${GREEN}✓${NC} Removed old plugin"
    else
        echo -e "${YELLOW}⚠${NC}  Skipping plugin installation"
        SKIP_PLUGIN_INSTALL=true
    fi
fi

if [ "$SKIP_PLUGIN_INSTALL" != "true" ]; then
    mkdir -p "$HOME/.claude/plugins"
    cp -r "plugins/gitlab-mr-review" "$HOME/.claude/plugins/"
    echo -e "${GREEN}✓${NC} Plugin copied to $PLUGIN_DIR"
fi

echo ""

# Step 4: Install Python dependencies
echo -e "${BLUE}Step 4: Installing Python Dependencies${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}✗ Error: Python is not installed${NC}"
    echo "Please install Python 3.10 or higher and run this script again."
    exit 1
fi

PYTHON_CMD=$(command -v python3 || command -v python)
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo -e "${GREEN}✓${NC} Found Python: $PYTHON_VERSION"

cd "$PLUGIN_DIR/server"

echo "Installing dependencies..."
if $PYTHON_CMD -m pip install -e . > /tmp/gitlab-plugin-install.log 2>&1; then
    echo -e "${GREEN}✓${NC} Python dependencies installed successfully"
else
    echo -e "${RED}✗ Error: Failed to install Python dependencies${NC}"
    echo "Check /tmp/gitlab-plugin-install.log for details"
    exit 1
fi

echo ""

# Step 5: Verify installation
echo -e "${BLUE}Step 5: Verifying Installation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if $PYTHON_CMD -c "import httpx; from mcp.server.fastmcp import FastMCP; print('Dependencies OK')" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Python dependencies verified"
else
    echo -e "${RED}✗ Warning: Could not verify Python dependencies${NC}"
fi

if [ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
    echo -e "${GREEN}✓${NC} Plugin structure verified"
else
    echo -e "${RED}✗ Warning: Plugin structure may be incomplete${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 Installation Complete! 🎉                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "  1. ${YELLOW}Restart your terminal${NC} (to load environment variables)"
echo "     Close and reopen your terminal application"
echo ""
echo "  2. ${YELLOW}Restart Claude Code${NC} (to load the plugin)"
echo "     Quit Claude Code completely and relaunch it"
echo ""
echo "  3. ${YELLOW}Test the plugin${NC} by running:"
echo "     /help"
echo "     You should see /review-gitlab-mr in the list"
echo ""
echo "  4. ${YELLOW}Use the plugin${NC}:"
echo "     /review-gitlab-mr project-name mr-number"
echo ""
echo -e "${BLUE}Example:${NC}"
echo "  /review-gitlab-mr gitlab-mr-mcp 42"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  If the command doesn't appear:"
echo "  - Make sure you restarted your terminal AND Claude Code"
echo "  - Check: ls ~/.claude/plugins/gitlab-mr-review/"
echo "  - Check: echo \$GITLAB_PERSONAL_ACCESS_TOKEN"
echo ""
echo -e "${GREEN}Happy code reviewing! 🚀${NC}"
echo ""
