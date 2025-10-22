#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PATH="$SCRIPT_DIR/server/.venv"

# Source shell configuration (optional)
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null || true
elif [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || true
elif [ -f "$HOME/.bash_profile" ]; then
    source "$HOME/.bash_profile" 2>/dev/null || true
fi

echo "Creating virtual environment at $VENV_PATH..."
conda create -p "$VENV_PATH" python=3.10 -y >&2

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$VENV_PATH"

cd "$SCRIPT_DIR/server"
echo "Installing packages from ./server..."
pip install -e . >&2

conda deactivate
echo "Setup complete."

# Run Python with arguments
exec "$VENV_PATH/bin/python" "$@"
