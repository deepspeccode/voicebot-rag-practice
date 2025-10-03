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

### Demo Setup (5 minutes)

1. **Start the LLM service:**
   ```bash
   git clone https://github.com/deepspeccode/voicebot-rag-practice.git
   cd voicebot-rag-practice
   docker-compose up llm
   ```

2. **Start the frontend (in a new terminal):**
   ```bash
   cd frontend
   node server.js
   ```

3. **Open the demo:**
   - Frontend: http://localhost:3000
   - LLM API: http://localhost:8001

### 🎯 **Live Demo Ready!**

Your team can now interact with the AI chatbot:
- **Real AI responses** from TinyLlama running locally
- **Beautiful interface** with typing indicators
- **Status monitoring** showing service health
- **Demo instructions** built into the UI

**Try these demo questions:**
- "Hello! How are you?"
- "What can you help me with?"
- "Explain quantum computing in simple terms"

## 🛠️ Technology Stack

### AI Services
- **LLM**: vLLM or llama.cpp with Llama 3.1 8B Instruct
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

## 🤖 LLM Service Implementation (Part A & B Complete ✅)

### What We Built

We've successfully implemented **Parts A & B** of the LLM service, creating a fully functional AI chatbot backend with real AI responses:

#### 🏗️ **Architecture Overview**
```
┌─────────────────┐
│   FastAPI       │  OpenAI-compatible API wrapper
│   (Port 8001)   │  /healthz, /v1/chat/completions
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
- **`services/llm/download_model.py`** - Model download script for Llama 3.1 8B
- **`services/llm/model_config.json`** - Model configuration (GGUF format)
- **`services/llm/setup_model.sh`** - Model setup automation
- **Updated `docker-compose.yml`** - LLM service configuration with health checks

#### 🚀 **Key Features Implemented**
- ✅ **Health Monitoring**: `/healthz` endpoint with service status
- ✅ **OpenAI Compatibility**: `/v1/chat/completions` endpoint matching OpenAI API
- ✅ **Real AI Responses**: Working TinyLlama model generating thoughtful responses
- ✅ **llama.cpp Integration**: Compiled from source with OpenBLAS optimization
- ✅ **Docker Integration**: Multi-stage build with proper library management
- ✅ **Model Management**: TinyLlama 1.1B model (638MB) for fast testing
- ✅ **Error Handling**: Robust error handling and graceful degradation
- ✅ **Prometheus Metrics**: Comprehensive monitoring and observability

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

# Prometheus metrics
curl http://localhost:8001/metrics
# Response: Detailed metrics including request counts, token counts, etc.
```

#### 🎯 **Current Status: FULLY OPERATIONAL**
- 🟢 **Service**: Running and healthy (`model_loaded: true`)
- 🟢 **API**: All endpoints working (`/healthz`, `/v1/chat/completions`, `/metrics`)
- 🟢 **AI**: Generating real, helpful responses using TinyLlama
- 🟢 **Monitoring**: Prometheus metrics active and collecting data
- 🟡 **Next**: Part C (SSE streaming) and Part D (performance tuning)

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

### Phase 1: Foundations
- ✅ Project setup and infrastructure

### Phase 2: Core AI Services
- ✅ **LLM service implementation** (Part A Complete)
- 🔲 Speech-to-Text service
- 🔲 Text-to-Speech service

### Phase 3: RAG
- 🔲 RAG service with vector search

### Phase 4: Orchestration
- 🔲 FastAPI coordination layer

### Phase 5: Frontend (Issue 7 - Complete ✅)
- ✅ **Chatbot Interface** - Working HTML frontend with real-time chat
- ✅ **Local LLM Integration** - Connected to TinyLlama backend
- ✅ **Demo Ready** - Team presentation interface available

### Phase 6: Observability & Hardening
- 🔲 Monitoring and alerting
- 🔲 Production deployment
- 🔲 Performance optimization

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

**Status**: 🚧 Active Development | **Phase**: 1 - Foundations

