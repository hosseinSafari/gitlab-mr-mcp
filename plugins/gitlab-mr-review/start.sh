#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PATH="$SCRIPT_DIR/server/.venv"

# Source shell configuration to pick up exported environment variables
# Try common shell config files
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null || true
elif [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || true
elif [ -f "$HOME/.bash_profile" ]; then
    source "$HOME/.bash_profile" 2>/dev/null || true
fi

# Check if virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
    echo "Virtual environment not found. Installing..." >&2
    
    # Check if conda is available
    if ! command -v conda &> /dev/null; then
        echo "Error: conda is not installed or not in PATH" >&2
        exit 1
    fi
    
    # Create conda environment
    conda create -p "$VENV_PATH" python=3.10 -y >&2
    
    # Activate and install dependencies
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "$VENV_PATH"

    # Install dependencies using the venv's pip
    "$VENV_PATH/bin/python" -m pip install -e "$SCRIPT_DIR/server" >&2

    conda deactivate
    
    echo "Installation complete!" >&2
fi

# Run the Python server with inherited environment variables
exec "$VENV_PATH/bin/python" "$@"

