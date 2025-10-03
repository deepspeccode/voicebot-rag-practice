# LLM Service Deployment Guide

## Overview

This document provides comprehensive guidance on deploying the LLM service as a modular component of the voicebot-rag-practice system. The LLM service is designed to be **modular, scriptable, and production-ready**.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    LLM Service Module                       │
├─────────────────────────────────────────────────────────────┤
│  FastAPI Wrapper (Port 8001)                               │
│  ├── /healthz (Health monitoring)                          │
│  ├── /v1/chat/completions (OpenAI-compatible API)          │
│  ├── /metrics (Prometheus metrics)                         │
│  └── SSE Streaming support                                  │
├─────────────────────────────────────────────────────────────┤
│  llama.cpp Engine (Internal)                               │
│  ├── CPU-optimized inference                                │
│  ├── OpenBLAS acceleration                                 │
│  └── GGUF model format (Llama 3.1 8B)                      │
└─────────────────────────────────────────────────────────────┘
```

## 📁 File Structure

```
services/llm/
├── Dockerfile              # Multi-stage container build
├── main.py                 # FastAPI application
├── requirements.txt        # Python dependencies
├── download_model.py       # Model download automation
├── model_config.json       # Model configuration
└── setup_model.sh          # Setup automation

scripts/
└── deploy-llm.sh           # Modular deployment script

docker-compose.yml           # Service orchestration
```

## 🚀 Deployment Options

### Option 1: Standalone Script (Recommended)

**Use Case**: Development, testing, and simple deployments

```bash
# Deploy using the modular script
./scripts/deploy-llm.sh
```

**Benefits**:
- ✅ Automated health checks
- ✅ Error handling and rollback
- ✅ Comprehensive testing
- ✅ Clear success/failure feedback

### Option 2: Docker Compose

**Use Case**: Local development and testing

```bash
# Start LLM service only
docker-compose up llm

# Start with other services
docker-compose up llm app nginx
```

### Option 3: Kubernetes

**Use Case**: Production deployments

```yaml
# k8s/llm-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: llm-service
  labels:
    app: llm-service
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
        - name: MODEL_NAME
          value: "llama-3.1-8b-instruct"
        resources:
          requests:
            memory: "8Gi"
            cpu: "2"
          limits:
            memory: "16Gi"
            cpu: "4"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8001
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8001
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: llm-service
spec:
  selector:
    app: llm-service
  ports:
  - port: 8001
    targetPort: 8001
  type: ClusterIP
```

### Option 4: Terraform Module

**Use Case**: Infrastructure as Code

```hcl
# terraform/modules/llm-service/main.tf
resource "docker_container" "llm_service" {
  name  = "voicebot-llm"
  image = "voicebot-llm:latest"
  
  ports {
    internal = 8001
    external = var.port
  }
  
  env = [
    "MODEL_PATH=${var.model_path}",
    "MODEL_NAME=${var.model_name}"
  ]
  
  volumes {
    host_path      = var.model_volume_path
    container_path = "/models"
  }
  
  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost:8001/healthz"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
}

# terraform/llm-service.tf
module "llm_service" {
  source = "./modules/llm-service"
  
  model_name        = "llama-3.1-8b-instruct"
  model_path        = "/models/llama-3.1-8b-instruct.Q4_K_M.gguf"
  model_volume_path = "/opt/models"
  port              = 8001
}
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_NAME` | `llama-3.1-8b-instruct` | Model identifier |
| `MODEL_PATH` | `/models/llama-3.1-8b-instruct.Q4_K_M.gguf` | Path to model file |
| `CUDA_VISIBLE_DEVICES` | `0` | GPU device (0 for CPU) |

### Resource Requirements

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| **Development** | 2 cores | 8GB | 10GB |
| **Production** | 4 cores | 16GB | 20GB |
| **Model Storage** | - | - | 5-8GB |

## 🧪 Testing & Validation

### Health Checks

```bash
# Basic health check
curl http://localhost:8001/healthz

# Expected response:
{
  "status": "ok",
  "model_loaded": true,
  "uptime": 1234567890.123
}
```

### API Testing

```bash
# Test chat completions
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "temperature": 0.7,
    "max_tokens": 100
  }'

# Test streaming
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "stream": true
  }'
```

### Load Testing

```bash
# Install hey (load testing tool)
go install github.com/rakyll/hey@latest

# Run load test
hey -n 100 -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello!"}]}' \
  http://localhost:8001/v1/chat/completions
```

## 📊 Monitoring

### Metrics Endpoints

- **Health**: `GET /healthz`
- **Metrics**: `GET /metrics` (Prometheus format)
- **OpenAPI Docs**: `GET /docs`

### Key Metrics

- `llm_service_requests_total` - Total requests
- `llm_service_request_duration_seconds` - Request latency
- `llm_service_tokens_total` - Tokens generated

### Logging

```bash
# View service logs
docker-compose logs -f llm

# View specific log levels
docker-compose logs -f llm | grep ERROR
```

## 🔄 Maintenance

### Updates

```bash
# Update service
docker-compose pull llm
docker-compose up -d llm

# Rebuild with changes
docker-compose build llm
docker-compose up -d llm
```

### Model Updates

```bash
# Download new model
docker-compose exec llm python download_model.py

# Restart with new model
docker-compose restart llm
```

### Backup

```bash
# Backup model files
docker run --rm -v voicebot_llm_models:/data -v $(pwd):/backup alpine tar czf /backup/models-backup.tar.gz -C /data .

# Restore model files
docker run --rm -v voicebot_llm_models:/data -v $(pwd):/backup alpine tar xzf /backup/models-backup.tar.gz -C /data
```

## 🚨 Troubleshooting

### Common Issues

1. **Service won't start**
   ```bash
   # Check logs
   docker-compose logs llm
   
   # Check port availability
   lsof -i :8001
   ```

2. **Model not found**
   ```bash
   # Check model path
   docker-compose exec llm ls -la /models/
   
   # Download model
   docker-compose exec llm python download_model.py
   ```

3. **High memory usage**
   ```bash
   # Check resource usage
   docker stats voicebot-llm
   
   # Adjust memory limits in docker-compose.yml
   ```

### Debug Commands

```bash
# Container shell access
docker-compose exec llm bash

# Check service status
docker-compose ps llm

# View resource usage
docker stats voicebot-llm

# Test connectivity
curl -v http://localhost:8001/healthz
```

## 🔒 Security Considerations

### Production Hardening

1. **Network Security**
   - Use internal networks only
   - Implement TLS termination
   - Configure firewall rules

2. **Authentication**
   - Add API key authentication
   - Implement rate limiting
   - Use request validation

3. **Resource Limits**
   - Set memory and CPU limits
   - Implement request timeouts
   - Monitor resource usage

## 📈 Performance Optimization

### CPU Optimization

```yaml
# docker-compose.yml
llm:
  environment:
    - OMP_NUM_THREADS=4
    - MKL_NUM_THREADS=4
  deploy:
    resources:
      limits:
        cpus: '4'
        memory: 16G
```

### Model Optimization

- Use quantized models (Q4_K_M)
- Optimize context length
- Tune batch size parameters

## 🎯 Next Steps

1. **Part B**: Integrate actual llama.cpp inference
2. **Part C**: Implement real streaming
3. **Part D**: Performance tuning
4. **Production**: Add authentication and monitoring

---

**Status**: ✅ Part A Complete | **Next**: Part B Implementation
