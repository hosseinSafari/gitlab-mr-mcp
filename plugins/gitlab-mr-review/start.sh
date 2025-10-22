#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PATH="$SCRIPT_DIR/server/.venv"

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
    
    cd "$SCRIPT_DIR/server"
    pip install -e . >&2
    
    conda deactivate
    
    echo "Installation complete!" >&2
fi

# Run the Python server
exec "$VENV_PATH/bin/python" "$@"

