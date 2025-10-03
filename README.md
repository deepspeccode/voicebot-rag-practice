# Voice+Text Chatbot (Practice Repo)

A low-latency voice and text chatbot system built with open-source AI models, featuring real-time speech processing, retrieval-augmented generation (RAG), and a modern web interface.

## 🎯 Project Goals

This is a learning project to implement a production-grade conversational AI system with:
- **Voice Input/Output**: Real-time speech-to-text and text-to-speech
- **Text Chat**: Fast streaming text responses
- **RAG**: Retrieval-Augmented Generation for knowledge-based responses
- **Low Latency**: Optimized for real-time user experience
- **Observability**: Comprehensive monitoring and metrics

## 🎛️ Architecture

```
┌─────────────┐
│   Next.js   │  Landing page with push-to-talk
│   Frontend  │  Real-time streaming UI
└──────┬──────┘
       │
┌──────▼──────┐
│   Nginx     │  Reverse proxy & TLS termination
└──────┬──────┘
       │
┌──────▼──────┐
│  FastAPI    │  Orchestration layer
│     App     │  WebSocket & SSE endpoints
└──┬───┬───┬──┘
   │   │   │
   │   │   └────────┐
   │   │            │
┌──▼───▼───▼──┐  ┌─▼────┐
│     LLM     │  │ RAG  │  Vector search & retrieval
│ (vLLM/llama)│  │      │  FAISS/pgvector
└─────────────┘  └──────┘
   
┌──────┐  ┌──────┐
│ STT  │  │ TTS  │  Speech processing
│Whisper│  │Piper │  
└──────┘  └──────┘
```

## 📊 Service Level Objectives (SLOs)

Our performance targets for production-quality experience:

| Metric | Target | Description |
|--------|--------|-------------|
| **First Token (Text)** | ≤ 300ms | Time to first LLM token for text input |
| **First Token (Voice)** | ≤ 700ms | Time to first LLM token for voice input |
| **Audio → Transcript** | ≤ 800ms | STT processing latency |
| **Streaming Rate** | ≥ 30 tok/s | LLM token generation speed (8B model on GPU) |
| **End-to-End P99** | ≤ 2.5s | 99th percentile total response time |
| **Concurrent Users** | ≥ 100 | Simultaneous user capacity |
| **Uptime** | 99.9% | System availability |

## 🚀 Quick Start

### Prerequisites
- Docker Desktop running
- Node.js 18+ (for frontend)
- Git
- Ollama installed locally
- 8GB+ RAM (for Qwen2.5 7B model)

### Demo Setup (5 minutes)

1. **Install and setup Ollama:**
   ```bash
   # Install Ollama (if not already installed)
   # Visit https://ollama.ai/download for installation instructions
   
   # Download Qwen2.5 7B model
   ollama pull qwen2.5:7b
   
   # Start Ollama server
   ollama serve
   ```

2. **Clone and start the LLM service:**
   ```bash
   git clone https://github.com/deepspeccode/voicebot-rag-practice.git
   cd voicebot-rag-practice
   
   # Start the LLM service (runs on host, not in Docker)
   cd services/llm
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   python main.py
   ```

3. **Start the frontend (in a new terminal):**
   ```bash
   cd frontend
   node server.js
   ```

4. **Open the demo:**
   - Frontend: http://localhost:3000
   - LLM API: http://localhost:8001

### 🎯 **Live Demo Ready!**

Your team can now interact with the AI chatbot:
- **Real AI responses** from Qwen2.5 7B running locally via Ollama
- **Beautiful interface** with typing indicators
- **Status monitoring** showing service health
- **Demo instructions** built into the UI
- **Both streaming and non-streaming** chat completions

**Try these demo questions:**
- "Hello! How are you?"
- "What can you help me with?"
- "Explain quantum computing in simple terms"
- "Write a short poem about coding"

## 🧪 Testing the System

### 1. Test LLM Service Health
```bash
# Check if LLM service is running
curl http://localhost:8001/healthz

# Expected response:
# {"status":"ok","model_loaded":true,"uptime":1759479171.7937365}
```

### 2. Test Chat Completion (Non-streaming)
```bash
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "Hello! How are you?"}],
    "temperature": 0.7,
    "max_tokens": 200,
    "stream": false
  }'
```

### 3. Test Streaming Chat Completion
```bash
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "Tell me a short story about a robot"}],
    "temperature": 0.7,
    "max_tokens": 200,
    "stream": true
  }'
```

