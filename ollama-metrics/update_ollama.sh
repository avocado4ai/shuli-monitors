#!/bin/bash

echo "Updating Ollama to the latest version..."

# Stop the Ollama service
echo "Stopping Ollama service..."
sudo systemctl stop ollama

# Download and install the latest version of Ollama
echo "Downloading latest Ollama version..."
curl -fsSL https://ollama.ai/install.sh | sh

# Check the new version
echo "Checking new Ollama version..."
ollama --version

# Start the Ollama service
echo "Starting Ollama service..."
sudo systemctl start ollama

# Check service status
echo "Ollama service status:"
systemctl status ollama --no-pager -l

echo "Ollama update completed!"