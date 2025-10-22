# GitLab MR Review - Marketplace Structure

## Overview

This repository contains a complete Claude Plugin Marketplace setup with automatic conda environment provisioning.

## Directory Structure

```
gitlab-mr-mcp/
├── .claude-plugin/
│   └── marketplace.json           # Marketplace definition
│
└── plugins/
    └── gitlab-mr-review/           # Plugin directory
        ├── .claude-plugin/
        │   └── plugin.json         # Plugin metadata + install hook
        │
        ├── .mcp.json               # MCP server configuration
        ├── install.sh              # 🔥 Auto-setup script (conda + Python 3.10)
        │
        ├── commands/
        │   └── review-gitlab-mr.md # Slash command definition
        │
        ├── server/
        │   ├── .venv/              # 🐍 Conda virtual environment (auto-created)
        │   ├── gitlab.py           # MCP server implementation
        │   └── pyproject.toml      # Python dependencies
        │
        ├── examples/
        │   └── claude_desktop_config.json
        │
        └── README.md               # Plugin documentation
```

## Hierarchy Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Marketplace (.claude-plugin/marketplace.json)              │
│  - name: gitlab-mr-review-marketplace                       │
│  - owner: Amir Masoud Ahmadi, Hossein Safari                │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Plugin (plugins/gitlab-mr-review/.claude-plugin/plugin.json)│
│  - name: gitlab-mr-review                                   │
│  - install: ./install.sh  ← 🔥 Automatic installation       │
│  - commands: ./commands                                     │
│  - mcpServers: ./.mcp.json                                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
┌───────────────────────┐   ┌──────────────────────────┐
│  Slash Commands       │   │  MCP Server (.mcp.json)  │
│  /review-gitlab-mr    │   │  - command: .venv/bin/python │
└───────────────────────┘   │  - args: server/gitlab.py│
                            │  - env: GITLAB_*         │
                            └────────┬─────────────────┘
                                     │
                                     ▼
                    ┌────────────────────────────────┐
                    │  MCP Server (server/gitlab.py) │
                    │  Tools:                        │
                    │  - get_projects()              │
                    │  - merge_request_changes()     │
                    │  - merge_request_file_diff()   │
                    └────────────────────────────────┘
```

## Automatic Installation Flow

When a user installs the plugin from the marketplace:

```
1. User installs plugin from marketplace
   ↓
2. Claude executes: plugins/gitlab-mr-review/install.sh
   ↓
3. install.sh creates conda environment:
   - Location: plugins/gitlab-mr-review/server/.venv
   - Python version: 3.10
   - Dependencies: httpx, mcp[cli]
   ↓
4. .mcp.json points to: server/.venv/bin/python
   ↓
5. Plugin ready to use!
```

## Key Files

### 1. Marketplace Configuration
**File**: `.claude-plugin/marketplace.json`
```json
{
  "name": "gitlab-mr-review-marketplace",
  "owner": {...},
  "metadata": {...},
  "plugins": [{
    "name": "gitlab-mr-review",
    "source": "./plugins/gitlab-mr-review",
    ...
  }]
}
```

### 2. Plugin Configuration
**File**: `plugins/gitlab-mr-review/.claude-plugin/plugin.json`
```json
{
  "name": "gitlab-mr-review",
  "commands": "./commands",
  "mcpServers": "./.mcp.json",
  "install": "./install.sh"  ← 🔥 Runs automatically
}
```

### 3. Installation Script
**File**: `plugins/gitlab-mr-review/install.sh`
- ✅ Checks for conda
- ✅ Creates `.venv` with Python 3.10
- ✅ Installs dependencies via pip
- ✅ Verifies installation

### 4. MCP Server Configuration
**File**: `plugins/gitlab-mr-review/.mcp.json`
```json
{
  "gitlab": {
    "command": "${CLAUDE_PLUGIN_ROOT}/server/.venv/bin/python",
    "args": ["${CLAUDE_PLUGIN_ROOT}/server/gitlab.py"],
    "env": {
      "GITLAB_PERSONAL_ACCESS_TOKEN": "${GITLAB_PERSONAL_ACCESS_TOKEN}",
      "GITLAB_API_URL": "${GITLAB_API_URL}"
    }
  }
}
```

### 5. MCP Server Implementation
**File**: `plugins/gitlab-mr-review/server/gitlab.py`
- FastMCP server with 3 tools
- Connects to GitLab API
- Provides MR analysis capabilities

### 6. Python Dependencies
**File**: `plugins/gitlab-mr-review/server/pyproject.toml`
```toml
requires-python = ">=3.10"
dependencies = [
    "httpx>=0.28.1",
    "mcp[cli]>=1.2.0",
]
```

## Environment Variables Required

Users must set these before using the plugin:

```bash
export GITLAB_PERSONAL_ACCESS_TOKEN="glpat-xxxxxxxxxxxx"
export GITLAB_API_URL="https://gitlab.com/api/v4"
```

## Testing the Setup

To verify the installation works:

```bash
# 1. Navigate to plugin directory
cd plugins/gitlab-mr-review

# 2. Run installation script
./install.sh

# 3. Verify conda environment was created
ls -la server/.venv

# 4. Activate environment and test
conda activate server/.venv
python -c "import httpx; from mcp.server.fastmcp import FastMCP; print('✓ OK')"

# 5. Test MCP server directly
python server/gitlab.py
```

## Features

### ✅ Automatic Setup
- No manual Python installation
- No manual dependency management
- Isolated conda environment per plugin

### ✅ Reproducible
- Fixed Python version (3.10)
- Pinned dependencies in pyproject.toml
- Same environment for all users

### ✅ Clean
- Each plugin has its own .venv
- No system Python pollution
- Easy to uninstall (just delete plugin folder)

## Publishing to Marketplace

When ready to publish:

1. Ensure all files are in place ✅
2. Test installation flow locally
3. Commit and push to repository
4. Submit to Claude Plugin Marketplace
5. Users will get automatic conda setup!

## Authors

- Amir Masoud Ahmadi
- Hossein Safari

## License

MIT