### 4. Test Prometheus Metrics
```bash
curl http://localhost:8001/metrics
```

### 5. Test Frontend Integration
1. Open http://localhost:3000 in your browser
2. Type a message and press Enter
3. Watch the AI respond in real-time
4. Try the streaming toggle to see the difference

### 6. Test Complete System
```bash
# Start all services
docker-compose up -d

# Check all services are running
docker-compose ps

# Test orchestration layer
curl http://localhost:8080/healthz

# Test chat through orchestration
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from the orchestration layer!", "stream": true}'
```

## 🔧 Troubleshooting

### LLM Service Won't Start
```bash
# Check Docker logs
docker-compose logs llm

# Check if model is downloaded
docker-compose exec llm ls -la /models/

# Restart LLM service
docker-compose restart llm
```

### Model Not Loading
```bash
# Check model file exists
docker-compose exec llm ls -la /models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf

# Download model if missing
docker-compose exec llm python download_model.py
```

### Frontend Not Connecting
```bash
# Check if LLM service is accessible
curl http://localhost:8001/healthz

# Check CORS settings in LLM service
# (CORS is already configured to allow all origins)
```

### Performance Issues
```bash
# Check system resources
docker stats

# Monitor LLM service specifically
docker-compose logs -f llm
```

## 🛠️ Technology Stack

### AI Services
- **LLM**: Ollama with Qwen2.5 7B Instruct (Currently Active)
- **STT**: faster-whisper (OpenAI Whisper)
- **TTS**: Piper or Coqui-TTS
- **Embeddings**: intfloat/e5-small-v2

### Infrastructure
- **Orchestration**: FastAPI with WebSocket & SSE
- **Vector DB**: FAISS or pgvector
- **Web Server**: Nginx with TLS
- **Frontend**: Next.js 14+ with TypeScript
- **Monitoring**: Prometheus + Grafana

### Deployment
- **Containers**: Docker Compose (dev), Kubernetes (prod)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions

## 🤖 Qwen2.5 7B Model Integration (COMPLETE ✅)

### 🚀 **What We Built**

We've successfully integrated **Qwen2.5 7B Instruct** model with **Ollama** backend, providing a powerful, locally-running AI chatbot with superior performance compared to the previous TinyLlama setup.

#### 🏗️ **Updated Architecture**
```
┌─────────────────┐
│   FastAPI       │  OpenAI-compatible API wrapper
│   (Port 8001)   │  /healthz, /v1/chat/completions, /metrics
└─────────┬───────┘
          │
┌─────────▼───────┐
│   Ollama        │  LLM inference engine
│ (Qwen2.5:7b)   │  High-performance model serving
└─────────────────┘
```

#### 🎯 **Key Improvements**

**✅ Model Upgrade:**
- **From**: TinyLlama 1.1B (638MB) → **To**: Qwen2.5 7B (4.7GB)
- **Performance**: Significantly better reasoning, creativity, and accuracy
- **Context**: Better understanding of complex queries and conversations

**✅ Backend Modernization:**
- **From**: llama.cpp → **To**: Ollama
- **Benefits**: Better model management, easier updates, optimized inference
- **Compatibility**: Maintains OpenAI-compatible API

**✅ Enhanced Features:**
- **Streaming**: Real-time token streaming with Ollama's optimized pipeline
- **Non-streaming**: Batch completions for better throughput
- **Health Monitoring**: Ollama server availability checks
- **Error Handling**: Robust error handling with graceful degradation

#### 📁 **Updated Files**

**Modified Files:**
- **`services/llm/main.py`** - Complete rewrite for Ollama integration
- **`docker-compose.yml`** - Updated model configuration
- **`frontend/index.html`** - Updated UI to reflect Qwen branding

**New Functions Added:**
- **`format_messages_for_ollama()`** - Converts OpenAI format to Ollama format
- **`generate_completion()`** - Non-streaming completions via Ollama
- **`generate_streaming_response()`** - Streaming completions via Ollama
- **Updated `lifespan()`** - Ollama server health checks
- **Updated `health_check()`** - Ollama-specific health monitoring

#### 🧪 **Test Results**

