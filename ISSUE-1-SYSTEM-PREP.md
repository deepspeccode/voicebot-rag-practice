# Issue #1: Task 0 - Project Setup & Infrastructure

**Status:** 🟡 In Progress  
**Phase:** Phase 1: Foundations  
**Labels:** `phase:foundations`, `type:infra`

---

## Overview
Complete system preparation and infrastructure setup for Ubuntu 22.04 EC2 instance to host the Voicebot RAG Practice application.

---

## Sub-Tasks Checklist

### 🔧 Sub-Issue 1.1: Connect and Update System
- [ ] Connect to EC2 instance (using SSM)
- [ ] Run system update: `sudo apt update`
- [ ] Run system upgrade: `sudo apt upgrade -y`
- [ ] Verify system is up to date

**Commands:**
```bash
sudo apt update
sudo apt upgrade -y
```

---

### 🐳 Sub-Issue 1.2: Install Docker Engine and Compose Plugin
- [ ] Install required packages (ca-certificates, curl, gnupg)
- [ ] Create keyrings directory
- [ ] Add Docker GPG key
- [ ] Add Docker repository to apt sources
- [ ] Update apt package index
- [ ] Install Docker CE, CLI, containerd, buildx, and compose plugins
- [ ] Add current user to docker group
- [ ] Activate docker group membership
- [ ] Verify Docker Compose installation

**Commands:**
```bash
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
 | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
docker compose version
```

---

### 📁 Sub-Issue 1.3: Create Application Directory Structure
- [ ] Create base directory at `/opt/app`
- [ ] Create subdirectories: app, llm, stt, tts, rag, nginx, deploy, landing, monitoring
- [ ] Set correct ownership for current user
- [ ] Verify directory structure

**Commands:**
```bash
sudo mkdir -p /opt/app/{app,llm,stt,tts,rag,nginx,deploy,landing,monitoring}
sudo chown -R $USER:$USER /opt/app
```

**Verification:**
```bash
ls -la /opt/app/
```

---

### 🔐 Sub-Issue 1.4: Create Environment Configuration
- [ ] Create `.env` file at `/opt/app/.env`
- [ ] Configure OPENAI_COMPAT_BASE_URL
- [ ] Configure MODEL_NAME
- [ ] Configure EMBED_MODEL
- [ ] Configure PG_DSN (or leave empty for FAISS)
- [ ] Configure FAISS_PATH
- [ ] Configure S3_BUCKET
- [ ] Generate and configure JWT_SECRET
- [ ] Set secure file permissions (600)
- [ ] Verify .env file is created and secured

**Commands:**
```bash
cat > /opt/app/.env << 'EOF'
OPENAI_COMPAT_BASE_URL=
MODEL_NAME=
EMBED_MODEL=
PG_DSN=                             # or leave empty when using FAISS_PATH
FAISS_PATH=
S3_BUCKET=
JWT_SECRET=
EOF

chmod 600 /opt/app/.env
```

**Notes:**
- Keep .env private and permissions restricted
- Never commit .env to version control
- Generate strong JWT_SECRET (use `openssl rand -hex 32`)

---

## 🎮 GPU Path (Optional - For GPU-enabled instances)

### 💻 Sub-Issue 1.5: Install NVIDIA Driver and CUDA Userspace
**Prerequisites:** GPU-enabled EC2 instance (e.g., g4dn, p3, p4)

#### Part A: Install NVIDIA Container Toolkit
- [ ] Install linux headers for current kernel
- [ ] Detect distribution version
- [ ] Add NVIDIA container toolkit GPG key
- [ ] Add NVIDIA container toolkit repository
- [ ] Update apt package index
- [ ] Install NVIDIA driver (version 535)
- [ ] Reboot system
- [ ] Wait for system to come back online

**Commands:**
```bash
sudo apt install -y linux-headers-$(uname -r)
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
 | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list \
 | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
 | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

sudo apt update
sudo apt install -y nvidia-driver-535
sudo reboot
```

#### Part B: Configure Docker for GPU Support (After Reboot)
- [ ] Update apt package index
- [ ] Install nvidia-container-toolkit
- [ ] Configure Docker runtime for NVIDIA
- [ ] Restart Docker service
- [ ] Verify nvidia-container-toolkit is configured

**Commands (run after reboot):**
```bash
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

---

## ✅ Sub-Issue 1.6: Acceptance Checks

### Docker and Compose Verification
- [ ] Verify Docker Compose version is displayed
- [ ] Verify Docker daemon is running

**Commands:**
```bash
docker compose version
docker ps
```

**Expected Output:**
```
Docker Compose version v2.x.x
```

### GPU Verification (GPU instances only)
- [ ] Verify GPU is visible inside container
- [ ] Check GPU details with nvidia-smi
- [ ] Verify CUDA version compatibility

**Commands:**
```bash
docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi
```

**Expected Output:**
- nvidia-smi output showing GPU details
- CUDA version information
- Driver version

---

## 📋 Infrastructure Checklist

### EC2 Instance Configuration
- [ ] Verify EC2 instance role has S3 permissions for configured bucket
- [ ] Verify SSM agent is installed and running (for SSM connectivity)
- [ ] Verify security group allows necessary inbound/outbound traffic
- [ ] Verify instance type is appropriate (GPU if needed)

### Next Steps After Completion
- [ ] Drop service docker-compose.yml files into subfolders
- [ ] Set up nginx configuration under `/opt/app/nginx`
- [ ] Register EC2 instance in ALB target group
- [ ] Configure health check endpoints
- [ ] Test basic CI/CD pipeline

---

## 🔍 Troubleshooting

### Common Issues

**Docker Permission Denied:**
```bash
# If you get permission denied, logout and login again
# or use: newgrp docker
```

**NVIDIA Driver Installation Fails:**
```bash
# Check if kernel headers match kernel version
uname -r
dpkg -l | grep linux-headers-$(uname -r)
```

**GPU Not Visible in Container:**
```bash
# Verify nvidia-container-toolkit is installed
dpkg -l | grep nvidia-container-toolkit

# Check Docker daemon configuration
cat /etc/docker/daemon.json
```

---

## 📝 Notes
- Use SSM to connect instead of SSH for better security
- Ensure the EC2 instance role has S3 permissions for your bucket
- Keep .env private and permissions restricted
- For production, consider using AWS Secrets Manager instead of .env files
- Document any deviations from standard setup for team reference

---

## ✨ Success Criteria
- [ ] All sub-tasks completed and checked off
- [ ] Docker and Docker Compose working correctly
- [ ] Application directory structure created with correct permissions
- [ ] Environment file configured and secured
- [ ] GPU support verified (if applicable)
- [ ] All acceptance checks passing
- [ ] Ready to deploy service containers

---

**Next Issue:** [Issue #2] Task 1: LLM Service Implementation