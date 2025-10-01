# Troubleshooting Guide

Common issues and their solutions.

## 🔌 Connection Issues

### Can't Connect to EC2 via SSM

**Error**: `AccessDeniedException` or `User is not authorized to perform: ssm:StartSession`

**Solution**:
```bash
# Add SSM permissions to your IAM user
aws iam attach-user-policy \
  --user-name YOUR-USERNAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess

# Wait 1-2 minutes for propagation, then try again
aws ssm start-session --target i-YOUR-INSTANCE-ID --region us-east-1
```

### SSM Session Immediately Closes

**Error**: `Cannot perform start session: EOF`

**Cause**: SSM agent still initializing on new instance

**Solution**: Wait 2-3 minutes after instance launches, then retry

---

## 🐳 Docker Issues

### "Permission Denied" when running Docker

**Error**: `Got permission denied while trying to connect to the Docker daemon`

**Solution**:
```bash
# On EC2:
newgrp docker
# OR log out and back in

# Verify
docker ps
```

### Services Won't Start

**Error**: Various Docker Compose errors

**Solution**:
```bash
# On EC2:
cd /opt/app

# Check what's wrong
docker compose ps
docker compose logs

# Stop everything
docker compose down

# Remove problematic containers
docker compose rm -f

# Start fresh
docker compose up -d app postgres prometheus grafana

# Watch logs
docker compose logs -f
```

### "Port Already in Use"

**Error**: `Bind for 0.0.0.0:8080 failed: port is already allocated`

**Solution**:
```bash
# Find what's using the port
sudo lsof -i :8080

# Stop the conflicting service
docker stop CONTAINER-ID

# Or stop all services and restart
docker compose down
docker compose up -d app postgres prometheus grafana
```

### Prometheus Config Error

**Error**: `error mounting prometheus.yml: not a directory`

**Solution**:
```bash
# On EC2:
rm -rf /opt/app/monitoring/prometheus/prometheus.yml

cat > /opt/app/monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['app:8080']
EOF

docker compose down
docker compose up -d app postgres prometheus grafana
```

---

## 🌐 API Not Responding

### Health Check Returns Nothing

**Test**:
```bash
curl -v http://YOUR-IP:8080/healthz
```

**If "Connection refused"**:
- App isn't running
- Solution: `docker compose up -d app`

**If "Connection timeout"**:
- Port 8080 not open in security group
- Solution:
  ```bash
  aws ec2 authorize-security-group-ingress \
    --group-id sg-YOUR-SG-ID \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 \
    --region us-east-1
  ```

**If "No route to host"**:
- Instance stopped or terminated
- Solution: Start instance

### API Returns 500 Error

**Check logs**:
```bash
# On EC2:
docker compose logs app | tail -100
```

**Common causes**:
- Missing environment variables
- Can't connect to dependent services
- Python exception in code

**Solution**:
```bash
# Check environment
cat /opt/app/.env | grep -v SECRET

# Restart with fresh logs
docker compose restart app
docker compose logs -f app
```

---

## 📦 Repository Issues

### Can't Clone Private Repo on EC2

**Error**: `Authentication failed for https://github.com/...`

**Solution Option 1 - Make Repo Public**:
```bash
# On your Mac:
gh repo edit YOUR-REPO --visibility public --accept-visibility-change-consequences
```

**Solution Option 2 - Use wget**:
```bash
# On EC2 (for public repos):
wget https://github.com/USER/REPO/archive/refs/heads/main.zip
unzip main.zip
mv REPO-main REPO
```

**Solution Option 3 - Use GitHub Token**:
```bash
# On EC2:
git clone https://YOUR-TOKEN@github.com/USER/REPO.git
```

---

## ⚙️ Setup Script Issues

### setup-production.sh Fails

**Check logs**:
```bash
# On EC2:
cat /var/log/voicebot-setup.log
# Or if running manually:
./deploy/setup-production.sh 2>&1 | tee setup-debug.log
```

**Common Issues**:

**1. "apt update" fails**
- Network issue
- Wait and retry
- Solution: `sudo apt update`

**2. Docker installation fails**
- GPG key issue
- Repository not added correctly
- Solution: Follow manual Docker installation docs

**3. "Permission denied" creating /opt/app**
- Running as wrong user
- Solution: Script uses `sudo` internally - run as ubuntu user

**4. Environment file not created**
- openssl not installed
- Solution: `sudo apt install -y openssl`

### GPU Setup Fails

**Error**: `nvidia-smi command not found` after reboot

