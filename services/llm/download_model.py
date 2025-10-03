#!/usr/bin/env python3
"""
Model download script for Llama 3.1 8B Instruct in GGUF format
Downloads the Q4_K_M quantized version for optimal CPU performance
"""

import os
import sys
import requests
import hashlib
from pathlib import Path

# Model configuration
MODEL_NAME = "llama-3.1-8b-instruct"
MODEL_FILE = "llama-3.1-8b-instruct.Q4_K_M.gguf"
MODEL_URL = f"https://huggingface.co/TheBloke/Llama-3.1-8B-Instruct-GGUF/resolve/main/{MODEL_FILE}"
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

def verify_file(filepath: str) -> bool:
    """Verify downloaded file"""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return False
    
    file_size = os.path.getsize(filepath)
    print(f"File size: {file_size / (1024*1024*1024):.2f}GB")
    
    if file_size < EXPECTED_SIZE * 0.9:  # Allow 10% tolerance
        print(f"Warning: File size seems too small (expected ~{EXPECTED_SIZE / (1024*1024*1024):.1f}GB)")
        return False
    
    print("File verification passed")
    return True

def main():
    """Main download function"""
    print("=== Llama 3.1 8B Instruct Model Downloader ===")
    print(f"Model: {MODEL_NAME}")
    print(f"Quantization: Q4_K_M (optimized for CPU)")
    print(f"Expected size: ~4.7GB")
    print()
    
    # Create models directory
    os.makedirs(MODEL_PATH, exist_ok=True)
    model_filepath = os.path.join(MODEL_PATH, MODEL_FILE)
    
    # Check if model already exists
    if os.path.exists(model_filepath):
        print(f"Model already exists: {model_filepath}")
        if verify_file(model_filepath):
            print("Model is ready to use!")
            return
        else:
            print("Existing model file appears corrupted, re-downloading...")
            os.remove(model_filepath)
    
    # Download the model
    print("Starting download...")
    if download_file(MODEL_URL, model_filepath):
        if verify_file(model_filepath):
            print("\n✅ Model download completed successfully!")
            print(f"Model ready at: {model_filepath}")
        else:
            print("\n❌ Model verification failed")
            sys.exit(1)
    else:
        print("\n❌ Model download failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