**Performance Tests:**
```bash
# Simple math - Instant response
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen2.5:7b", "messages": [{"role": "user", "content": "What is 2+2?"}]}'
# Response: "The sum of 2 + 2 is 4." (Instant, accurate)

# Complex explanation - Detailed, well-structured
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen2.5:7b", "messages": [{"role": "user", "content": "Explain machine learning in simple terms."}]}'
# Response: Comprehensive, educational explanation with examples

# Creative writing - High-quality, formatted
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen2.5:7b", "messages": [{"role": "user", "content": "Write a short poem about coding."}], "temperature": 0.7}'
# Response: Beautiful, creative poem with proper formatting
```

**Streaming Tests:**
```bash
# Real-time streaming - Smooth token delivery
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen2.5:7b", "messages": [{"role": "user", "content": "Tell me a story"}], "stream": true}'
# Response: Real-time token streaming with proper SSE formatting
```

#### 🎯 **Current Status: FULLY OPERATIONAL**

- 🟢 **Service**: Running and healthy (`model_loaded: true`)
- 🟢 **API**: All endpoints working (`/healthz`, `/v1/chat/completions`, `/metrics`)
- 🟢 **AI**: Qwen2.5 generating high-quality, intelligent responses
- 🟢 **Streaming**: SSE streaming working with proper data framing
- 🟢 **Performance**: Fast response times with superior quality
- 🟢 **Monitoring**: Prometheus metrics active and collecting data
- 🟢 **Frontend**: Updated HTML interface reflecting Qwen branding

#### 🔧 **Setup Instructions**

**Prerequisites:**
```bash
# Install Ollama (if not already installed)
# Visit https://ollama.ai/download for installation instructions

# Download Qwen2.5 7B model (4.7GB download)
ollama pull qwen2.5:7b

# Start Ollama server
ollama serve
```

**Service Setup:**
```bash
# Clone repository
git clone https://github.com/deepspeccode/voicebot-rag-practice.git
cd voicebot-rag-practice

# Setup LLM service
cd services/llm
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Start the service
python main.py
```

**Verification:**
```bash
# Check service health
curl http://localhost:8001/healthz
# Expected: {"status": "ok", "model_loaded": true, "uptime": ...}

# Test chat completion
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen2.5:7b", "messages": [{"role": "user", "content": "Hello!"}]}'
```

## 🤖 LLM Service Implementation (COMPLETE ✅)

### What We Built

We've successfully implemented a **fully functional AI chatbot backend** with real AI responses, OpenAI-compatible API, and streaming support:

#### 🏗️ **Architecture Overview**
```
┌─────────────────┐
│   FastAPI       │  OpenAI-compatible API wrapper
│   (Port 8001)   │  /healthz, /v1/chat/completions, /metrics
└─────────┬───────┘
          │
┌─────────▼───────┐
│   llama.cpp     │  LLM inference engine
│   (Internal)    │  CPU-optimized with OpenBLAS
└─────────────────┘
```

#### 📁 **Files Created**
- **`services/llm/Dockerfile`** - Multi-stage Python container with llama.cpp
- **`services/llm/main.py`** - FastAPI wrapper with OpenAI-compatible endpoints
- **`services/llm/requirements.txt`** - Python dependencies (FastAPI, uvicorn, etc.)
- **`services/llm/download_model.py`** - Model download script for TinyLlama
- **`services/llm/model_config.json`** - Model configuration (GGUF format)
- **`services/llm/setup_model.sh`** - Model setup automation
- **Updated `docker-compose.yml`** - LLM service configuration with health checks

#### 🚀 **Key Features Implemented**
- ✅ **Health Monitoring**: `/healthz` endpoint with service status
- ✅ **OpenAI Compatibility**: `/v1/chat/completions` endpoint matching OpenAI API
- ✅ **Real AI Responses**: Working TinyLlama model generating thoughtful responses
- ✅ **SSE Streaming**: Real-time token streaming with proper data framing
- ✅ **Response Filtering**: Prevents AI from "talking to itself"
- ✅ **llama.cpp Integration**: Compiled from source with OpenBLAS optimization
- ✅ **Docker Integration**: Multi-stage build with proper library management
- ✅ **Model Management**: TinyLlama 1.1B model (638MB) for fast testing
- ✅ **Error Handling**: Robust error handling and graceful degradation
- ✅ **Prometheus Metrics**: Comprehensive monitoring and observability
- ✅ **CORS Support**: Cross-origin requests enabled for frontend integration

