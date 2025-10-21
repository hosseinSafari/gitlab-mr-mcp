from typing import Any
import httpx
import os
import json
import urllib.parse
from mcp.server.fastmcp import FastMCP

# Initialize FastMCP server
mcp = FastMCP("gitlab")

# Constants
GITLAB_API_BASE = os.getenv("GITLAB_API_URL")

async def make_gitlab_request(url: str) -> dict[str, Any] | None:
    """Make a request to the GITLAB API with proper error handling."""
    token = os.getenv("GITLAB_PERSONAL_ACCESS_TOKEN")
    if not token:
        raise ValueError("GITLAB_PERSONAL_ACCESS_TOKEN environment variable is not set")
    if not GITLAB_API_BASE:
        raise ValueError("GITLAB_API_URL environment variable is not set")
    
    headers = {
        "PRIVATE-TOKEN": token
    }
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url, headers=headers, timeout=30.0)
            response.raise_for_status()
            return response.json()
        except Exception:
            return None

@mcp.tool()
async def get_projects() -> str:
    """Get projects from GitLab."""
    url = f"{GITLAB_API_BASE}/projects?simple=true&per_page=100"
    data = await make_gitlab_request(url)

    if not data:
        return "Unable to fetch projects."

    projects = data if isinstance(data, list) else data.get("projects", [])

    if not projects:
        return "No projects found."

    lines = []
    for project in projects:
        project_id = project.get("id")
        project_name = project.get("name") or project.get("name_with_namespace") or "Unnamed project"
        lines.append(f"{project_name}, {project_id}")
    
    return "\n".join(lines)


# Configuration for trimming
MAX_SERIALIZED_BYTES = 200_000   # rough limit on JSON bytes returned by the tool (adjust to fit mcp limits)
MAX_FILES_IN_FULL_RETURN = 50    # if more files changed than this, return summary instead
TOP_N_FILES = 20                 # show top N files in the summary


@mcp.tool()
async def merge_request_changes(project_id: int, merge_request_id: int) -> str:
    """Get merge request changes from GitLab, but return a compact summary when large.

    Returns:
      - small summary (title, author, web_url, number of changed files, top N files)
      - instructions for fetching full diff for a specific file: use tool `merge_request_file_diff`
    """
    # Use numeric project id. If you ever pass a namespace, encode it:
    project_encoded = urllib.parse.quote_plus(str(project_id))
    url = f"{GITLAB_API_BASE}/projects/{project_encoded}/merge_requests/{merge_request_id}/changes"
    data = await make_gitlab_request(url)

    if not data:
        return "Unable to fetch merge request changes."

    # The endpoint returns a dict with keys like title, description, changes (list)
    changes = data.get("changes", [])
    mr_title = data.get("title", "<no title>")
    mr_author = data.get("author", {}).get("name", "<unknown>")
    mr_web_url = data.get("web_url", "")
    created_at = data.get("created_at", "")
    updated_at = data.get("updated_at", "")

    # Quick check: if changes is empty, maybe endpoint returned something else
    if not isinstance(changes, list):
        return "Unexpected response structure from GitLab."

    # Prepare file summaries (path, additions/deletions if present, and size of diff text)
    file_summaries = []
    for idx, ch in enumerate(changes):
        old_path = ch.get("old_path") or ch.get("old_path")
        new_path = ch.get("new_path") or ch.get("new_path")
        path = new_path or old_path or f"<unknown path {idx}>"
        # GitLab changes often include 'diff' field, and sometimes additions/deletions (depending on API)
        diff_text = ch.get("diff") or ""
        additions = ch.get("additions")
        deletions = ch.get("deletions")
        # approximate number of changed lines in this file
        approx_change_size = len(diff_text)
        file_summaries.append({
            "index": idx,
            "path": path,
            "additions": additions,
            "deletions": deletions,
            "diff_bytes": approx_change_size
        })

    total_files = len(file_summaries)
    total_diff_bytes = sum(f["diff_bytes"] for f in file_summaries)

    # If response is small enough, return the full JSON (pretty)
    serialized_full = json.dumps(data, indent=2)
    if len(serialized_full.encode("utf-8")) <= MAX_SERIALIZED_BYTES and total_files <= MAX_FILES_IN_FULL_RETURN:
        return serialized_full

    # Otherwise, produce a compact summary and instructions for retrieval of specific file diffs
    # Sort files by diff size desc to show biggest changes first
    file_summaries.sort(key=lambda x: x["diff_bytes"], reverse=True)

    lines = []
    lines.append(f"MR {merge_request_id} — {mr_title}")
    lines.append(f"Author: {mr_author}")
    if mr_web_url:
        lines.append(f"URL: {mr_web_url}")
    if created_at:
        lines.append(f"Created at: {created_at}")
    if updated_at:
        lines.append(f"Updated at: {updated_at}")
    lines.append(f"Files changed: {total_files}")
    lines.append(f"Approx. total diff bytes: {total_diff_bytes:,}")
    lines.append("")
    lines.append(f"Top {min(TOP_N_FILES, total_files)} changed files (index, path, approx diff bytes, additions, deletions):")
    for fs in file_summaries[:TOP_N_FILES]:
        lines.append(f"{fs['index']}: {fs['path']}  ({fs['diff_bytes']} bytes, +{fs.get('additions') or '?'} -{fs.get('deletions') or '?'})")

    lines.append("")
    lines.append("Notes:")
    lines.append("- The full MR changes were too large to return in one tool response.")
    lines.append("- To fetch the full diff for a specific file, call the MCP tool `merge_request_file_diff` with the project_id, merge_request_id, and either `file_index` (the index shown) or the `file_path`.")
    lines.append("- Example: merge_request_file_diff(project_id=24, merge_request_id=871, file_index=3)")

    return "\n".join(lines)


