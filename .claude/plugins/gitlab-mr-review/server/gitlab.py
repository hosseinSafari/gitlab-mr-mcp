"""GitLab MCP Server for Merge Request Analysis."""

from typing import Any, Optional
import httpx
import os
import json
import logging
from mcp.server.fastmcp import FastMCP

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration constants
HTTP_TIMEOUT = 30.0
PROJECTS_PER_PAGE = 100


def validate_config() -> tuple[str, str]:
    """Validate and return GitLab configuration from environment."""
    api_url = os.getenv("GITLAB_API_URL")
    token = os.getenv("GITLAB_PERSONAL_ACCESS_TOKEN")

    if not api_url:
        raise ValueError(
            "GITLAB_API_URL environment variable is not set. "
            "Set it to your GitLab API URL (e.g., https://gitlab.com/api/v4)"
        )

    if not token:
        raise ValueError(
            "GITLAB_PERSONAL_ACCESS_TOKEN environment variable is not set. "
            "Provide a valid GitLab personal access token with 'read_api' scope."
        )

    return api_url, token


class GitLabClient:
    """Async HTTP client for GitLab API with connection pooling."""

    def __init__(self, api_url: str, token: str):
        self.api_url = api_url
        self._client: Optional[httpx.AsyncClient] = None
        self._headers = {"PRIVATE-TOKEN": token}

    async def __aenter__(self):
        self._client = httpx.AsyncClient(headers=self._headers, timeout=HTTP_TIMEOUT)
        return self

    async def __aexit__(self, _exc_type, _exc_val, _exc_tb):
        if self._client:
            await self._client.aclose()
            self._client = None

    async def request(self, url: str) -> dict[str, Any]:
        """Make API request with error handling."""
        if not self._client:
            raise RuntimeError("Client not initialized. Use async context manager.")

        try:
            response = await self._client.get(url)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise RuntimeError(
                f"GitLab API error {e.response.status_code}: {e.response.reason_phrase}"
            ) from e
        except httpx.RequestError as e:
            raise RuntimeError(f"Failed to connect to GitLab: {str(e)}") from e


# Initialize MCP server and config
mcp = FastMCP("gitlab")

try:
    API_URL, TOKEN = validate_config()
    logger.info(f"Configuration loaded: {API_URL}")
except ValueError as e:
    logger.error(f"Configuration error: {e}")
    API_URL, TOKEN = None, None


@mcp.tool()
async def get_projects() -> str:
    """Get all accessible GitLab projects."""
    if not API_URL or not TOKEN:
        return "Error: Server not configured. Set GITLAB_API_URL and GITLAB_PERSONAL_ACCESS_TOKEN."

    try:
        async with GitLabClient(API_URL, TOKEN) as client:
            url = f"{API_URL}/projects?simple=true&per_page={PROJECTS_PER_PAGE}"
            data = await client.request(url)

            # Handle response format variations
            projects = data if isinstance(data, list) else data.get("projects", [])

            if not projects:
                return "No projects found."

            lines = []
            for p in projects:
                name = p.get("name") or p.get("name_with_namespace") or "Unnamed"
                lines.append(f"{name}, {p.get('id')}")

            result = "\n".join(lines)

            if len(projects) >= PROJECTS_PER_PAGE:
                result += f"\n\nNote: Showing first {PROJECTS_PER_PAGE} projects."

            logger.info(f"Retrieved {len(projects)} projects")
            return result

    except Exception as e:
        logger.error(f"get_projects failed: {e}")
        return f"Error: {str(e)}"


@mcp.tool()
async def merge_request_changes(project_id: int, merge_request_id: int) -> str:
    """
    Get list of changed files in a merge request.

    Returns a simple list of files with indices for use with merge_request_file_diff.
    Args:
        project_id: GitLab project ID (numeric)
        merge_request_id: MR IID (e.g., !123 -> 123)
    """
    if not API_URL or not TOKEN:
        return "Error: Server not configured. Set GITLAB_API_URL and GITLAB_PERSONAL_ACCESS_TOKEN."

    try:
        async with GitLabClient(API_URL, TOKEN) as client:
            url = f"{API_URL}/projects/{project_id}/merge_requests/{merge_request_id}/changes"
            data = await client.request(url)

            changes = data.get("changes", [])

            if not isinstance(changes, list):
                return "Error: Unexpected response structure from GitLab."

            if not changes:
                return "This merge request has no file changes."

            # Build simple file list
            title = data.get("title", "No title")
            lines = [
                f"Merge Request: {title}",
                f"Files changed: {len(changes)}",
                ""
            ]

            for idx, change in enumerate(changes):
                old_path = change.get("old_path")
                new_path = change.get("new_path")
                new_file = change.get("new_file", False)
                deleted_file = change.get("deleted_file", False)
                renamed_file = change.get("renamed_file", False)

                # Determine status and display
                if renamed_file:
                    display = f"{old_path} → {new_path} (renamed)"
                elif new_file:
                    display = f"{new_path} (new)"
                elif deleted_file:
                    display = f"{old_path} (deleted)"
                else:
                    display = f"{new_path or old_path} (modified)"

                lines.append(f"{idx}: {display}")

            lines.append("")
            lines.append("Use merge_request_file_diff(project_id, merge_request_id, file_index=N) to see the diff.")

            logger.info(f"Returning file list for MR with {len(changes)} changes")
            return "\n".join(lines)

    except Exception as e:
        logger.error(f"merge_request_changes failed: {e}")
        return f"Error: {str(e)}"


@mcp.tool()
async def merge_request_file_diff(
    project_id: int,
    merge_request_id: int,
    file_index: Optional[int] = None,
    file_path: Optional[str] = None
) -> str:
    """
    Get diff for a specific file in a merge request.

    Provide either file_index (0-based index) or file_path.
    """
    if not API_URL or not TOKEN:
        return "Error: Server not configured. Set GITLAB_API_URL and GITLAB_PERSONAL_ACCESS_TOKEN."

    if file_index is None and file_path is None:
        return "Error: Provide either file_index or file_path parameter."

    try:
        async with GitLabClient(API_URL, TOKEN) as client:
            url = f"{API_URL}/projects/{project_id}/merge_requests/{merge_request_id}/changes"
            data = await client.request(url)

            changes = data.get("changes", [])

            if not isinstance(changes, list) or not changes:
                return "Error: No file changes in this merge request."

            # Find the requested file
            entry = None

            if file_index is not None:
                if 0 <= file_index < len(changes):
                    entry = changes[file_index]
                else:
                    return f"Error: file_index {file_index} out of range (0-{len(changes)-1})"
            else:
                # Search by path
                for change in changes:
                    if change.get("new_path") == file_path or change.get("old_path") == file_path:
                        entry = change
                        break

                if not entry:
                    return f"Error: No file found with path: {file_path}"

            diff_text = entry.get("diff")

            if not diff_text:
                # No diff available, return JSON
                return json.dumps(entry, indent=2)

            # Return full diff
            display_path = entry.get("new_path") or entry.get("old_path") or "unknown"
            logger.info(f"Returning diff for {display_path}")

            return diff_text

    except Exception as e:
        logger.error(f"merge_request_file_diff failed: {e}")
        return f"Error: {str(e)}"


def main():
    """Run the MCP server."""
    if not API_URL or not TOKEN:
        logger.warning("Server starting without valid configuration.")

    mcp.run(transport='stdio')


if __name__ == "__main__":
    main()
