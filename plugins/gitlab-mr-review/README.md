# GitLab MR Review Plugin

A Claude Code plugin that provides comprehensive automated code review for GitLab merge requests using MCP (Model Context Protocol) tools.

## Features

- 🔍 **Automated Code Review**: Analyzes all files in a merge request for security, bugs, performance, and code quality issues
- ⚡ **Parallel Processing**: Fetches and analyzes all file diffs in parallel for maximum efficiency
- 🎯 **Severity-Based Reporting**: Categorizes issues as Critical, High, Medium, or Low priority
- 📊 **Comprehensive Analysis**: Checks for 40+ issue patterns including SQL injection, XSS, race conditions, performance bottlenecks, and more
- 🚀 **Simple Usage**: Just use `/review-gitlab-mr <project_name> <mr_number>`

## Prerequisites

- **Python 3.10+**
- **GitLab Account** with API access
- **GitLab Personal Access Token** with `read_api` scope
- **Claude Code** (this plugin is installed within Claude Code)

## Installation

### 1. Get Your GitLab Personal Access Token

1. Log in to your GitLab account (gitlab.com or self-hosted)
2. Navigate to **Settings** → **Access Tokens** → **Personal Access Tokens**
3. Click **Add new token**
4. Configure:
   - **Name**: "Claude Code MR Review"
   - **Scopes**: Select `read_api` (minimum required)
   - **Expiration**: Set according to your security policy
5. Click **Create personal access token**
6. **Copy the token immediately** (you won't see it again)

### 2. Set Environment Variables

Set these environment variables in your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
export GITLAB_PERSONAL_ACCESS_TOKEN="your-token-here"
export GITLAB_API_URL="https://gitlab.com/api/v4"
```

For self-hosted GitLab:
```bash
export GITLAB_API_URL="https://your-gitlab-instance.com/api/v4"
```

**Apply the changes:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

### 3. Install Python Dependencies

From the plugin directory:

```bash
cd .claude/plugins/gitlab-mr-review/server
pip install -e .
```

Or install dependencies directly:
```bash
pip install httpx>=0.28.1 'mcp[cli]>=1.2.0'
```

### 4. Restart Claude Code

The plugin will be automatically loaded when Claude Code starts.

## Usage

### Basic Review

Review a merge request by project name and MR number:

```
/review-gitlab-mr my-project 42
```

This will:
1. Find the project ID from the project name
2. Retrieve all changed files in the merge request
3. Fetch all file diffs in parallel
4. Analyze each file for issues
5. Generate a comprehensive report with severity-based categorization

### What Gets Analyzed

The plugin checks for:

**🔴 Critical Issues (Security)**
- SQL injection vulnerabilities
- Cross-Site Scripting (XSS)
- Command injection
- Hardcoded secrets/tokens
- Authentication bypasses
- Path traversal
- And more...

**🟠 High Priority Issues (Bugs)**
- Null reference errors
- Race conditions
- Resource leaks
- Incorrect error handling
- Logic errors
- Type mismatches
- And more...

**🟡 Medium Priority Issues (Performance)**
- N+1 query problems
- Inefficient algorithms
- Missing database indices
- Memory leaks
- Synchronous operations that should be async
- And more...

**🟢 Low Priority Issues (Code Quality)**
- Code duplication
- High complexity
- Poor naming
- Magic numbers
- Inconsistent style
- And more...

### Example Report

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
**Recommendation**: Add null validation before accessing .length

---

## ✅ Positive Observations

- Excellent test coverage for new authentication flow
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

## How It Works

### Architecture

```
┌─────────────────┐
│  Claude Code    │
│  /review-mr     │
└────────┬────────┘
         │
         │ Expands slash command
         │
┌────────▼────────────────────┐
│   Review Workflow           │
│  1. Find project ID         │
│  2. Get file list           │
│  3. Fetch all diffs (||)    │
│  4. Analyze each file       │
│  5. Generate report         │
└────────┬────────────────────┘
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

### MCP Server

The plugin includes a lightweight MCP server (`server/gitlab.py`) that provides three tools:

1. **get_projects()** - List all accessible GitLab projects
2. **merge_request_changes(project_id, mr_id)** - Get list of changed files
3. **merge_request_file_diff(project_id, mr_id, file_index)** - Get diff for specific file

The server uses:
- **Connection pooling** for efficient API requests
- **Async architecture** for parallel operations
- **Proper error handling** with helpful messages

## Configuration

### Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `GITLAB_PERSONAL_ACCESS_TOKEN` | Yes | GitLab API token with `read_api` scope | `glpat-xxxxxxxxxxxx` |
| `GITLAB_API_URL` | Yes | GitLab API base URL with version | `https://gitlab.com/api/v4` |

### Advanced Configuration

You can customize the MCP server behavior by modifying constants in `server/gitlab.py`:

```python
HTTP_TIMEOUT = 30.0          # API request timeout in seconds
PROJECTS_PER_PAGE = 100      # Number of projects retrieved per request
```

## Troubleshooting

### "Error: Server not configured"

**Cause**: Environment variables not set or not accessible

**Solution**:
1. Verify environment variables are set: `echo $GITLAB_PERSONAL_ACCESS_TOKEN`
2. Restart your terminal to reload environment
3. Restart Claude Code

### "Error: Failed to connect to GitLab"

**Cause**: Network issue or incorrect API URL

**Solution**:
1. Check your internet connection
2. Verify `GITLAB_API_URL` is correct
3. For self-hosted: Ensure you can access the URL in browser
4. Check if GitLab is behind VPN/firewall

### "Error: No matching project found"

**Cause**: Project name doesn't match any accessible projects

**Solution**:
1. Check the exact project name in GitLab
2. Try using the full path (e.g., "username/project-name")
3. Verify you have access to the project

### Token Expired

**Cause**: GitLab personal access token has expired

**Solution**:
1. Create a new token in GitLab
2. Update `GITLAB_PERSONAL_ACCESS_TOKEN` environment variable
3. Restart Claude Code

## Limitations

- **Read-Only**: Plugin only reads data, no write operations
- **Project Limit**: Retrieves up to 100 projects per request
- **GitLab API v4**: Requires modern GitLab instances supporting API v4
- **Token Scope**: Requires minimum `read_api` scope

## Security Considerations

- ✅ Never commit tokens to version control
- ✅ Store tokens in environment variables only
- ✅ Use minimal required scopes (`read_api`)
- ✅ Set reasonable expiration dates for tokens
- ✅ All communication uses HTTPS
- ✅ No data is stored or transmitted outside GitLab API calls

## Contributing

Contributions are welcome! To improve this plugin:

1. Fork the repository
2. Create a feature branch
3. Make your improvements
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Changelog

### [0.1.0] - 2025-10-22

- Initial release
- Slash command: `/review-gitlab-mr`
- MCP tools: `get_projects`, `merge_request_changes`, `merge_request_file_diff`
- Comprehensive code review with severity categorization
- Parallel file analysis
- Support for GitLab Cloud and self-hosted instances

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Check the troubleshooting section above
- Review MCP documentation: https://modelcontextprotocol.io

---

**Made for Claude Code** - Bringing AI-powered code review to GitLab merge requests
