conda create --prefix ./.venv python=3.10
pip install .

{
    "command": "/Users/Hossein/Documents/projects/custom_gitlab_mcp/.venv/bin/python",
    "args": [
    "/Users/Hossein/Documents/projects/custom_gitlab_mcp/gitlab.py"
    ],
    "env": {
    "GITLAB_PERSONAL_ACCESS_TOKEN": "YOUR_TOKEN",
    "GITLAB_API_URL": "YOUR_GITLAB_URI/api/v4"
    }
}