"""
LLM Service - FastAPI wrapper for llama.cpp
Provides OpenAI-compatible API with SSE streaming support
"""

import os
import json
import asyncio
import time
from typing import Optional, AsyncGenerator

from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse, Response
from pydantic import BaseModel
import uvicorn

# Global variables
model_loaded = True  # For testing, always mark as loaded

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

# Initialize FastAPI app
app = FastAPI(title="LLM Service", version="1.0.0")

@app.get("/healthz", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="ok",
        model_loaded=model_loaded,
        uptime=time.time()
    )

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(content="# No metrics available yet\n", media_type="text/plain")

@app.post("/v1/chat/completions", response_model=ChatCompletionResponse)
async def chat_completions(request: ChatCompletionRequest):
    """OpenAI-compatible chat completions endpoint"""
    if request.stream:
        # For now, return a simple response
        return StreamingResponse(
            generate_streaming_response(request),
            media_type="text/plain"
        )
    else:
        # For now, return a mock response
        return ChatCompletionResponse(
            id="test-123",
            created=int(time.time()),
            model=request.model,
            choices=[{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "Hello! This is a test response from the LLM service."
                },
                "finish_reason": "stop"
            }],
            usage={
                "prompt_tokens": 10,
                "completion_tokens": 15,
                "total_tokens": 25
            }
        )

async def generate_streaming_response(request: ChatCompletionRequest) -> AsyncGenerator[str, None]:
    """Generate streaming response"""
    # For now, return a simple streaming response
    response_text = "Hello! This is a test streaming response from the LLM service."
    for word in response_text.split():
        yield f"data: {json.dumps({'choices': [{'delta': {'content': word + ' '}}]})}\n"
        await asyncio.sleep(0.1)
    yield "data: [DONE]\n"

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True
    )