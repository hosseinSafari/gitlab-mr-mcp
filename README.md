# GitLab MR Review MCP Server

A Model Context Protocol (MCP) server for reviewing GitLab merge requests using Claude Code and other MCP clients.

## Overview

This MCP server provides tools to interact with GitLab's API, enabling AI assistants to analyze merge requests, retrieve changed files, and inspect code diffs. It's designed to integrate seamlessly with Claude Code and other MCP-compatible clients for efficient code review workflows.

## Setup

### 1. Export Environment Variables

```bash
export GITLAB_API_URL="https://your_gitlab_uri/api/v4"
export GITLAB_PERSONAL_ACCESS_TOKEN="your-token-here"
```

**Get your GitLab token**: Settings → Access Tokens → Create token with `read_api` scope

### 2. Install in Claude

1. Type `/plugin` in Claude
2. Select **Add marketplace**
3. Paste `@https://github.com/hosseinSafari/gitlab-mr-mcp`
4. Follow the prompts to complete the plugin installation

## Usage

### Quick Command

Use the command directly:
```
/gitlab-mr-review:review-gitlab-mr MR_number Project_name
```

### Or Ask Claude

- "List my GitLab projects"
- "Review merge request !42 in project your_project_name"
- "Show me the diff for the first file in MR !42"

## Available Tools

- **`get_projects()`** - List all accessible GitLab projects
- **`merge_request_changes(project_id, merge_request_id)`** - List changed files in an MR
- **`merge_request_file_diff(project_id, merge_request_id, file_index or file_path)`** - View file diff

## Requirements

- Python 3.10+
- Dependencies: `httpx`, `mcp`

**Note:** You don't need to manually install requirements. After adding the marketplace plugin and installing it, all dependencies will be automatically installed.

## License

MIT License - see [LICENSE](LICENSE) file for details.
