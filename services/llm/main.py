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
ollama_url = "http://localhost:11434"

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatCompletionRequest(BaseModel):
    model: str = "tinyllama-1.1b-chat"
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
    """Check Ollama server availability"""
    global model_loaded
    
    # Check if Ollama is running
    logger.info("Checking Ollama server availability...")
    model_name = os.getenv("MODEL_NAME", "qwen2.5:7b")
    
    try:
        async with httpx.AsyncClient() as client:
            # Check if Ollama is running
            response = await client.get(f"{ollama_url}/api/tags", timeout=5)
            if response.status_code == 200:
                # Check if our model is available
                models = response.json().get("models", [])
                model_available = any(model["name"] == model_name for model in models)
                
                if model_available:
                    model_loaded = True
                    logger.info(f"Ollama server is running and model {model_name} is available")
                else:
                    logger.error(f"Model {model_name} not found in Ollama. Available models: {[m['name'] for m in models]}")
            else:
                logger.error(f"Ollama server health check failed: {response.status_code}")
    except httpx.RequestError as e:
        logger.error(f"Failed to connect to Ollama server: {e}")
        logger.error("Please ensure Ollama is running: ollama serve")
    
    yield

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
    # Check if Ollama server is actually running
    ollama_healthy = False
    if model_loaded:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{ollama_url}/api/tags", timeout=2)
                ollama_healthy = response.status_code == 200
        except httpx.RequestError:
            ollama_healthy = False
    
    return HealthResponse(
        status="ok" if model_loaded and ollama_healthy else "degraded",
        model_loaded=model_loaded and ollama_healthy,
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
    """Generate non-streaming completion using Ollama"""
    # Convert messages to Ollama format
    prompt = format_messages_for_ollama(request.messages)
    
    # Prepare Ollama request
    ollama_request = {
        "model": "qwen2.5:7b",
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": request.temperature,
            "num_predict": request.max_tokens
        }
    }
    
    try:
        # Call Ollama server
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{ollama_url}/api/generate",
                json=ollama_request,
                timeout=30
            )
            response.raise_for_status()
            
            ollama_response = response.json()
        content = ollama_response.get("response", "")
        
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
        logger.error(f"Error calling Ollama server: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate completion: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error in generate_completion: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

async def generate_streaming_response(request: ChatCompletionRequest) -> AsyncGenerator[str, None]:
    """Generate streaming response using Ollama with proper SSE framing, cancellation handling, and time-to-first-token capture"""
    import time
    start_time = time.time()
    first_token_time = None
    
    # Convert messages to Ollama format
    prompt = format_messages_for_ollama(request.messages)
    
    # Prepare Ollama request
    ollama_request = {
        "model": "qwen2.5:7b",
        "prompt": prompt,
        "stream": True,
        "options": {
            "temperature": request.temperature,
            "num_predict": request.max_tokens
        }
    }
    
    try:
        # Call Ollama server with streaming
        async with httpx.AsyncClient() as client:
            async with client.stream(
                "POST",
                f"{ollama_url}/api/generate",
                json=ollama_request,
                timeout=30
            ) as response:
                response.raise_for_status()
                
                # Stream the response with proper SSE framing
                async for line in response.aiter_lines():
                    if line:
                        try:
                            ollama_data = json.loads(line)
                            # Convert Ollama format to OpenAI format
                            if 'response' in ollama_data:
                                content = ollama_data['response']
                                if content:  # Only yield if there's content
                                    # Capture time-to-first-token
                                    if first_token_time is None:
                                        first_token_time = time.time()
                                        logger.info(f"Time to first token: {first_token_time - start_time:.3f}s")
                                    
                                    openai_data = {
                                        "choices": [{
                                            "delta": {
                                                "content": content
                                            }
                                        }]
                                    }
                                    # Proper SSE framing: event: message, data: {...}
                                    yield f"event: message\ndata: {json.dumps(openai_data)}\n\n"
                                    _, _, token_count = get_metrics()
                                    token_count.inc(1)
                            
                            # Check if done - proper end-of-stream token
                            if ollama_data.get('done', False):
                                yield "event: message\ndata: [DONE]\n\n"
                                break
                                
                        except json.JSONDecodeError:
                            continue
                            
    except httpx.RequestError as e:
        logger.error(f"Error calling Ollama server: {e}")
        yield f"event: error\ndata: {json.dumps({'error': 'Failed to generate completion'})}\n\n"
    except asyncio.CancelledError:
        # Handle client disconnect (cancellation)
        logger.info("Streaming request cancelled by client")
        yield f"event: error\ndata: {json.dumps({'error': 'Request cancelled'})}\n\n"
        raise
    except Exception as e:
        logger.error(f"Unexpected error in streaming: {e}")
        yield f"event: error\ndata: {json.dumps({'error': 'Unexpected error'})}\n\n"

def filter_generated_user_messages(content: str) -> str:
    """Filter out generated user messages to prevent AI talking to itself"""
    # First, remove any special tokens that might cause issues
    content = content.replace('<|im_start|>', '').replace('<|im_end|>', '')
    
    # Aggressively cut off at the first "Assistant:" pattern
    # This is the most common pattern that causes the issue
    if 'Assistant:' in content:
        result = content.split('Assistant:')[0].strip()
    elif 'User:' in content:
        result = content.split('User:')[0].strip()
    elif 'Human:' in content:
        result = content.split('Human:')[0].strip()
    elif 'Question:' in content:
        result = content.split('Question:')[0].strip()
    else:
        result = content.strip()
    
    # Additional cleanup - remove any remaining conversation patterns
    conversation_patterns = ['Assistant:', 'User:', 'Human:', 'Question:', 'assistant:', 'user:', 'human:', 'question:']
    for pattern in conversation_patterns:
        if pattern in result:
            # Split and take only the first part before any patterns
            parts = result.split(pattern)
            if parts:
                result = parts[0].strip()
    
    # Remove any trailing patterns
    for pattern in conversation_patterns:
        result = result.rstrip(pattern).strip()
    
    return result

def format_messages_for_ollama(messages: list[ChatMessage]) -> str:
    """Convert OpenAI chat messages to Ollama format"""
    if not messages:
        return "Hello! How can I help you today?"
    
    # Build conversation context, but limit to last 3 exchanges to prevent context overflow
    recent_messages = messages[-6:]  # Last 3 exchanges (6 messages)
    
    prompt_parts = []
    for message in recent_messages:
        if message.role == "user":
            prompt_parts.append(f"Human: {message.content}")
        elif message.role == "assistant":
            prompt_parts.append(f"Assistant: {message.content}")
    
    # Add the current assistant prompt
    prompt_parts.append("Assistant:")
    
    return "\n\n".join(prompt_parts)

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True
    )