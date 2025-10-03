#!/usr/bin/env python3
"""
Download Llama 3.1 8B Instruct model - Much better for conversations
"""

import os
import sys
import requests
from pathlib import Path

# Llama 3.1 8B Instruct configuration
MODEL_NAME = "llama-3.1-8b-instruct"
MODEL_FILE = "llama-3.1-8b-instruct.Q4_K_M.gguf"
MODEL_URL = f"https://huggingface.co/bartowski/Llama-3.1-8B-Instruct-GGUF/resolve/main/{MODEL_FILE}"
MODEL_PATH = "/models"
EXPECTED_SIZE = 4.7 * 1024 * 1024 * 1024  # ~4.7GB

def download_file(url: str, filepath: str) -> bool:
    """Download file with progress bar"""
    print(f"Downloading {MODEL_FILE}...")
    print(f"URL: {url}")
    print(f"Destination: {filepath}")
    
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        downloaded = 0
        
        with open(filepath, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\rProgress: {percent:.1f}% ({downloaded / (1024*1024*1024):.2f}GB / {total_size / (1024*1024*1024):.2f}GB)", end="", flush=True)
        
        print(f"\nDownload completed: {filepath}")
        return True
        
    except Exception as e:
        print(f"\nError downloading model: {e}")
        return False

def main():
    """Main download function"""
    print("=== Llama 3.1 8B Instruct Model Downloader ===")
    print(f"Model: {MODEL_NAME}")
    print(f"Quantization: Q4_K_M (optimized for CPU)")
    print(f"Expected size: ~4.7GB")
    print()
    
    # Create models directory
    os.makedirs(MODEL_PATH, exist_ok=True)
    
    # Check if model already exists
    model_filepath = os.path.join(MODEL_PATH, MODEL_FILE)
    if os.path.exists(model_filepath):
        file_size = os.path.getsize(model_filepath)
        if file_size > EXPECTED_SIZE * 0.9:  # 90% of expected size
            print(f"✅ Model already exists: {model_filepath}")
            print(f"Size: {file_size / (1024*1024*1024):.2f}GB")
            return True
        else:
            print(f"⚠️  Model exists but seems incomplete. Re-downloading...")
            os.remove(model_filepath)
    
    # Download the model
    success = download_file(MODEL_URL, model_filepath)
    
    if success:
        file_size = os.path.getsize(model_filepath)
        print(f"✅ Model downloaded successfully!")
        print(f"Size: {file_size / (1024*1024*1024):.2f}GB")
        print(f"Location: {model_filepath}")
        return True
    else:
        print("❌ Model download failed")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
