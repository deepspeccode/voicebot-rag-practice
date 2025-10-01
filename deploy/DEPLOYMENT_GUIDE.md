# Production Deployment Guide

This guide covers **Part B** of Task 0: Setting up the production infrastructure on EC2.

## 📋 Overview

You have **three options** for setting up your production environment, listed from easiest to most advanced:

1. **🎯 Automated Setup Script** (Recommended for learning)
2. **🚀 EC2 User Data** (For new instances)
3. **⚙️ Manual Setup** (Not recommended - error-prone)

---

## Option 1: Automated Setup Script ⭐ RECOMMENDED

This is the **best option for learning** because:
- ✅ You see exactly what's happening
- ✅ Easy to understand and modify
- ✅ Can run multiple times safely
- ✅ Good error handling
- ✅ No manual typing errors

### Prerequisites

1. **EC2 Instance Running**
   - Ubuntu 22.04 LTS
   - t3.medium or larger (t3.large+ recommended for AI workloads)
   - At least 50GB storage
   - Security group allowing ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (API)

2. **Access to Instance**
   - SSH key pair configured
   - Or AWS Systems Manager (SSM) Session Manager access

### Step-by-Step Instructions

#### 1. Connect to Your EC2 Instance

**Option A: Via SSH**
```bash
ssh -i your-key.pem ubuntu@your-instance-ip
```

**Option B: Via AWS Systems Manager** (Recommended - no SSH key needed)
```bash
# Install Session Manager plugin first:
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Then connect:
aws ssm start-session --target i-1234567890abcdef0
```

#### 2. Download the Setup Script

```bash
# Clone your repository
git clone https://github.com/deepspeccode/voicebot-rag-practice.git
cd voicebot-rag-practice

# Make the script executable
chmod +x deploy/setup-production.sh
```

#### 3. Run the Setup Script

**For CPU-only instances:**
```bash
./deploy/setup-production.sh
```

**For GPU instances (g4dn, g5, p3, p4, etc.):**
```bash
./deploy/setup-production.sh --gpu
```

> **Note:** GPU setup will reboot the instance. After reboot, reconnect and run the script again with `--gpu` to complete GPU configuration.

#### 4. Monitor the Setup

The script will:
- Update system packages (~2-5 minutes)
- Install Docker (~3-5 minutes)
- Create directory structure (~10 seconds)
- Generate environment file (~5 seconds)
- (Optional) Install GPU drivers (~5-10 minutes + reboot)

Total time: **5-10 minutes** (CPU) or **15-20 minutes** (GPU)

#### 5. Configure Environment

After setup completes:

```bash
# Edit the environment file
vim /opt/app/.env

# Update these critical values:
# - PG_DSN=postgresql://user:YOUR_PASSWORD@postgres:5432/rag
# - S3_BUCKET=your-actual-bucket-name
# - CORS_ORIGINS=https://your-domain.com
# - GRAFANA_ADMIN_PASSWORD=your-secure-password
```

#### 6. Deploy Your Application

```bash
cd /opt/app
git clone https://github.com/deepspeccode/voicebot-rag-practice.git .

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f

# Test health endpoint
curl http://localhost:8080/healthz
```

#### 7. Verify Everything Works

```bash
# Check Docker
docker ps
docker compose ps

# Check environment file permissions
ls -la /opt/app/.env  # Should show: -rw------- (600)

# Check GPU (if applicable)
docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi

# Check application logs
docker compose logs app

# Test API
curl http://localhost:8080/
curl http://localhost:8080/healthz
```

---

## Option 2: EC2 User Data (Automated Launch) 🚀

Use this when launching a **new EC2 instance** to have everything set up automatically.

### How It Works

1. You provide the user-data script when launching EC2
2. The script runs automatically on first boot
3. Instance is fully configured when it starts
4. Check `/var/log/voicebot-setup.log` for progress

### Instructions

#### 1. Prepare User Data Script

Copy the contents of `deploy/ec2-user-data.sh`

**Important:** Update the repository URL in the script:
```bash
SETUP_SCRIPT_URL="https://raw.githubusercontent.com/YOUR-USERNAME/voicebot-rag-practice/main/deploy/setup-production.sh"
```

#### 2. Launch EC2 Instance with User Data

**Via AWS Console:**
1. Go to EC2 → Launch Instance
2. Choose Ubuntu 22.04 LTS AMI
3. Select instance type (t3.large or better)
4. Configure storage (50GB+)
5. In "Advanced Details" → "User data", paste the script
6. Launch instance

