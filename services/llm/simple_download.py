#!/usr/bin/env python3
"""
Simple model download using huggingface_hub
Downloads a small model for testing
"""

import os
from huggingface_hub import hf_hub_download

# Use a small, publicly available model
REPO_ID = "microsoft/DialoGPT-small"
FILENAME = "pytorch_model.bin"  # This is just for testing - we'll use a different approach

def main():
    print("🔽 Downloading test model...")
    
    # Create models directory
    os.makedirs("/models", exist_ok=True)
    
    try:
        # For now, let's create a dummy model file for testing
        # In a real scenario, you'd download an actual GGUF model
        dummy_model_path = "/models/test-model.gguf"
        
        with open(dummy_model_path, "w") as f:
            f.write("# This is a dummy model file for testing\n")
            f.write("# In production, this would be a real GGUF model\n")
        
        print(f"✅ Dummy model created at: {dummy_model_path}")
        print("🧪 This is just for testing the service structure")
        print("📝 In production, you'd download a real GGUF model")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    
    return True

if __name__ == "__main__":
    main()