@mcp.tool()
async def merge_request_file_diff(project_id: int, merge_request_id: int, file_index: int | None = None, file_path: str | None = None) -> str:
    """Return the diff for a single changed file from the merge request changes payload.

    Provide *either* file_index (0-based index shown in the summary) or file_path.
    """
    if file_index is None and file_path is None:
        return "You must provide either file_index or file_path."

    project_encoded = urllib.parse.quote_plus(str(project_id))
    url = f"{GITLAB_API_BASE}/projects/{project_encoded}/merge_requests/{merge_request_id}/changes"
    data = await make_gitlab_request(url)
    if not data:
        return "Unable to fetch merge request changes."

    changes = data.get("changes", [])
    if not isinstance(changes, list) or not changes:
        return "No file changes present for this merge request."

    # Find the file entry
    entry = None
    if file_index is not None:
        if not (0 <= file_index < len(changes)):
            return f"file_index out of range (0..{len(changes)-1})"
        entry = changes[file_index]
    else:
        # find by path (match new_path or old_path)
        for ch in changes:
            path = ch.get("new_path") or ch.get("old_path") or ""
            if path == file_path:
                entry = ch
                break
        if entry is None:
            return f"No changed file found with path: {file_path}"

    diff_text = entry.get("diff")
    if not diff_text:
        # sometimes the endpoint gives 'a_mode'/'b_mode' and no unified diff; return serialized entry
        return json.dumps(entry, indent=2)

    # If the diff is still huge, return only head of diff and a suggestion
    MAX_BYTES_FOR_SINGLE_DIFF = 150_000
    diff_bytes = len(diff_text.encode("utf-8"))
    if diff_bytes > MAX_BYTES_FOR_SINGLE_DIFF:
        head = diff_text[:MAX_BYTES_FOR_SINGLE_DIFF]
        tail_notice = f"\n\n--- diff truncated: {diff_bytes} bytes total. To inspect the rest, consider fetching from the repo directly or reducing the requested chunk. ---"
        return head + tail_notice

    return diff_text


def main():
    # Initialize and run the server
    mcp.run(transport='stdio')    

if __name__ == "__main__":
    main()
