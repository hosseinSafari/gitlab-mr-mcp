#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PATH="$SCRIPT_DIR/.venv"

# Source shell configuration (optional)
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null || true
elif [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || true
elif [ -f "$HOME/.bash_profile" ]; then
    source "$HOME/.bash_profile" 2>/dev/null || true
fi
# Only install if venv doesn't exist
if [ ! -d "$VENV_PATH" ]; then
    echo "The script directory is $SCRIPT_DIR" >&2
    echo "Creating virtual environment at $VENV_PATH..." >&2

    conda create -p "$VENV_PATH" python=3.10 -y >&2

    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "$VENV_PATH"

    # cd "$SCRIPT_DIR/server"
    pip install -e $SCRIPT_DIR/server >&2

    conda deactivate
    echo "Setup complete." >&2
fi

# Run Python with arguments
echo "CLAUDE_PLUGIN_ROOT is $CLAUDE_PLUGIN_ROOT" >&2
exec "$VENV_PATH/bin/python" "$@"