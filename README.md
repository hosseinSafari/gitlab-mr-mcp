# GitLab MR Review MCP Server

A Model Context Protocol (MCP) server for reviewing GitLab merge requests using Claude Code and other MCP clients.

## Overview

This MCP server provides tools to interact with GitLab's API, enabling AI assistants to analyze merge requests, retrieve changed files, and inspect code diffs. It's designed to integrate seamlessly with Claude Code and other MCP-compatible clients for efficient code review workflows.

## Features

- **Project Discovery**: List all accessible GitLab projects
- **Merge Request Analysis**: Retrieve detailed information about merge request changes
- **File Change Inspection**: View individual file diffs with support for:
  - Modified files
  - New files
  - Deleted files
  - Renamed files
- **Flexible File Access**: Query files by index or path
- **Async HTTP Client**: Efficient connection pooling for API requests
- **Error Handling**: Comprehensive error handling with clear error messages

## Available Tools

### `get_projects()`
Retrieves all accessible GitLab projects for the authenticated user.

**Returns**: List of projects with names and IDs (up to 100 projects)

**Example Output**:
```
my-awesome-project, 12345
another-project, 67890
```

### `merge_request_changes(project_id: int, merge_request_id: int)`
Lists all changed files in a merge request with indexed file list.

**Parameters**:
- `project_id`: GitLab project ID (numeric)
- `merge_request_id`: Merge request IID (e.g., !123 → 123)

**Returns**: Formatted list of changed files with indices and status indicators

**Example Output**:
```
Merge Request: Add user authentication
Files changed: 5

0: src/auth.py (new)
1: src/models/user.py (modified)
2: tests/test_auth.py (new)
3: old_auth.py → src/legacy_auth.py (renamed)
4: deprecated.py (deleted)

Use merge_request_file_diff(project_id, merge_request_id, file_index=N) to see the diff.
```

### `merge_request_file_diff(project_id: int, merge_request_id: int, file_index: int = None, file_path: str = None)`
Retrieves the diff for a specific file in a merge request.

**Parameters**:
- `project_id`: GitLab project ID (numeric)
- `merge_request_id`: Merge request IID
- `file_index`: 0-based index from `merge_request_changes()` (optional)
- `file_path`: Full file path (optional)

**Returns**: Unified diff format for the specified file

**Note**: Provide either `file_index` or `file_path`, not both.

## Installation

### Prerequisites

- Python 3.10 or higher
- GitLab personal access token with `read_api` scope
- Access to a GitLab instance (GitLab.com or self-hosted)

### Using pip

```bash
pip install httpx mcp
```

### From Source

```bash
git clone https://github.com/yourusername/gitlab-mr-mcp.git
cd gitlab-mr-mcp
pip install -e .
```

## Configuration

### Environment Variables

The server requires two environment variables:

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `GITLAB_API_URL` | GitLab API endpoint URL | `https://gitlab.com/api/v4` | Yes |
| `GITLAB_PERSONAL_ACCESS_TOKEN` | GitLab personal access token | `glpat-xxxxxxxxxxxx` | Yes |

### Creating a GitLab Personal Access Token

1. Log in to your GitLab instance
2. Go to **Settings** → **Access Tokens**
3. Create a new token with the `read_api` scope
4. Copy the token (you won't be able to see it again)

## Usage

### With Claude Code

Add the following configuration to your Claude Code settings:

**For Claude Desktop** (`claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "gitlab": {
      "command": "python",
      "args": [
        "/path/to/gitlab-mr-mcp/gitlab.py"
      ],
      "env": {
        "GITLAB_PERSONAL_ACCESS_TOKEN": "your-gitlab-token-here",
        "GITLAB_API_URL": "https://gitlab.com/api/v4"
      }
    }
  }
}
```

**For Claude Code Plugin** (`.mcp.json`):
```json
{
  "gitlab": {
    "command": "${CLAUDE_PLUGIN_ROOT}/start.sh",
    "args": [
      "${CLAUDE_PLUGIN_ROOT}/server/gitlab.py"
    ],
    "env": {
      "GITLAB_PERSONAL_ACCESS_TOKEN": "${GITLAB_PERSONAL_ACCESS_TOKEN}",
      "GITLAB_API_URL": "${GITLAB_API_URL}"
    }
  }
}
```

### Standalone Execution

```bash
export GITLAB_API_URL="https://gitlab.com/api/v4"
export GITLAB_PERSONAL_ACCESS_TOKEN="your-token-here"

python gitlab.py
```

### Example Workflow

1. **List your projects**:
   ```
   Use the get_projects tool to see available projects
   ```

2. **Analyze a merge request**:
   ```
   Use merge_request_changes(project_id=12345, merge_request_id=42)
   ```

3. **Inspect specific file changes**:
   ```
   Use merge_request_file_diff(project_id=12345, merge_request_id=42, file_index=0)
   ```

## Development

### Project Structure

```
gitlab-mr-mcp/
├── gitlab.py              # Main MCP server implementation
├── pyproject.toml         # Project metadata and dependencies
├── LICENSE                # MIT License
├── README.md              # This file
└── plugins/
    └── gitlab-mr-review/  # Plugin-specific configuration
        ├── .mcp.json      # Claude Code plugin config
        ├── server/
        │   ├── gitlab.py  # Server implementation
        │   └── pyproject.toml
        └── examples/
            └── claude_desktop_config.json
```

### Running Tests

```bash
# Install development dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest
```

### Code Quality

The server implements:
- Type hints for all functions
- Async/await patterns for efficient I/O
- Context managers for resource management
- Comprehensive error handling
- Structured logging to stderr

## API Reference

### GitLabClient Class

Async HTTP client wrapper for GitLab API interactions.

**Methods**:
- `__aenter__()`: Initialize async HTTP client
- `__aexit__()`: Clean up client connection
- `request(url: str) -> dict[str, Any]`: Make authenticated API request

**Configuration**:
- `HTTP_TIMEOUT`: 30 seconds
- `PROJECTS_PER_PAGE`: 100 projects

## Troubleshooting

### Common Issues

**"GITLAB_API_URL environment variable is not set"**
- Solution: Set the `GITLAB_API_URL` environment variable to your GitLab API endpoint

**"GITLAB_PERSONAL_ACCESS_TOKEN environment variable is not set"**
- Solution: Create a personal access token and set it in the environment

**"GitLab API error 401: Unauthorized"**
- Solution: Verify your personal access token is valid and has the `read_api` scope

**"GitLab API error 404: Not Found"**
- Solution: Check that the project ID and merge request ID are correct

**"Failed to connect to GitLab"**
- Solution: Verify your `GITLAB_API_URL` is correct and the GitLab instance is accessible

### Debug Logging

The server logs to stderr by default. To see detailed logs:

```bash
python gitlab.py 2> debug.log
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built using [Model Context Protocol (MCP)](https://github.com/anthropics/mcp)
- Powered by [FastMCP](https://github.com/jlowin/fastmcp)
- GitLab API integration via [httpx](https://www.python-httpx.org/)

## Links

- [GitLab API Documentation](https://docs.gitlab.com/ee/api/)
- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Code Documentation](https://docs.claude.com/claude-code)

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/yourusername/gitlab-mr-mcp).
