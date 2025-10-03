#!/bin/bash
# Model setup script for LLM service

set -e

echo "=== LLM Service Model Setup ==="
echo "This script will download the Llama 3.1 8B Instruct model"
echo "Model size: ~4.7GB (Q4_K_M quantization)"
echo ""

# Check if we're in a Docker container
if [ -f /.dockerenv ]; then
    echo "Running inside Docker container"
    MODEL_PATH="/models"
else
    echo "Running on host system"
    MODEL_PATH="./models"
    mkdir -p "$MODEL_PATH"
fi

echo "Model will be downloaded to: $MODEL_PATH"
echo ""

# Download the model
echo "Starting model download..."
python3 download_model.py

echo ""
echo "✅ Model setup completed!"
echo "You can now start the LLM service with:"
echo "  docker-compose up llm"
echo ""
