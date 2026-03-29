#!/bin/bash
# Serve the workshop docs locally
# Usage: ./serve.sh

set -e

VENV_DIR=".venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    echo "Installing mkdocs..."
    pip install -r requirements.txt
else
    source "$VENV_DIR/bin/activate"
fi

echo "Starting MkDocs server at http://localhost:8000"
mkdocs serve
