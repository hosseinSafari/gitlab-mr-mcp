#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PATH="$SCRIPT_DIR/.venv"

# ============================================
# Setup function - only runs with --setup flag
# ============================================
do_setup() {
    echo "Setting up gitlab-mr-mcp..."
    
    # Check if uv is installed
    if ! command -v uv &> /dev/null; then
        echo "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi

    echo "Creating virtual environment at $VENV_PATH..."
    uv venv "$VENV_PATH" --python 3.10

    echo "Installing dependencies..."
    uv pip install -e "$SCRIPT_DIR/server" --python "$VENV_PATH/bin/python"

    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "You can now use this plugin with Claude Code."
}

# ============================================
# Handle --setup flag
# ============================================
if [ "$1" = "--setup" ]; then
    do_setup
    exit 0
fi

# ============================================
# Runtime mode - fail fast if not set up
# ============================================
if [ ! -d "$VENV_PATH" ]; then
    echo "❌ Error: Virtual environment not found." >&2
    echo "" >&2
    echo "Please run setup first:" >&2
    echo "  $0 --setup" >&2
    echo "" >&2
    exit 1
fi

# Run Python with arguments
echo "CLAUDE_PLUGIN_ROOT is $CLAUDE_PLUGIN_ROOT" >&2
exec "$VENV_PATH/bin/python" "$@"