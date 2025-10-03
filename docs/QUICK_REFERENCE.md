# LLM Service - Quick Reference

## 🚀 Quick Start

```bash
# Deploy LLM service (modular approach)
./scripts/deploy-llm.sh

# Or use docker-compose directly
docker-compose up llm
```

## 🔍 Health Checks

```bash
# Check service health
curl http://localhost:8001/healthz

# Expected response:
{
  "status": "ok",
  "model_loaded": true,
  "uptime": 1234567890.123
}
```

## 💬 API Usage

```bash
# Chat completion (non-streaming)
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello!"}]}'

# Chat completion (streaming)
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello!"}], "stream": true}'
```

## 🛠️ Management Commands

```bash
# View logs
docker-compose logs -f llm

# Stop service
docker-compose down llm

# Restart service
docker-compose restart llm

# Rebuild service
docker-compose build llm
docker-compose up -d llm
```

## 📊 Monitoring

```bash
# Check container status
docker-compose ps llm

# View resource usage
docker stats voicebot-llm

# Access container shell
docker-compose exec llm bash
```

## 🔧 Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_NAME` | `llama-3.1-8b-instruct` | Model identifier |
| `MODEL_PATH` | `/models/llama-3.1-8b-instruct.Q4_K_M.gguf` | Model file path |
| `PORT` | `8001` | Service port |

## 🚨 Troubleshooting

```bash
# Service won't start
docker-compose logs llm

# Port already in use
lsof -i :8001

# Model not found
docker-compose exec llm ls -la /models/

# High memory usage
docker stats voicebot-llm
```

## 📁 Key Files

- `services/llm/main.py` - FastAPI application
- `services/llm/Dockerfile` - Container build
- `docker-compose.yml` - Service orchestration
- `scripts/deploy-llm.sh` - Deployment script
- `docs/LLM_SERVICE_DEPLOYMENT.md` - Full deployment guide

## 🎯 Status

- ✅ **Part A Complete**: Basic service with OpenAI-compatible API
- 🔄 **Part B Next**: Integrate actual llama.cpp inference
- 🔄 **Part C Next**: Real streaming implementation
- 🔄 **Part D Next**: Performance optimization

---

**Service URL**: http://localhost:8001  
**Health Check**: http://localhost:8001/healthz  
**API Docs**: http://localhost:8001/docs
