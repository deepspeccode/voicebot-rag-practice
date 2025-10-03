#!/usr/bin/env python3
"""
TinyLlama LLM Service - Simple FastAPI wrapper for llama.cpp
Provides OpenAI-compatible API for TinyLlama model
"""

import uvicorn
import json
import time
import os
import subprocess
import signal
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI(title="TinyLlama LLM Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    model: str = "tinyllama-1.1b-chat"
    temperature: float = 0.7
    max_tokens: int = 512
    stream: bool = False

class ChatResponse(BaseModel):
    choices: List[dict]
    usage: dict

# Global variables
model_loaded = False
llama_process = None

def start_llama_server():
    """Start llama.cpp server with TinyLlama model"""
    global model_loaded, llama_process
    
    try:
        print("🚀 Starting TinyLlama LLM Service...")
        
        # Load model configuration
        config_path = "/app/model_config.json"
        if os.path.exists(config_path):
            with open(config_path, "r") as f:
                config = json.load(f)
            model_path = config.get("model_path", "/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf")
        else:
            model_path = "/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        
        print(f"📁 Model path: {model_path}")
        
        if not os.path.exists(model_path):
            print(f"❌ Model file not found: {model_path}")
            return False
        
        print("✅ Model file found!")
        
        # Start llama.cpp server
        cmd = [
            "/usr/local/bin/llama-server",
            "--model", model_path,
            "--host", "0.0.0.0",
            "--port", "8080",
            "--threads", "2",
            "--ctx-size", "2048",
            "--batch-size", "256"
        ]
        
        print(f"🔧 Starting llama.cpp server: {' '.join(cmd)}")
        llama_process = subprocess.Popen(
            cmd, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            preexec_fn=os.setsid  # Create new process group
        )
        
        # Wait for server to start
        print("⏳ Waiting for server to start...")
        time.sleep(10)
        
        # Test connection
        import requests
        try:
            response = requests.get("http://localhost:8080/health", timeout=5)
            if response.status_code == 200:
                model_loaded = True
                print("✅ TinyLlama model loaded successfully!")
                return True
            else:
                print(f"❌ Model loading failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Model loading failed: {e}")
            return False
            
    except Exception as e:
        print(f"❌ Startup failed: {e}")
        return False

def stop_llama_server():
    """Stop llama.cpp server"""
    global llama_process
    if llama_process:
        try:
            # Kill the entire process group
            os.killpg(os.getpgid(llama_process.pid), signal.SIGTERM)
            llama_process.wait(timeout=10)
        except:
            try:
                llama_process.kill()
            except:
                pass
        llama_process = None

@app.on_event("startup")
async def startup_event():
    """Start llama.cpp server on startup"""
    start_llama_server()

@app.on_event("shutdown")
async def shutdown_event():
    """Stop llama.cpp server on shutdown"""
    stop_llama_server()

@app.get("/healthz")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy" if model_loaded else "degraded",
        "model_loaded": model_loaded,
        "uptime": time.time()
    }

@app.post("/v1/chat/completions")
async def chat_completions(request: ChatRequest):
    """OpenAI-compatible chat completions endpoint"""
    if not model_loaded:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Get user message
        user_message = request.messages[-1].content if request.messages else "Hello"
        
        # Call llama.cpp API
        llama_request = {
            "prompt": f"<|user|>\n{user_message}\n<|assistant|>\n",
            "temperature": request.temperature,
            "max_tokens": request.max_tokens,
            "stop": ["<|user|>", "<|assistant|>"]
        }
        
        import requests
        response = requests.post(
            "http://localhost:8080/completion",
            json=llama_request,
            timeout=30
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail="LLM generation failed")
        
        result = response.json()
        content = result.get("content", "I apologize, but I could not generate a response.")
        
        return ChatResponse(
            choices=[{
                "message": {
                    "role": "assistant",
                    "content": content
                },
                "finish_reason": "stop"
            }],
            usage={
                "prompt_tokens": len(user_message.split()),
                "completion_tokens": len(content.split()),
                "total_tokens": len(user_message.split()) + len(content.split())
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat completion failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)