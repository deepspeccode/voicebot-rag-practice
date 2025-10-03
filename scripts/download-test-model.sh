#!/bin/bash

# Download Llama 3.2 3B model for testing
# This is a smaller, faster model perfect for testing

echo "🚀 Downloading Llama 3.2 3B Instruct for Testing"
echo "================================================"
echo "Model: Llama 3.2 3B Instruct"
echo "Size: ~2GB (Q4_K_M quantization)"
echo "Speed: Very fast inference"
echo "Quality: Good for testing"
echo ""

# Create models directory
mkdir -p ./models

# Download the model using the download script
echo "📥 Starting model download..."
docker-compose run --rm llm python download_model.py

echo ""
echo "✅ Model download completed!"
echo "📍 Model location: ./models/Llama-3.2-3B-Instruct.Q4_K_M.gguf"
echo ""
echo "🧪 Ready for testing! You can now run:"
echo "   docker-compose up llm"
echo ""
echo "🔍 Test the service with:"
echo "   curl http://localhost:8001/healthz"
echo "   curl -X POST http://localhost:8001/v1/chat/completions \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]}'"