#### 🧪 **Tested Endpoints**
```bash
# Health check - Returns service status
curl http://localhost:8001/healthz
# Response: {"status":"ok","model_loaded":true,"uptime":1759479171.7937365}

# Chat completion - Real AI responses!
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello! How are you?"}]}'
# Response: Thoughtful AI response with helpful content

# Streaming chat completion
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Tell me a story"}], "stream": true}'
# Response: Real-time streaming tokens

# Prometheus metrics
curl http://localhost:8001/metrics
# Response: Detailed metrics including request counts, token counts, etc.
```

#### 🎯 **Current Status: FULLY OPERATIONAL**
- 🟢 **Service**: Running and healthy (`model_loaded: true`)
- 🟢 **API**: All endpoints working (`/healthz`, `/v1/chat/completions`, `/metrics`)
- 🟢 **AI**: Generating real, helpful responses using TinyLlama
- 🟢 **Streaming**: SSE streaming working with proper data framing
- 🟢 **Filtering**: AI responses are clean and don't "talk to themselves"
- 🟢 **Monitoring**: Prometheus metrics active and collecting data
- 🟢 **Frontend**: Working HTML demo interface (Issue 7 complete)

### How to Replicate

#### **Prerequisites**
- Docker Desktop running
- Git repository cloned
- Port 8001 available

#### **Step-by-Step Setup**

1. **Start the LLM service:**
   ```bash
   docker-compose up llm
   ```

2. **Verify service is running:**
   ```bash
   curl http://localhost:8001/healthz
   # Should return: {"status": "ok", "model_loaded": true, "uptime": ...}
   ```

3. **Test chat completions:**
   ```bash
   curl -X POST http://localhost:8001/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{"messages": [{"role": "user", "content": "Hello!"}]}'
   ```

#### **Service Configuration**
The LLM service is configured in `docker-compose.yml`:
```yaml
llm:
  build: ./services/llm
  container_name: voicebot-llm
  environment:
    - MODEL_NAME=${MODEL_NAME:-llama-3.1-8b-instruct}
    - MODEL_PATH=${MODEL_PATH:-/models/llama-3.1-8b-instruct.Q4_K_M.gguf}
  ports:
    - "8001:8001"
  volumes:
    - llm_models:/models
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8001/healthz"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### 🔧 **Modularity & Deployment Strategy**

#### **Current Implementation: Modular & Scriptable**

**✅ KEEP MODULAR** - The current implementation is designed for modularity:

1. **Independent Service**: The LLM service runs as a standalone container
2. **API-First Design**: OpenAI-compatible endpoints allow easy integration
3. **Health Checks**: Built-in monitoring for orchestration systems
4. **Environment Variables**: Configurable via environment variables
5. **Volume Mounts**: Model persistence across deployments

#### **Deployment Options**

**Option 1: Standalone Script (Recommended)**
```bash
#!/bin/bash
# deploy-llm.sh
echo "Deploying LLM service..."
docker-compose up -d llm
echo "LLM service deployed on port 8001"
```

**Option 2: Kubernetes Deployment**
```yaml
# k8s/llm-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: llm-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: llm-service
  template:
    metadata:
      labels:
        app: llm-service
    spec:
      containers:
      - name: llm
        image: voicebot-llm:latest
        ports:
        - containerPort: 8001
        env:
        - name: MODEL_PATH
          value: "/models/llama-3.1-8b-instruct.Q4_K_M.gguf"
```

**Option 3: Terraform Module**
```hcl
# terraform/llm-service.tf
module "llm_service" {
  source = "./modules/llm-service"
  