**Via AWS CLI:**
```bash
aws ec2 run-instances \
    --image-id ami-0c7217cdde317cfec \
    --instance-type t3.large \
    --key-name your-key-pair \
    --security-group-ids sg-xxxxx \
    --subnet-id subnet-xxxxx \
    --user-data file://deploy/ec2-user-data.sh \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":50,"VolumeType":"gp3"}}]' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=voicebot-rag-prod}]'
```

#### 3. Wait for Setup to Complete

```bash
# Connect to instance
aws ssm start-session --target i-YOUR-INSTANCE-ID

# Check if setup is complete
tail -f /var/log/voicebot-setup.log

# Setup is complete when you see this file:
ls -la /home/ubuntu/.voicebot-setup-complete
```

#### 4. Continue from Step 5 of Option 1

Configure environment and deploy your application.

---

## Option 3: Manual Setup ⚠️ NOT RECOMMENDED

If you must do it manually, follow the exact commands in `deploy/setup-production.sh`.

**Why not recommended:**
- Easy to make typos
- Easy to skip steps
- No error checking
- Hard to reproduce
- Time-consuming

---

## 🔍 Troubleshooting

### Docker: Permission Denied

**Problem:** `Got permission denied while trying to connect to the Docker daemon`

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Verify
docker ps
```

### Script Fails Partway Through

**Problem:** Setup script stops with an error

**Solution:**
```bash
# Check the error message
# The script is idempotent - safe to run again

# Run the script again
./deploy/setup-production.sh

# Or run specific steps manually by examining the script
```

### GPU Not Detected

**Problem:** `nvidia-smi` command not found after GPU setup

**Solution:**
```bash
# Check if driver is installed
dpkg -l | grep nvidia-driver

# Reboot if needed
sudo reboot

# After reboot, verify
nvidia-smi

# If still fails, check GPU is present
lspci | grep -i nvidia
```

### Environment File Issues

**Problem:** Variables not loading or file has wrong permissions

**Solution:**
```bash
# Check file exists
ls -la /opt/app/.env

# Should show: -rw------- (600)
# Fix permissions if needed:
chmod 600 /opt/app/.env

# Verify contents (be careful not to expose secrets!)
head -5 /opt/app/.env
```

### Services Won't Start

**Problem:** `docker compose up` fails

**Solution:**
```bash
# Check Docker is running
sudo systemctl status docker

# Check logs
docker compose logs

# Verify environment file
cat /opt/app/.env | grep -v SECRET | grep -v PASSWORD

# Try starting services individually
docker compose up app
docker compose up postgres
```

---

## 📊 Verification Checklist

After setup completes, verify everything:

- [ ] Docker is installed: `docker --version`
- [ ] Docker Compose is installed: `docker compose version`
- [ ] User is in docker group: `groups | grep docker`
- [ ] Application directory exists: `ls -la /opt/app`
- [ ] Environment file exists: `ls -la /opt/app/.env`
- [ ] Environment file has correct permissions: `600`
- [ ] (GPU) NVIDIA driver is loaded: `nvidia-smi`
- [ ] (GPU) Docker can access GPU: `docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi`

---

## 🚀 Next Steps

After production environment is set up:

1. **Configure Environment** - Edit `/opt/app/.env`
2. **Deploy Code** - Clone repo to `/opt/app`
3. **Start Services** - Run `docker compose up -d`
4. **Configure Nginx** - Set up reverse proxy and TLS
5. **Set Up Monitoring** - Configure Grafana and Prometheus
6. **Test Everything** - Verify all endpoints work

Then move to **Task 1: LLM Service Implementation**!

---

## 📝 Notes

### Security Considerations

- Always use secure passwords in `.env`
- Keep `.env` file permissions at `600`
- Use AWS Secrets Manager for production secrets
- Configure security groups properly
- Enable CloudWatch logging
- Use IAM roles instead of AWS keys when possible

### Cost Optimization

- Use t3.large for testing (~$0.08/hour)
- Use g4dn.xlarge for GPU (~$0.50/hour)
- Stop instances when not in use
- Use Reserved Instances for production
- Monitor costs with AWS Cost Explorer

### Performance Tuning

- Use gp3 EBS volumes (faster than gp2)
- Configure swap if needed: `sudo fallocate -l 8G /swapfile`
- Use CloudWatch agent for detailed monitoring
- Consider using Application Load Balancer
- Enable access logs for debugging

---

## 📚 Additional Resources

- [Docker Installation Guide](https://docs.docker.com/engine/install/ubuntu/)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

