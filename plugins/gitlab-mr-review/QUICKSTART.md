# Quick Start Guide - GitLab MR Review Plugin

## Installation (Automatic)

When you install this plugin, it will **automatically**:

1. ✅ Create a conda virtual environment with Python 3.10
2. ✅ Install all required dependencies
3. ✅ Configure the MCP server

**You don't need to manually install Python or dependencies!**

## Prerequisites

Just make sure you have **conda** installed:

```bash
# Check if conda is installed
conda --version

# If not installed, download from:
# https://docs.conda.io/en/latest/miniconda.html
```

## Setup (2 Steps)

### Step 1: Set Environment Variables

Add these to your `~/.zshrc` or `~/.bashrc`:

```bash
export GITLAB_PERSONAL_ACCESS_TOKEN="your-token-here"
export GITLAB_API_URL="https://gitlab.com/api/v4"
```

Then reload your shell:
```bash
source ~/.zshrc
```

### Step 2: Install Plugin

Install through Claude marketplace, or manually:

```bash
cd ~/.claude/plugins/gitlab-mr-review
./install.sh
```

That's it! The script will:
- Create `server/.venv/` with Python 3.10
- Install httpx and mcp packages
- Verify everything works

## Usage

In Claude Code, use the slash command:

```
/review-gitlab-mr my-project 42
```

Replace:
- `my-project` with your GitLab project name
- `42` with your merge request number

## Verify Installation

```bash
# Check if virtual environment was created
ls ~/.claude/plugins/gitlab-mr-review/server/.venv

# Should see:
# bin/  include/  lib/  etc/  ...
```

## Troubleshooting

### Error: "conda: command not found"

Install Miniconda:
```bash
# macOS (Intel)
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh

# macOS (Apple Silicon)
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh
bash Miniconda3-latest-MacOSX-arm64.sh

# Linux
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

### Error: "Server not configured"

Make sure environment variables are set:
```bash
echo $GITLAB_PERSONAL_ACCESS_TOKEN  # Should show your token
echo $GITLAB_API_URL                 # Should show API URL
```

If empty:
1. Add exports to `~/.zshrc`
2. Run `source ~/.zshrc`
3. Restart Claude Code

## What Gets Installed

```
server/.venv/               # Conda virtual environment
├── bin/
│   └── python             # Python 3.10
├── lib/
│   └── python3.10/
│       └── site-packages/
│           ├── httpx/     # HTTP client
│           └── mcp/       # Model Context Protocol
```

## Manual Reinstall

If something goes wrong:

```bash
cd ~/.claude/plugins/gitlab-mr-review

# Remove old environment
rm -rf server/.venv

# Reinstall
./install.sh
```

## Support

- 📖 Full docs: [README.md](./README.md)
- 🐛 Issues: [GitHub Issues](https://github.com/hosseinSafari/gitlab-mr-mcp/issues)
- 🏗️ Structure: See [STRUCTURE.md](../../STRUCTURE.md) in repo root

---

**Happy Code Reviewing! 🚀**

