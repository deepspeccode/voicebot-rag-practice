# 🎯 Next Steps - After EC2 Setup Completes

## ✅ Step 1: Verify Setup is Complete

Run this command every few minutes until you get a JSON response:

```bash
curl http://54.167.82.36:8080/healthz
```

**Success looks like:**
```json
{
  "status": "ok",
  "services": {
    "app": "ok",
    "llm": "unknown",
    "stt": "unknown",
    "tts": "unknown",
    "rag": "unknown"
  }
}
```

If you get connection errors, wait 5 more minutes and try again.

---

## ✅ Step 2: Connect to Your Instance

Once the health check works:

```bash
# Connect via SSM (no SSH key needed!)
aws ssm start-session --target i-051cb6ac6bf116c23 --region us-east-1
```

**Once connected**, switch to ubuntu user:
```bash
sudo su - ubuntu
cd ~
```

---

## ✅ Step 3: Verify the Setup

Check that everything was installed:

```bash
# Check Docker
docker --version
docker compose version

# Check directories
ls -la /opt/app/

# Check environment file
ls -la /opt/app/.env

# Verify you're in docker group
groups | grep docker
```

**Expected output:**
- Docker version 24.x+
- Docker Compose version 2.x+
- `/opt/app/` directory with subdirectories
- `.env` file with 600 permissions
- You should be in the docker group

---

## ✅ Step 4: Configure Environment Variables

Edit the environment file with actual values:

```bash
vim /opt/app/.env
```

**Critical values to update:**

```bash
# Database (change the password!)
PG_DSN=postgresql://user:CHANGE_THIS_PASSWORD@postgres:5432/rag

# Storage (use your actual bucket name)
S3_BUCKET=voicebot-practice-YOUR-NAME

# CORS (use your actual domain or public IP)
CORS_ORIGINS=http://54.167.82.36,http://localhost:3000

# Grafana admin (change this!)
GRAFANA_ADMIN_PASSWORD=YOUR_SECURE_PASSWORD_HERE

# JWT_SECRET is already randomly generated - leave it as is
```

**Save and exit**: Press `Esc`, type `:wq`, press Enter

---

## ✅ Step 5: Deploy Your Application

Clone your repository and start services:

```bash
cd /opt/app

# Clone your repo
git clone https://github.com/deepspeccode/voicebot-rag-practice.git .

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f app
```

**Expected output:**
All services should show "Up" status:
- app
- postgres
- prometheus
- grafana

