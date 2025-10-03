"""
LLM Service - FastAPI wrapper for llama.cpp
Provides OpenAI-compatible API with SSE streaming support
"""

import os
import json
import asyncio
import time
import subprocess
import signal
import logging
import httpx
from typing import Optional, AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Prometheus metrics - initialized lazily to avoid duplication
REQUEST_COUNT = None
REQUEST_DURATION = None
TOKEN_COUNT = None

def get_metrics():
    global REQUEST_COUNT, REQUEST_DURATION, TOKEN_COUNT
    if REQUEST_COUNT is None:
        REQUEST_COUNT = Counter('llm_requests_total', 'Total number of requests', ['method', 'endpoint', 'status'])
        REQUEST_DURATION = Histogram('llm_request_duration_seconds', 'Request duration in seconds', ['endpoint'])
        TOKEN_COUNT = Counter('llm_tokens_total', 'Total number of tokens generated')
    return REQUEST_COUNT, REQUEST_DURATION, TOKEN_COUNT

# Global variables
model_loaded = False
llama_server_process: Optional[subprocess.Popen] = None
llama_server_url = "http://localhost:8080"

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatCompletionRequest(BaseModel):
    model: str = "llama-3.1-8b-instruct"
    messages: list[ChatMessage]
    temperature: float = 0.7
    max_tokens: int = 512
    stream: bool = False

