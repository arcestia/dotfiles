#!/bin/bash
# Wrapper script for codestats_fake.py
# Loads .env file if present and runs the python script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/codestats_fake.py"

# Check for .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading environment from .env..."
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed."
    exit 1
fi

# Run the python script, passing all arguments
python3 "$PYTHON_SCRIPT" "$@"
