# GitLab MR MCP Server

A Model Context Protocol (MCP) server that provides programmatic access to GitLab merge requests, enabling AI assistants like Claude to review and analyze code changes.

[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MCP](https://img.shields.io/badge/MCP-1.2.0+-green.svg)](https://modelcontextprotocol.io)

## Overview

This MCP server integrates with GitLab's API to provide three powerful tools for merge request analysis:

- **Project Discovery**: List all accessible GitLab projects
- **MR Changes Summary**: Get intelligent summaries of merge request changes
- **File Diff Retrieval**: Examine detailed diffs for specific files

The server automatically handles large merge requests by providing smart summaries and supports granular file-by-file inspection.

## Features

- **Intelligent Response Sizing**: Automatically summarizes large merge requests (>50 files or >200KB) to avoid overwhelming context windows
- **Flexible File Selection**: Retrieve diffs by file index or exact path
- **Async Architecture**: Built on modern async Python for efficient I/O operations
- **Smart Truncation**: Large diffs (>150KB) are automatically truncated with clear indicators
- **GitLab Cloud & Self-Hosted**: Works with both gitlab.com and self-hosted GitLab instances
- **Secure**: Token-based authentication with environment variable configuration

## Installation

### Prerequisites

- Python 3.10 or higher
- GitLab account with API access
- Personal Access Token with appropriate scopes (minimum: `read_api`)

### Setup

1. **Clone the repository**

```bash
git clone <repository-url>
cd gitlab-mr-mcp
```

2. **Create a virtual environment**

Using conda:
```bash
conda create --prefix ./.venv python=3.10
conda activate ./.venv
```

Or using venv:
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

3. **Install the package**

```bash
pip install .
```

4. **Configure environment variables**

Create a `.env` file or set environment variables:

```bash
export GITLAB_PERSONAL_ACCESS_TOKEN="your-token-here"
export GITLAB_API_URL="https://gitlab.com/api/v4"
```

For self-hosted GitLab:
```bash
export GITLAB_API_URL="https://your-gitlab-instance.com/api/v4"
```

### Getting a GitLab Personal Access Token

1. Log in to your GitLab account
2. Navigate to **Settings** > **Access Tokens** > **Personal Access Tokens**
3. Click **Add new token**
4. Configure the token:
   - **Name**: "MCP Server" (or any descriptive name)
   - **Scopes**: Select `read_api` (minimum required)
   - **Expiration date**: Set according to your security policy
5. Click **Create personal access token**
6. Copy the token immediately (it won't be shown again)

## Configuration

### Claude Desktop Integration

Add the following configuration to your Claude Desktop settings:

**Location**:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

**Configuration**:

```json
{
  "mcpServers": {
    "gitlab": {
      "command": "/path/to/your/project/.venv/bin/python",
      "args": [
        "/path/to/your/project/gitlab.py"
      ],
      "env": {
        "GITLAB_PERSONAL_ACCESS_TOKEN": "your-token-here",
        "GITLAB_API_URL": "https://gitlab.com/api/v4"
      }
    }
  }
}
```

**Important**: Replace the paths with your actual project location:
- `/path/to/your/project/.venv/bin/python` → Your virtual environment's Python executable
- `/path/to/your/project/gitlab.py` → Your gitlab.py file location

After updating the configuration, restart Claude Desktop.

## Usage

### Available MCP Tools

Once configured, the following tools are available to Claude:

#### 1. `get_projects()`

List all accessible GitLab projects.

**Returns**: Formatted list of projects with IDs

**Example output**:
```
My Project, 12345
Another Project, 67890
Team Repository, 11111
```

#### 2. `merge_request_changes(project_id: int, merge_request_id: int)`

Retrieve all changes in a merge request with intelligent summarization.

**Parameters**:
- `project_id` (int): GitLab project ID
- `merge_request_id` (int): Merge request IID (internal ID shown in GitLab UI)

**Returns**:
- **Small MRs** (<50 files, <200KB): Full JSON with all details
- **Large MRs**: Formatted summary with top 20 files by change size

**Example output** (large MR):
```
Merge Request: Add user authentication system
Author: John Doe
URL: https://gitlab.com/project/repo/-/merge_requests/123
Created: 2025-01-15T10:30:00Z
Updated: 2025-01-16T14:20:00Z

Top 20 changed files (sorted by diff size):
0: src/auth/oauth.py (+145/-12, 8234 bytes)
1: src/models/user.py (+89/-5, 5621 bytes)
2: tests/test_auth.py (+234/-0, 4512 bytes)
...

Use merge_request_file_diff(project_id, merge_request_id, file_index=N)
to get the full diff for a specific file.
```

#### 3. `merge_request_file_diff(project_id: int, merge_request_id: int, file_index: int | None = None, file_path: str | None = None)`

Get detailed diff for a specific file in a merge request.

**Parameters**:
- `project_id` (int): GitLab project ID
- `merge_request_id` (int): Merge request IID
- `file_index` (int, optional): 0-based index from changes summary
- `file_path` (str, optional): Exact file path (old or new)

**Note**: You must provide either `file_index` OR `file_path`.

**Returns**: Unified diff format or JSON if diff unavailable

**Example usage**:
```
By index: merge_request_file_diff(12345, 42, file_index=0)
By path: merge_request_file_diff(12345, 42, file_path="src/auth/oauth.py")
```

### Workflow Example

1. **Discover projects**:
   ```
   "List my GitLab projects"
   → Claude calls get_projects()
   ```

2. **Get MR overview**:
   ```
   "Show me the changes in MR #42 for project 12345"
   → Claude calls merge_request_changes(12345, 42)
   ```

3. **Examine specific file**:
   ```
   "Show me the full diff for the first file"
   → Claude calls merge_request_file_diff(12345, 42, file_index=0)
   ```

## Architecture

### Component Overview

```
┌─────────────────┐
│  Claude Desktop │
│   (MCP Client)  │
└────────┬────────┘
         │ MCP Protocol (stdio)
         │
┌────────▼────────────────────┐
│   GitLab MR MCP Server      │
│  ┌──────────────────────┐   │
│  │  FastMCP Framework   │   │
│  └──────────────────────┘   │
│  ┌──────────────────────┐   │
│  │  Tool: get_projects  │   │
│  │  Tool: mr_changes    │   │
│  │  Tool: file_diff     │   │
│  └──────────────────────┘   │
│  ┌──────────────────────┐   │
│  │   HTTP Client        │   │
│  │   (httpx async)      │   │
│  └──────────────────────┘   │
└────────┬────────────────────┘
         │ HTTPS
         │
┌────────▼────────┐
│   GitLab API    │
│   (v4 REST)     │
└─────────────────┘
```

### Key Technologies

- **FastMCP**: Modern MCP server framework with decorator-based tool registration
- **httpx**: Async HTTP client for GitLab API communication
- **Python 3.10+**: Leverages modern async/await syntax and type hints
- **stdio transport**: Standard input/output for MCP communication

### Response Size Management

The server implements intelligent response sizing:

1. **Small responses** (<200KB AND <50 files):
   - Return complete JSON with all file changes
   - Includes full metadata and diffs

2. **Large responses**:
   - Generate compact summary with MR metadata
   - List top 20 files sorted by change size
   - Provide file indices for granular retrieval
   - Include usage instructions for `merge_request_file_diff`

3. **Individual file diffs**:
   - Truncate diffs exceeding 150KB
   - Clearly indicate truncation with byte count

## Configuration Reference

### Environment Variables

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `GITLAB_PERSONAL_ACCESS_TOKEN` | GitLab API authentication token | Yes | `glpat-xxxxxxxxxxxx` |
| `GITLAB_API_URL` | GitLab API base URL with version | Yes | `https://gitlab.com/api/v4` |

### Internal Limits

These constants are defined in `gitlab.py` and can be modified if needed:

| Constant | Default | Purpose |
|----------|---------|---------|
| `MAX_SERIALIZED_BYTES` | 200,000 | Maximum response size before summarization |
| `MAX_FILES_IN_FULL_RETURN` | 50 | Maximum files before summarization |
| `TOP_N_FILES` | 20 | Number of files shown in summary |
| HTTP Timeout | 30 seconds | GitLab API request timeout |
| Projects per page | 100 | Number of projects retrieved |

## Troubleshooting

### Common Issues

**"Environment variables not set"**
- Ensure `GITLAB_PERSONAL_ACCESS_TOKEN` and `GITLAB_API_URL` are configured
- Check the environment variables in your Claude Desktop config
- Verify the token hasn't expired

**"Failed to retrieve projects"**
- Verify your token has `read_api` scope
- Check the GitLab API URL is correct (include `/api/v4`)
- Test connectivity to your GitLab instance

**"Could not retrieve MR changes"**
- Verify the project ID is correct (numeric ID, not project name)
- Ensure the MR ID exists in that project
- Check you have access permissions to the project

**"No diff available"**
- Some files may not have diffs (binary files, renamed files)
- The tool will return JSON serialization as fallback

**Large diffs are truncated**
- Diffs over 150KB are automatically truncated
- This is by design to prevent overwhelming the context window
- The truncation includes a notice with the original size

### Getting Help

- Check the [MCP documentation](https://modelcontextprotocol.io)
- Review GitLab API v4 documentation
- Examine server logs (stdout/stderr from the Python process)

## Development

### Running Tests

```bash
# Install development dependencies (if any)
pip install -e ".[dev]"

# Run tests (add test framework as needed)
pytest
```

### Code Structure

```
gitlab-mr-mcp/
├── gitlab.py           # Main server implementation
├── pyproject.toml      # Project configuration and dependencies
├── README.md           # This file
└── LICENSE             # MIT License
```

### Making Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test with Claude Desktop
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## Security Considerations

- **Token Storage**: Never commit tokens to version control
- **Environment Variables**: Store sensitive data in environment variables only
- **Token Scopes**: Use minimal required scopes (`read_api` is sufficient)
- **Token Expiration**: Set reasonable expiration dates for tokens
- **HTTPS**: Always use HTTPS for GitLab API communication
- **Timeouts**: 30-second timeout prevents hanging requests

## Limitations

- **Project Limit**: Currently retrieves up to 100 projects per request
- **Response Size**: Large responses (>200KB) are summarized
- **Diff Truncation**: Individual diffs over 150KB are truncated
- **GitLab API v4**: Requires GitLab API v4 (modern GitLab instances)
- **Read-Only**: This server only reads data, no write operations

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Hossein Safari

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Built with [FastMCP](https://github.com/jlowin/fastmcp)
- Uses [httpx](https://www.python-httpx.org/) for async HTTP
- Implements the [Model Context Protocol](https://modelcontextprotocol.io)

## Changelog

### [0.1.0] - 2025-01-21

- Initial release
- Three core tools: `get_projects`, `merge_request_changes`, `merge_request_file_diff`
- Intelligent response sizing for large MRs
- Support for GitLab Cloud and self-hosted instances