class ChatCompletionResponse(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: list[dict]
    usage: dict

class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    uptime: float
    
    class Config:
        protected_namespaces = ()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage llama.cpp server lifecycle"""
    global llama_server_process, model_loaded
    
    # Start llama.cpp server
    logger.info("Starting llama.cpp server...")
    model_path = os.getenv("MODEL_PATH", "/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf")
    
    if not os.path.exists(model_path):
        logger.error(f"Model file not found at {model_path}")
        logger.error("Please ensure the model is downloaded to the models volume")
    else:
        logger.info(f"Starting llama.cpp server with model: {model_path}")
        
        # Start llama.cpp server
        cmd = [
            "llama-server",
            "--model", model_path,
            "--host", "0.0.0.0",
            "--port", "8080",
            "--n-predict", "512",
            "--ctx-size", "2048",
            "--threads", str(os.cpu_count() or 4),
            "--batch-size", "512",
            "--n-gpu-layers", "0",  # CPU only for now
        ]
        
        try:
            llama_server_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                preexec_fn=os.setsid  # Detach from current process group
            )
            
            # Wait for server to start
            await asyncio.sleep(10)
            
            # Check if server is running
            if llama_server_process.poll() is None:
                # Test server health
                try:
                    async with httpx.AsyncClient() as client:
                        response = await client.get(f"{llama_server_url}/health", timeout=5)
                        if response.status_code == 200:
                            model_loaded = True
                            logger.info("llama.cpp server started successfully")
                        else:
                            logger.error(f"llama.cpp server health check failed: {response.status_code}")
                except httpx.RequestError as e:
                    logger.error(f"Failed to connect to llama.cpp server: {e}")
            else:
                logger.error("llama.cpp server failed to start")
                
        except Exception as e:
            logger.error(f"Error starting llama.cpp server: {e}")
    
    yield
    
    # Cleanup
    if llama_server_process:
        logger.info("Shutting down llama.cpp server...")
        try:
            os.killpg(os.getpgid(llama_server_process.pid), signal.SIGTERM)
            llama_server_process.wait(timeout=10)
        except (subprocess.TimeoutExpired, ProcessLookupError):
            logger.warning("Force killing llama.cpp server...")
            try:
                os.killpg(os.getpgid(llama_server_process.pid), signal.SIGKILL)
            except ProcessLookupError:
                pass
        logger.info("llama.cpp server shut down")

# Initialize FastAPI app with lifespan
app = FastAPI(title="LLM Service", version="1.0.0", lifespan=lifespan)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

@app.get("/healthz", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    # Check if llama.cpp server is actually running
    llama_healthy = False
    if llama_server_process and llama_server_process.poll() is None:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{llama_server_url}/health", timeout=2)
                llama_healthy = response.status_code == 200
        except httpx.RequestError:
            llama_healthy = False
    
    return HealthResponse(
        status="ok" if model_loaded and llama_healthy else "degraded",
        model_loaded=model_loaded and llama_healthy,
        uptime=time.time()
    )

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/v1/chat/completions")
async def chat_completions(request: ChatCompletionRequest):
    """OpenAI-compatible chat completions endpoint"""
    start_time = time.time()
    
    # Get metrics
    request_count, request_duration, token_count = get_metrics()
    
    # Check if model is loaded
    if not model_loaded:
        request_count.labels(method='POST', endpoint='/v1/chat/completions', status='503').inc()
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        if request.stream:
            # Streaming response
            request_count.labels(method='POST', endpoint='/v1/chat/completions', status='200').inc()
            return StreamingResponse(
                generate_streaming_response(request),
                media_type="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive",
                }
            )
        else:
            # Non-streaming response
            response = await generate_completion(request)
            request_count.labels(method='POST', endpoint='/v1/chat/completions', status='200').inc()
            request_duration.labels(endpoint='/v1/chat/completions').observe(time.time() - start_time)
            return response
            
    except Exception as e:
        logger.error(f"Error in chat completions: {e}")
        request_count.labels(method='POST', endpoint='/v1/chat/completions', status='500').inc()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

async def generate_completion(request: ChatCompletionRequest) -> ChatCompletionResponse:
    """Generate non-streaming completion using llama.cpp"""
    # Convert messages to llama.cpp format
    prompt = format_messages_for_llama(request.messages)
    
    # Prepare llama.cpp request
    llama_request = {
        "prompt": prompt,
        "n_predict": request.max_tokens,
        "temperature": request.temperature,
        "stream": False
    }
    
    try:
        # Call llama.cpp server
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{llama_server_url}/completion",
                json=llama_request,
                timeout=30
            )
            response.raise_for_status()
            
            llama_response = response.json()
        content = llama_response.get("content", "")
        
        # Count tokens (rough estimation)
        prompt_tokens = len(prompt.split())
        completion_tokens = len(content.split())
        
        # Update metrics
        _, _, token_count = get_metrics()
        token_count.inc(completion_tokens)
        
        return ChatCompletionResponse(
            id=f"chatcmpl-{int(time.time())}",
            created=int(time.time()),
            model=request.model,
            choices=[{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": content
                },
                "finish_reason": "stop"
            }],
            usage={
                "prompt_tokens": prompt_tokens,
                "completion_tokens": completion_tokens,
                "total_tokens": prompt_tokens + completion_tokens
            }
        )
        
    except httpx.RequestError as e:
        logger.error(f"Error calling llama.cpp server: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate completion: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error in generate_completion: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

async def generate_streaming_response(request: ChatCompletionRequest) -> AsyncGenerator[str, None]:
    """Generate streaming response using llama.cpp"""
    # Convert messages to llama.cpp format
    prompt = format_messages_for_llama(request.messages)
    
    # Prepare llama.cpp request
    llama_request = {
        "prompt": prompt,
        "n_predict": request.max_tokens,
        "temperature": request.temperature,
        "stream": True
    }
    
    try:
        # Call llama.cpp server with streaming
        async with httpx.AsyncClient() as client:
            async with client.stream(
                "POST",
                f"{llama_server_url}/completion",
                json=llama_request,
                timeout=30
            ) as response:
                response.raise_for_status()
                
                # Stream the response
                async for line in response.aiter_lines():
                    if line:
                        if line.startswith('data: '):
                            data = line[6:]  # Remove 'data: ' prefix
                            if data.strip() == '[DONE]':
                                yield "data: [DONE]\n\n"
                                break
                            else:
                                try:
                                    llama_data = json.loads(data)
                                    # Convert llama.cpp format to OpenAI format
                                    if 'content' in llama_data:
                                        openai_data = {
                                            "choices": [{
                                                "delta": {
                                                    "content": llama_data['content']
                                                }
                                            }]
                                        }
                                        yield f"data: {json.dumps(openai_data)}\n\n"
                                        _, _, token_count = get_metrics()
                                        token_count.inc(1)
                                except json.JSONDecodeError:
                                    continue
                            
    except httpx.RequestError as e:
        logger.error(f"Error calling llama.cpp server: {e}")
        yield f"data: {json.dumps({'error': 'Failed to generate completion'})}\n\n"

def format_messages_for_llama(messages: list[ChatMessage]) -> str:
    """Convert OpenAI chat messages to TinyLlama chat format"""
    # Use a very direct format that prevents the model from generating user messages
    # Take only the last user message and create a simple Q&A format
    
    # Find the last user message
    last_user_message = None
    for message in reversed(messages):
        if message.role == "user":
            last_user_message = message.content
            break
    
    if not last_user_message:
        return "Hello! How can I help you today?"
    
    # Use a very direct format that should prevent conversation continuation
    prompt = f"Question: {last_user_message}\n\nAnswer:"
    return prompt

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True
    )