#!/bin/bash

echo "Starting custom startup script..."

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Verify installation
pip list

# Start the application
gunicorn --bind 0.0.0.0:8000 main:app
