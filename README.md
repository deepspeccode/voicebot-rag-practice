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
- Docker Desktop with GPU support (optional but recommended)
- Node.js 18+
- Python 3.10+
- GitHub CLI

### Setup

1. **Clone and configure:**
   ```bash
   git clone https://github.com/deepspeccode/voicebot-rag-practice.git
   cd voicebot-rag-practice
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Start services:**
   ```bash
   docker compose up -d
   ```

3. **Verify health:**
   ```bash
   curl http://localhost:8080/healthz
   ```

4. **Access the UI:**
   - Frontend: http://localhost:3000
   - API: http://localhost:8080

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

## 📚 Project Phases

This project is organized into 6 phases with 10 tasks:

### Phase 1: Foundations
- ✅ Project setup and infrastructure

### Phase 2: Core AI Services
- 🔲 LLM service implementation
- 🔲 Speech-to-Text service
- 🔲 Text-to-Speech service

### Phase 3: RAG
- 🔲 RAG service with vector search

### Phase 4: Orchestration
- 🔲 FastAPI coordination layer

### Phase 5: Frontend
- 🔲 Next.js UI with push-to-talk

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