  model_name = "llama-3.1-8b-instruct"
  model_path = "/models/llama-3.1-8b-instruct.Q4_K_M.gguf"
  port       = 8001
}
```

#### **Why Keep It Modular?**

1. **Error Isolation**: LLM service failures don't crash the entire system
2. **Independent Scaling**: Can scale LLM service separately from other components
3. **Easy Testing**: Can test LLM service in isolation
4. **Deployment Flexibility**: Can deploy to different environments (dev/staging/prod)
5. **Maintenance**: Easy to update LLM service without affecting other services

#### **Next Steps for Complete Deployment**

1. **Part B**: Integrate actual llama.cpp inference (currently using mock responses)
2. **Part C**: Implement real streaming with llama.cpp
3. **Part D**: Performance tuning and optimization
4. **Production**: Add authentication, rate limiting, and monitoring

## 📚 Project Phases

This project is organized into 6 phases with 10 tasks:

### Phase 1: Foundations ✅ **COMPLETE**
- ✅ Project setup and infrastructure
- ✅ Docker Compose configuration
- ✅ GitHub setup with CI/CD
- ✅ Production deployment on AWS EC2

### Phase 2: Core AI Services (Partially Complete)
- ✅ **LLM service implementation** - **COMPLETE**
  - ✅ OpenAI-compatible API
  - ✅ SSE streaming support
  - ✅ Response filtering
  - ✅ Real AI responses with TinyLlama
- 🔲 Speech-to-Text service
- 🔲 Text-to-Speech service

### Phase 3: RAG
- 🔲 RAG service with vector search

### Phase 4: Orchestration
- ✅ **FastAPI coordination layer** - **COMPLETE**
  - ✅ Health checks and service discovery
  - ✅ Chat endpoint with streaming
  - ✅ WebSocket support (placeholder)

### Phase 5: Frontend ✅ **COMPLETE**
- ✅ **Chatbot Interface** - Working HTML frontend with real-time chat
- ✅ **Local LLM Integration** - Connected to TinyLlama backend
- ✅ **Demo Ready** - Team presentation interface available
- ✅ **Streaming Support** - Real-time token streaming
- ✅ **Status Monitoring** - Service health indicators

### Phase 6: Observability & Hardening
- ✅ **Monitoring and alerting** - Prometheus & Grafana
- ✅ **Production deployment** - AWS EC2 with automation
- 🔲 Performance optimization
- 🔲 Security hardening

## 📈 Monitoring & Observability

Access monitoring dashboards:
- **Grafana**: http://localhost:3001
- **Prometheus**: http://localhost:9090

Key metrics tracked:
- Response latencies (P50, P95, P99)
- Token generation rates
- Error rates and success rates
- Resource utilization (CPU, Memory, GPU)
- Concurrent connections

## 🧪 Testing

```bash
# Run unit tests
docker compose run --rm app pytest

# Run integration tests
./scripts/integration-test.sh

# Load testing
./scripts/load-test.sh
```

## 📖 Documentation

- [Project Tracking Guide](PROJECT_TRACKING.md)
- [Setup Instructions](project_instructions.md)
- [LLM Service Deployment Guide](docs/LLM_SERVICE_DEPLOYMENT.md)
- [GitHub Project Board](https://github.com/users/deepspeccode/projects/8)

## 🤝 Contributing

This is a learning project, but contributions are welcome!

1. Create a feature branch: `git checkout -b feat/my-feature`
2. Make your changes with tests
3. Push and create a PR: `gh pr create --fill`

## 📄 License

MIT License - feel free to use this for learning and experimentation.

## 🙏 Acknowledgments

Built with open-source models and tools:
- Meta's Llama models
- OpenAI's Whisper
- vLLM team
- FastAPI and Next.js communities

---

## 🎉 Current Achievements

### ✅ **What's Working Right Now**

**Complete AI Chatbot System:**
- 🤖 **Real AI Responses**: Qwen2.5 7B model generating intelligent, high-quality responses
- 🔄 **Streaming Support**: Real-time token streaming with Ollama's optimized pipeline
- 🌐 **Web Interface**: Beautiful HTML frontend with typing indicators
- 🔧 **OpenAI Compatibility**: Drop-in replacement for OpenAI API
- 📊 **Monitoring**: Prometheus metrics and Grafana dashboards
- ☁️ **Production Ready**: Deployed on AWS EC2 with automation
- 🚀 **Modern Backend**: Ollama integration for better model management

**Technical Features:**
- ✅ **Response Filtering**: Prevents AI from "talking to itself"
- ✅ **CORS Support**: Cross-origin requests enabled
- ✅ **Health Checks**: Comprehensive service monitoring
- ✅ **Error Handling**: Graceful degradation and recovery
- ✅ **Ollama Integration**: Modern model serving with optimized inference
- ✅ **Model Management**: Easy model switching and updates via Ollama
- ✅ **Performance**: Fast response times with superior quality

**Live Demo Available:**
- **Local**: http://localhost:3000 (when running locally)
- **Production**: http://54.167.82.36:8080 (AWS EC2)
- **API**: http://54.167.82.36:8001 (LLM service direct)

### 🚀 **Ready for Next Phase**

**Immediate Next Steps:**
1. **STT Service** - Speech-to-Text with Whisper
2. **TTS Service** - Text-to-Speech with Piper
3. **RAG Service** - Vector search and retrieval
4. **Performance Optimization** - GPU acceleration

**Current Status**: 🟢 **Fully Functional** | **Phase**: 2 - Core AI Services (LLM Complete)