(llm, stt, tts, rag will fail - we haven't implemented them yet!)

---

## ✅ Step 6: Test Your API

From your **local Mac terminal** (not EC2):

```bash
# Test health check
curl http://54.167.82.36:8080/healthz

# Test root endpoint
curl http://54.167.82.36:8080/

# Test chat endpoint (streaming)
curl -X POST http://54.167.82.36:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from the cloud!", "stream": true}'
```

**Success**: You should see JSON responses!

---

## ✅ Step 7: Access Monitoring Dashboards

### Prometheus (Metrics)
```
http://54.167.82.36:9090
```

### Grafana (Dashboards)
```
http://54.167.82.36:3001
```
- **Username**: admin
- **Password**: (the one you set in .env, or default: admin)

---

## 🎉 Step 8: You're Ready for Task 1!

Now you have a working production environment! Time to implement the LLM service.

### Start Task 1: LLM Service

1. **Create a feature branch:**
   ```bash
   cd ~/voicebot-rag-practice  # On your local Mac
   git checkout -b feat/task-1-llm-service
   ```

2. **Check the GitHub issue:**
   ```bash
   gh issue view 2
   ```

3. **Create the LLM service files:**
   ```bash
   # Create directory structure
   mkdir -p services/llm
   cd services/llm
   
   # You'll create:
   # - Dockerfile
   # - main.py or server.py
   # - requirements.txt
   # - README.md
   ```

4. **Choose your approach:**
   - **vLLM** (recommended for GPU) - Fast, production-ready
   - **llama.cpp** (CPU-friendly) - Works without GPU
   - **Ollama** (easiest) - Simple to set up

---

## 💰 Remember: Cost Management

### Stop Instance When Not Using

**From your local Mac:**
```bash
# Stop instance (saves compute costs)
aws ec2 stop-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1

# Check status
aws ec2 describe-instances \
  --instance-ids i-051cb6ac6bf116c23 \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].State.Name'

# Start again when needed
aws ec2 start-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1

# Get new IP after restart
aws ec2 describe-instances \
  --instance-ids i-051cb6ac6bf116c23 \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

**Cost reminder:**
- **Running**: ~$0.08/hour (~$60/month if 24/7)
- **Stopped**: ~$4/month (just storage)
- **You have $100 free credits** - they'll last 2+ months if you stop when not using!

---

## 🆘 Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
sudo systemctl status docker

# Check logs
docker compose logs

# Restart Docker
sudo systemctl restart docker

# Try starting services one by one
docker compose up app
```

### Can't Connect to Instance

```bash
# Check instance is running
aws ec2 describe-instances \
  --instance-ids i-051cb6ac6bf116c23 \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].State.Name'

# Start if stopped
aws ec2 start-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1
```

### API Not Responding

```bash
# Check if services are running
docker compose ps

# Check app logs
docker compose logs app

# Restart the app service
docker compose restart app
```

### Need to Re-run Setup

If something went wrong during setup:

```bash
# Connect to instance
aws ssm start-session --target i-051cb6ac6bf116c23 --region us-east-1

# Switch to ubuntu user
sudo su - ubuntu

# Re-run setup script
cd ~/voicebot-rag-practice
./deploy/setup-production.sh
```

---

## 📚 Useful Commands Reference

### Docker Compose Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f app

# Restart a service
docker compose restart app

# Rebuild after code changes
docker compose up -d --build app

# Check resource usage
docker stats
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feat/my-feature

# Make changes and commit
git add .
git commit -m "feat: description of changes"

# Push to GitHub
git push -u origin feat/my-feature

# Create PR
gh pr create --fill
```

### System Commands

```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
htop  # or: top

# Check network connections
netstat -tlnp

# View system logs
sudo journalctl -f
```

---

## 🎯 Quick Win: Your First API Request

Once everything is up, try this from your Mac:

```bash
# Create a simple test script
cat > test-api.sh << 'EOF'
#!/bin/bash
echo "Testing Voicebot RAG API..."
echo ""
echo "1. Health Check:"
curl -s http://54.167.82.36:8080/healthz | jq
echo ""
echo "2. Root Endpoint:"
curl -s http://54.167.82.36:8080/ | jq
echo ""
echo "3. Chat Endpoint:"
curl -s -X POST http://54.167.82.36:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from the cloud!", "stream": false}' | jq
echo ""
echo "✅ All tests complete!"
EOF

chmod +x test-api.sh
./test-api.sh
```

---

## 📖 Learning Resources

### For Task 1 (LLM Service):
- **vLLM Docs**: https://docs.vllm.ai/
- **llama.cpp**: https://github.com/ggerganov/llama.cpp
- **Ollama**: https://ollama.ai/
- **Llama Models**: https://huggingface.co/meta-llama

### General:
- **Docker Compose**: https://docs.docker.com/compose/
- **FastAPI**: https://fastapi.tiangolo.com/
- **AWS EC2**: https://docs.aws.amazon.com/ec2/

---

## 🎉 Congratulations!

When you complete all the steps above, you'll have:

✅ Production-ready infrastructure on AWS  
✅ Working FastAPI application  
✅ Monitoring with Prometheus and Grafana  
✅ Environment configured  
✅ Ready to implement AI services  

**You've completed Task 0 (Part B) - Production Infrastructure Setup!**

Now you're ready to move on to Task 1: Implementing the LLM service! 🚀

---

**Questions or stuck?** Check the troubleshooting section or review:
- `deploy/DEPLOYMENT_GUIDE.md`
- `GETTING_STARTED.md`
- `PROJECT_TRACKING.md`