**Solution**:
```bash
# Check driver installation
dpkg -l | grep nvidia-driver

# Reinstall if needed
sudo apt install -y nvidia-driver-535
sudo reboot

# After reboot, verify
nvidia-smi
```

---

## 🗄️ Database Issues

### Postgres Won't Start

**Error**: `could not start container`

**Solution**:
```bash
# Check logs
docker compose logs postgres

# Common issue: port 5432 in use
sudo lsof -i :5432

# Remove old data (if safe)
docker compose down -v  # WARNING: Deletes data!
docker compose up -d postgres
```

### Can't Connect to Postgres

**Test connection**:
```bash
# On EC2:
docker exec -it voicebot-postgres psql -U user -d rag
```

**If fails**:
- Check password in .env matches docker-compose.yml
- Verify postgres container is running: `docker ps`
- Check logs: `docker compose logs postgres`

---

## 💸 Cost Issues

### Unexpected High Bill

**Check costs**:
```bash
# Current month
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost
```

**Common causes**:
- Instance running 24/7
- Large EBS volume
- Data transfer charges

**Solution**:
```bash
# Stop ALL running instances
aws ec2 stop-instances \
  --instance-ids $(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)
```

### Credits Not Applied

**Check Free Tier usage**:
- Go to: https://console.aws.amazon.com/billing/home#/freetier

**Check credits**:
- Go to: https://console.aws.amazon.com/billing/home#/credits

**Note**: Credits apply automatically - you don't need to do anything

---

## 🔄 Recovery Scenarios

### Lost Instance IP

**Get IP of running instance**:
```bash
aws ec2 describe-instances \
  --instance-ids i-YOUR-ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

**Find instance by tag**:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=voicebot-rag" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name]' \
  --output table
```

### Forgot Instance ID

**List all your instances**:
```bash
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PublicIpAddress]' \
  --output table
```

### Setup Script Incomplete

**Re-run setup**:
```bash
# On EC2:
cd ~/voicebot-rag-practice
./deploy/setup-production.sh

# Script is idempotent - safe to run multiple times
```

### Docker Compose File Corrupted

**Redownload**:
```bash
# On EC2:
cd /opt/app
wget https://raw.githubusercontent.com/deepspeccode/voicebot-rag-practice/main/docker-compose.yml
docker compose up -d app postgres prometheus grafana
```

---

## 🚨 Emergency Procedures

### Stop All Services Immediately

```bash
# On EC2:
docker compose down

# Or from Mac:
aws ec2 stop-instances --instance-ids i-YOUR-ID
```

### Delete Everything and Start Over

```bash
# Terminate instance
aws ec2 terminate-instances --instance-ids i-YOUR-ID --region us-east-1

# Remove state file
rm ~/.voicebot-deploy-state

# Run deployment again
./deploy/MASTER-DEPLOY.sh
```

### Instance Not Responding

```bash
# Reboot instance
aws ec2 reboot-instances --instance-ids i-YOUR-ID --region us-east-1

# Wait 2 minutes, then reconnect
```

---

## 📞 Getting Help

### Check Documentation
1. `README.md` - Project overview
2. `GETTING_STARTED.md` - Initial setup
3. `NEXT-STEPS.md` - After deployment
4. `deploy/DEPLOYMENT_GUIDE.md` - Full deployment guide
5. `deploy/SCRIPTS-GUIDE.md` - Script reference
6. `CHECKPOINTS.md` - Version history

### View GitHub Issues
```bash
gh issue list
gh issue view 1  # Task 0
```

### Check Logs
```bash
# On EC2:
cat /var/log/voicebot-setup.log  # Setup script
docker compose logs app  # Application
sudo journalctl -xe  # System logs
```

### Debug Mode

**Run app in debug mode**:
```bash
# On EC2, edit .env:
vim /opt/app/.env
# Set: DEBUG=true
# Set: LOG_LEVEL=DEBUG

# Restart
docker compose restart app

# Watch detailed logs
docker compose logs -f app
```

---

## 🎯 Quick Fixes

### App Won't Start
```bash
cd /opt/app
docker compose down
docker compose up app  # No -d to see errors
```

### Out of Disk Space
```bash
df -h  # Check space
docker system prune -a  # Clean up
```

### Forgot Admin Password
```bash
# Reset Grafana:
vim /opt/app/.env  # Change GRAFANA_ADMIN_PASSWORD
docker compose restart grafana
```

### Wrong Region
```bash
# Check state file
cat ~/.voicebot-deploy-state

# All AWS commands need: --region YOUR-REGION
```

---

**Still stuck?** Check the full guides or create a GitHub issue for help!

