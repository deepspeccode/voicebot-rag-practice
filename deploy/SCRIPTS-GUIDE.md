# Quick Reference - Voicebot RAG

Essential commands for daily development and deployment.

## 🚀 Deployment

### Fresh Deployment
```bash
./deploy/MASTER-DEPLOY.sh
# Follow on-screen instructions
```

### Connect to Instance
```bash
aws ssm start-session --target i-YOUR-INSTANCE-ID --region us-east-1
```

---

## 💰 Cost Management

### Stop Instance (When Done Working)
```bash
aws ec2 stop-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1
```

### Start Instance (Resume Work)
```bash
aws ec2 start-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1

# Get new IP after starting:
aws ec2 describe-instances \
  --instance-ids i-051cb6ac6bf116c23 \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

### Check Instance Status
```bash
aws ec2 describe-instances \
  --instance-ids i-051cb6ac6bf116c23 \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
```

---

## 🐳 Docker Commands (On EC2)

### Service Management
```bash
# Start all services
docker compose up -d app postgres prometheus grafana

# Stop all services
docker compose down

# Restart a service
docker compose restart app

# View status
docker compose ps

# View logs
docker compose logs -f app
docker compose logs -f postgres

# Rebuild after code changes
docker compose up -d --build app
```

### Container Management
```bash
# List running containers
docker ps

# View resource usage
docker stats

# Remove all stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Full cleanup (careful!)
docker system prune -a --volumes
```

---

## 🧪 Testing

### From Your Mac

**Health Check:**
```bash
curl http://54.167.82.36:8080/healthz
```

**Root Endpoint:**
```bash
curl http://54.167.82.36:8080/
```

**Chat (Non-Streaming):**
```bash
curl -X POST http://54.167.82.36:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Test message", "stream": false}'
```

**Chat (Streaming):**
```bash
curl -X POST http://54.167.82.36:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Test streaming", "stream": true}' \
  --no-buffer
```

### On EC2

**Local Health Check:**
```bash
curl http://localhost:8080/healthz
```

**Check Service Dependencies:**
```bash
# Test if services can reach each other
docker exec voicebot-app curl http://postgres:5432
docker exec voicebot-app ping -c 3 llm
```

---

## 📋 File Locations

### On EC2:
- Application: `/opt/app/`
- Environment: `/opt/app/.env`
- Docker Compose: `/opt/app/docker-compose.yml`
- Setup log: `/var/log/voicebot-setup.log`
- Repository: `/home/ubuntu/voicebot-rag-practice/`

### On Your Mac:
- Deployment info: `deployment-info.txt`
- State file: `~/.voicebot-deploy-state`
- Scripts: `deploy/`

---

## 🔧 Configuration

### Edit Environment Variables (On EC2)
```bash
vim /opt/app/.env
# After changes:
docker compose restart app
```

### View Current Config (Hide Secrets)
```bash
cat /opt/app/.env | grep -v SECRET | grep -v PASSWORD
```

### Update Single Service (On EC2)
```bash
cd /opt/app/services/app
# Edit files
docker compose up -d --build app
```

---

## 📊 Monitoring

### Access Dashboards
- **Prometheus**: http://YOUR-IP:9090
- **Grafana**: http://YOUR-IP:3001 (admin/admin)

### Check Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app

# Last 100 lines
docker compose logs --tail=100 app

# Since specific time
docker compose logs --since 1h app
```

### System Resources (On EC2)
```bash
# CPU and memory
htop

# Disk space
df -h

# Docker usage
docker system df
```

---

## 🔐 Security

### Update Grafana Password (On EC2)
```bash
vim /opt/app/.env
# Change: GRAFANA_ADMIN_PASSWORD
docker compose restart grafana
```

### Update Database Password (On EC2)
```bash
vim /opt/app/.env
# Change: PG_DSN password
docker compose restart postgres app
```

### View Security Group Rules
```bash
aws ec2 describe-security-groups \
  --group-ids sg-YOUR-SG-ID \
  --query 'SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]' \
  --output table
```

---

## 🐛 Debugging

### Check Service Health (On EC2)
```bash
# Inside container
docker exec -it voicebot-app bash
# Run commands inside container

# Check network
docker network inspect app_default

# Check volumes
docker volume ls
docker volume inspect app_rag_data
```

### Application Errors
```bash
# On EC2:
docker compose logs app --tail=50

# Check Python errors
docker exec voicebot-app python -c "import fastapi; print(fastapi.__version__)"
```

### Database Issues
```bash
# Connect to Postgres
docker exec -it voicebot-postgres psql -U user -d rag

# Inside psql:
\dt  -- List tables
\q   -- Quit
```

---

## 📦 Backup & Restore

### Backup Environment
```bash
# On EC2:
cp /opt/app/.env /opt/app/.env.backup.$(date +%Y%m%d)
```

### Backup Database
```bash
# On EC2:
docker exec voicebot-postgres pg_dump -U user rag > backup.sql
```

### Create AMI Snapshot
```bash
# From Mac:
aws ec2 create-image \
  --instance-id i-YOUR-ID \
  --name "voicebot-rag-snapshot-$(date +%Y%m%d)" \
  --description "Voicebot RAG configured instance" \
  --region us-east-1
```

---

## 🎯 Current Instance Info

**Instance ID**: `i-051cb6ac6bf116c23`  
**Public IP**: `54.167.82.36`  
**Region**: `us-east-1`  
**Type**: `c7i-flex.large`  

### Quick Commands for This Instance:

```bash
# Connect
aws ssm start-session --target i-051cb6ac6bf116c23 --region us-east-1

# Stop
aws ec2 stop-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1

# Start  
aws ec2 start-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1

# Status
aws ec2 describe-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1 --query 'Reservations[0].Instances[0].State.Name'

# Terminate (when completely done)
aws ec2 terminate-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1
```

### Test Endpoints:

```bash
# Health
curl http://54.167.82.36:8080/healthz

# API Info
curl http://54.167.82.36:8080/

# Chat
curl -X POST http://54.167.82.36:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!", "stream": false}'
```

---

## 📅 Daily Workflow

### Morning (Start Work):
```bash
# 1. Start instance
aws ec2 start-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1

# 2. Get IP (might have changed)
aws ec2 describe-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# 3. Connect
aws ssm start-session --target i-051cb6ac6bf116c23 --region us-east-1

# 4. Start services (if not auto-started)
cd /opt/app
docker compose up -d app postgres prometheus grafana
```

### Evening (End Work):
```bash
# 1. Stop services (optional - saves minimal cost)
docker compose down

# 2. Stop instance (IMPORTANT - saves money!)
aws ec2 stop-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1
```

---

## 🎓 Learning Resources

- **Docker Compose**: https://docs.docker.com/compose/
- **FastAPI**: https://fastapi.tiangolo.com/
- **AWS EC2**: https://docs.aws.amazon.com/ec2/
- **Systems Manager**: https://docs.aws.amazon.com/systems-manager/

---

**Last Updated**: October 1, 2025  
**Instance**: i-051cb6ac6bf116c23  
**Status**: ✅ Running and accessible

