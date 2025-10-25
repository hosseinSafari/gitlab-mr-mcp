#!/bin/bash
set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PATH="$SCRIPT_DIR/server/.venv"
PYTHON_BIN="$VENV_PATH/bin/python"

# Function to create venv using standard Python
create_venv_standard() {
    echo "Creating virtual environment using standard Python venv..." >&2

    # Try to find a suitable Python version
    PYTHON_CMD=""
    for cmd in python3.12 python3.11 python3.10 python3 python; do
        if command -v "$cmd" &> /dev/null; then
            VERSION=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
            MAJOR=$(echo "$VERSION" | cut -d. -f1)
            MINOR=$(echo "$VERSION" | cut -d. -f2)

            # Check if Python >= 3.10
            if [ "$MAJOR" -eq 3 ] && [ "$MINOR" -ge 10 ]; then
                PYTHON_CMD="$cmd"
                echo "Found suitable Python: $cmd (version $VERSION)" >&2
                break
            fi
        fi
    done

    if [ -z "$PYTHON_CMD" ]; then
        echo "Error: Python 3.10 or higher is required but not found" >&2
        echo "Please install Python 3.10+ or conda" >&2
        exit 1
    fi

    # Create virtual environment
    "$PYTHON_CMD" -m venv "$VENV_PATH" || {
        echo "Error: Failed to create virtual environment" >&2
        exit 1
    }

    return 0
}

# Function to create venv using conda
create_venv_conda() {
    echo "Creating virtual environment using conda..." >&2

    conda create -p "$VENV_PATH" python=3.10 -y >&2 || {
        echo "Error: Failed to create conda environment" >&2
        exit 1
    }

    return 0
}

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..." >&2

    # Ensure pip is up to date
    "$PYTHON_BIN" -m pip install --upgrade pip >&2 || {
        echo "Error: Failed to upgrade pip" >&2
        exit 1
    }

    # Install the package in editable mode
    "$PYTHON_BIN" -m pip install -e "$SCRIPT_DIR/server" >&2 || {
        echo "Error: Failed to install dependencies" >&2
        exit 1
    }

    return 0
}

# Function to validate installation
validate_installation() {
    echo "Validating installation..." >&2

    # Check if Python executable exists
    if [ ! -f "$PYTHON_BIN" ]; then
        echo "Error: Python executable not found at $PYTHON_BIN" >&2
        return 1
    fi

    # Check if required packages are installed
    "$PYTHON_BIN" -c "import httpx, mcp" 2>&1 || {
        echo "Error: Required packages not properly installed" >&2
        return 1
    }

    echo "Installation validation successful!" >&2
    return 0
}

# Main installation logic
if [ ! -d "$VENV_PATH" ]; then
    echo "Virtual environment not found. Installing..." >&2

    # Try conda first, then fall back to standard Python venv
    if command -v conda &> /dev/null; then
        create_venv_conda
    else
        echo "Conda not found, using standard Python venv..." >&2
        create_venv_standard
    fi

    # Install dependencies
    install_dependencies

    # Validate installation
    validate_installation || {
        echo "Installation validation failed. Cleaning up..." >&2
        rm -rf "$VENV_PATH"
        exit 1
    }

    echo "1. The plugin root is $CLAUDE_PLUGIN_ROOT"
    echo "Installation complete!" >&2
fi

# Final check before running
if [ ! -f "$PYTHON_BIN" ]; then
    echo "Error: Python executable not found. Try removing $VENV_PATH and run again." >&2
    exit 1
fi

echo "2. The plugin root is $CLAUDE_PLUGIN_ROOT"
# Run the Python server with inherited environment variables
exec "$PYTHON_BIN" "$@"

