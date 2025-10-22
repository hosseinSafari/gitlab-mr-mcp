# GitLab MR Review Plugin for Claude Code

A Claude Code plugin that provides comprehensive automated code review for GitLab merge requests using MCP (Model Context Protocol) tools.

[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Plugin-blue.svg)](https://claude.com/claude-code)

## Features

- 🔍 **Automated Code Review**: Analyzes all files in a merge request for security, bugs, performance, and code quality issues
- ⚡ **Parallel Processing**: Fetches and analyzes all file diffs in parallel for maximum efficiency
- 🎯 **Severity-Based Reporting**: Categorizes issues as Critical, High, Medium, or Low priority
- 📊 **Comprehensive Analysis**: Checks for 40+ issue patterns including SQL injection, XSS, race conditions, performance bottlenecks
- 🚀 **Simple Usage**: Just use `/review-gitlab-mr <project_name> <mr_number>`

## Quick Start

### Automated Installation (Recommended)

The easiest way to install - just run the installation script:

```bash
# 1. Clone the repository
git clone https://github.com/hosseinSafari/gitlab-mr-mcp.git
cd gitlab-mr-mcp

# 2. Run the installation script
./install.sh
```

The script will:
- ✅ Prompt you for your GitLab Personal Access Token
- ✅ Automatically configure environment variables
- ✅ Copy the plugin to Claude Code
- ✅ Install Python dependencies
- ✅ Verify the installation

**After installation:**
1. Restart your terminal
2. Restart Claude Code
3. Type `/help` to see the `/review-gitlab-mr` command

### Manual Installation

If you prefer to install manually:

<details>
<summary>Click to expand manual installation steps</summary>

#### 1. Clone and Copy Plugin

```bash
# Clone the repository
git clone https://github.com/hosseinSafari/gitlab-mr-mcp.git
cd gitlab-mr-mcp

# Copy plugin to Claude Code plugins directory
cp -r plugins/gitlab-mr-review ~/.claude/plugins/

# Install Python dependencies
cd ~/.claude/plugins/gitlab-mr-review/server
pip install -e .
```

#### 2. Get Your GitLab Personal Access Token

1. Log in to GitLab (gitlab.com or your self-hosted instance)
2. Go to **Settings** → **Access Tokens** → **Personal Access Tokens**
3. Click **Add new token**
4. Configure:
   - **Token name**: "Claude Code MR Review"
   - **Scopes**: Check **`read_api`** (minimum required)
   - **Expiration**: Set according to your policy
5. Click **Create personal access token**
6. **Copy the token immediately** (you won't see it again!)

#### 3. Set Environment Variables

Add to your shell configuration (`~/.zshrc` or `~/.bashrc`):

```bash
# GitLab MCP Configuration
export GITLAB_PERSONAL_ACCESS_TOKEN="glpat-your-token-here"
export GITLAB_API_URL="https://gitlab.com/api/v4"
```

For self-hosted GitLab:
```bash
export GITLAB_API_URL="https://your-gitlab-instance.com/api/v4"
```

Apply the changes:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

#### 4. Restart Claude Code

Completely quit and relaunch Claude Code for the plugin to load.

</details>

### Usage

Review any merge request with a simple slash command:

```bash
/review-gitlab-mr project-name mr-number
```

**Examples:**
```bash
/review-gitlab-mr gitlab-mr-mcp 42
/review-gitlab-mr my-team/backend-api 123
```

The plugin will:
1. Find your project by name
2. Retrieve all changed files
3. Fetch all diffs in parallel
4. Analyze for security, bugs, performance, and quality issues
5. Generate a comprehensive severity-categorized report

## What Gets Analyzed

### 🔴 Critical Issues (Security)
- SQL injection vulnerabilities
- Cross-Site Scripting (XSS)
- Command injection
- Hardcoded secrets/tokens/passwords
- Authentication bypasses
- Path traversal vulnerabilities
- Insecure deserialization
- And more...

### 🟠 High Priority Issues (Bugs)
- Null reference errors
- Race conditions
- Resource leaks
- Incorrect error handling
- Logic errors
- Type mismatches
- Off-by-one errors
- And more...

### 🟡 Medium Priority Issues (Performance)
- N+1 query problems
- Inefficient algorithms
- Missing database indices
- Memory leaks
- Unnecessary synchronous operations
- Missing pagination
- And more...

### 🟢 Low Priority Issues (Code Quality)
- Code duplication
- High complexity
- Poor naming conventions
- Magic numbers
- Inconsistent style
- Missing documentation
- And more...

## Example Report

```markdown
# Merge Request Review: Add user authentication

**Project**: my-app
**MR Number**: 42
**Files Analyzed**: 8 files
**Total Issues Found**: 12 issues

---

## 🔴 Critical Issues

**File**: src/auth/login.py:45
**Issue**: Potential SQL injection vulnerability
**Impact**: User input directly concatenated into SQL query
**Recommendation**: Use parameterized queries or ORM

---

## 🟠 High Priority Issues

**File**: src/utils/validator.py:23
**Issue**: Missing null check before string operation
**Impact**: Potential NullReferenceError at runtime
**Recommendation**: Add null validation before accessing properties

---

## ✅ Positive Observations

- Excellent test coverage for authentication flow
- Clear documentation in README
- Consistent code style throughout

---

## 📋 Summary & Recommendations

**Overall Assessment**: REQUEST CHANGES

**Key Actions Required**:
1. Fix SQL injection vulnerability in login.py
2. Add null checks in validator.py
...
```

## Architecture

```
┌─────────────────┐
│  Claude Code    │
│  /review-mr     │
└────────┬────────┘
         │
         │ Uses MCP tools
         │
┌────────▼────────────────────┐
│   GitLab MCP Server         │
│  - get_projects()           │
│  - merge_request_changes()  │
│  - merge_request_file_diff()│
└────────┬────────────────────┘
         │
         │ HTTPS
         │
┌────────▼────────┐
│  GitLab API v4  │
└─────────────────┘
```

## Prerequisites

- **Python 3.10+**
- **GitLab Account** with API access
- **GitLab Personal Access Token** with `read_api` scope
- **Claude Code** installed

## Troubleshooting

### Command not appearing

**Problem**: `/review-gitlab-mr` doesn't show in `/help`

**Solutions**:
1. Verify plugin is installed: `ls ~/.claude/plugins/gitlab-mr-review/`
2. Check environment variables are set: `echo $GITLAB_PERSONAL_ACCESS_TOKEN`
3. Restart Claude Code completely (quit and relaunch)
4. Check debug logs: `claude --debug`

### "Error: Server not configured"

**Problem**: Environment variables not accessible

**Solutions**:
1. Verify variables are set in your shell config
2. Source your config: `source ~/.zshrc`
3. Restart your terminal
4. Restart Claude Code after setting variables

### "Failed to connect to GitLab"

**Problem**: Network or API URL issue

**Solutions**:
1. Check internet connection
2. Verify `GITLAB_API_URL` ends with `/api/v4`
3. For self-hosted: Ensure URL is accessible
4. Test manually: `curl -H "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN" $GITLAB_API_URL/projects`

### "No matching project found"

**Problem**: Project name doesn't match

**Solutions**:
1. Try full project path: `namespace/project-name`
2. Check you have access to the project in GitLab
3. Verify the exact project name

## Plugin Structure

```
plugins/gitlab-mr-review/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── .mcp.json                # MCP server configuration
├── commands/
│   └── review-gitlab-mr.md  # Slash command definition
├── server/
│   ├── gitlab.py            # MCP server implementation
│   └── pyproject.toml       # Python dependencies
└── README.md                # Plugin documentation
```

## Development

### Running the MCP Server Standalone

For development and testing:

```bash
# Install dependencies
pip install -e .

# Set environment variables
export GITLAB_PERSONAL_ACCESS_TOKEN="your-token"
export GITLAB_API_URL="https://gitlab.com/api/v4"

# Run the server
python gitlab.py
```

### Making Changes

1. Modify files in `plugins/gitlab-mr-review/`
2. Test changes by restarting Claude Code
3. Submit pull requests to improve the plugin

## Security Considerations

- ✅ Never commit tokens to version control
- ✅ Store tokens in environment variables only
- ✅ Use minimal required scopes (`read_api`)
- ✅ Set reasonable expiration dates for tokens
- ✅ All communication uses HTTPS
- ✅ No data is stored or transmitted outside GitLab API calls

## Limitations

- **Read-Only**: Plugin only reads data, no write operations
- **Project Limit**: Retrieves up to 100 projects per request
- **GitLab API v4**: Requires modern GitLab instances
- **Token Scope**: Requires minimum `read_api` scope

## Contributing

Contributions are welcome! To improve this plugin:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly with Claude Code
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details

Copyright (c) 2025 Amir Masoud Ahmadi & Hossein Safari

## Changelog

### [0.1.0] - 2025-10-22

- Initial release as Claude Code plugin
- Slash command: `/review-gitlab-mr`
- MCP tools: `get_projects`, `merge_request_changes`, `merge_request_file_diff`
- Comprehensive code review with severity categorization
- Parallel file analysis
- Support for GitLab Cloud and self-hosted instances

## Acknowledgments

- Built with [FastMCP](https://github.com/jlowin/fastmcp)
- Uses [httpx](https://www.python-httpx.org/) for async HTTP
- Implements the [Model Context Protocol](https://modelcontextprotocol.io)

---

**Made for Claude Code** - Bringing AI-powered code review to GitLab merge requests 🚀
