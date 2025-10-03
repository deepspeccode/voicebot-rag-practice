"""
Voicebot RAG - Main FastAPI Orchestration Service

This service coordinates all AI services (LLM, STT, TTS, RAG) and provides
REST and WebSocket endpoints for text and voice chat.
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, AsyncGenerator
import logging
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Voicebot RAG API",
    description="Low-latency voice and text chatbot with RAG",
    version="0.1.0"
)

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Service URLs from environment
LLM_URL = os.getenv("OPENAI_COMPAT_BASE_URL", "http://llm:8001")
STT_URL = os.getenv("STT_URL", "http://stt:8002")
TTS_URL = os.getenv("TTS_URL", "http://tts:8003")
RAG_URL = "http://rag:8004"


# =============================================================================
# Data Models
# =============================================================================

class ChatRequest(BaseModel):
    """Request model for text chat"""
    message: str
    use_rag: bool = False
    stream: bool = True


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    services: dict


# =============================================================================
# Health Check Endpoint
# =============================================================================

@app.get("/healthz", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint for container orchestration.
    
    Returns:
        Health status of this service and downstream services
    """
    services_status = {
        "app": "ok",
        "llm": "unknown",  # TODO: Check LLM service health
        "stt": "unknown",  # TODO: Check STT service health
        "tts": "unknown",  # TODO: Check TTS service health
        "rag": "unknown",  # TODO: Check RAG service health
    }
    
    return {
        "status": "ok",
        "services": services_status
    }


# =============================================================================
# Text Chat Endpoint (Server-Sent Events)
# =============================================================================

@app.post("/chat")
async def chat(request: ChatRequest):
    """
    Text chat endpoint with streaming support.
    
    Args:
        request: Chat request with message and options
        
    Returns:
        StreamingResponse with SSE format or JSONResponse for non-streaming
    """
    logger.info(f"Chat request: {request.message[:50]}...")
    
    async def generate_response() -> AsyncGenerator[str, None]:
        """Generate streaming response using SSE format"""
        try:
            # TODO: Implement RAG retrieval if use_rag is True
            
            # TODO: Call LLM service for response generation
            
            # Provide intelligent responses for common questions
            response = generate_smart_response(request.message)
            
            yield "data: {\"type\": \"start\"}\n\n"
            for word in response.split():
                yield f"data: {{\"type\": \"token\", \"content\": \"{word} \"}}\n\n"
            yield "data: {\"type\": \"end\"}\n\n"
            
        except Exception as e:
            logger.error(f"Error in chat: {e}")
            yield f"data: {{\"type\": \"error\", \"message\": \"{str(e)}\"}}\n\n"
    
    if request.stream:
        return StreamingResponse(
            generate_response(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
            }
        )
    else:
        # Non-streaming response
        return JSONResponse({
            "response": f"Hello! I received your message: {request.message}"
        })


# =============================================================================
# Voice Chat Endpoint (WebSocket)
# =============================================================================

@app.websocket("/voice")
async def voice_chat(websocket: WebSocket):
    """
    Voice chat endpoint using WebSocket for real-time audio streaming.
    
    Flow:
    1. Client sends audio chunks
    2. STT transcribes audio to text
    3. RAG retrieves relevant context (if needed)
    4. LLM generates response
    5. TTS converts response to audio
    6. Audio chunks streamed back to client
    """
    await websocket.accept()
    logger.info("WebSocket connection established")
    
    try:
        while True:
            # Receive audio data from client
            data = await websocket.receive_bytes()
            logger.info(f"Received audio chunk: {len(data)} bytes")
            
            # TODO: Implement voice processing pipeline
            # 1. Send audio to STT service
            # 2. Get transcript
            # 3. Process with RAG + LLM
            # 4. Convert response to audio with TTS
            # 5. Stream audio back
            
            # For now, send a simple acknowledgment
            await websocket.send_json({
                "type": "ack",
                "message": "Audio received, processing not yet implemented"
            })
            
    except WebSocketDisconnect:
        logger.info("WebSocket connection closed")
    except Exception as e:
        logger.error(f"Error in voice chat: {e}")
        await websocket.close(code=1011, reason=str(e))


# =============================================================================
# Metrics Endpoint
# =============================================================================

@app.get("/metrics")
async def metrics():
    """
    Prometheus metrics endpoint.
    
    TODO: Implement Prometheus metrics collection:
    - Request latency (P50, P95, P99)
    - Token generation rate
    - Error rates
    - Service health
    """
    return {"message": "Metrics endpoint - to be implemented"}


# =============================================================================
# Root Endpoint
# =============================================================================

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "service": "Voicebot RAG API",
        "version": "0.1.0",
        "endpoints": {
            "health": "/healthz",
            "chat": "/chat (POST)",
            "voice": "/voice (WebSocket)",
            "metrics": "/metrics"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=os.getenv("RELOAD", "false").lower() == "true"
    )

