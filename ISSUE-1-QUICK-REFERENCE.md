# Issue #1: System Prep - Quick Reference

📋 **[Full Details](ISSUE-1-SYSTEM-PREP.md)** | 🎯 **[Project Tracking](PROJECT_TRACKING.md)**

---

## 📊 Progress Overview

**Status:** 🟡 In Progress  
**Total Sub-Issues:** 6  
**Completed:** 0/6

---

## ✅ Sub-Issues Checklist

### 1.1 Connect and Update System
- [ ] Connect to EC2 (SSM)
- [ ] Update and upgrade system packages

### 1.2 Install Docker Engine and Compose
- [ ] Install Docker CE, CLI, containerd
- [ ] Install Docker Compose plugin
- [ ] Configure user permissions
- [ ] Verify installation

### 1.3 Create Application Directory Structure
- [ ] Create `/opt/app` and subdirectories
- [ ] Set correct ownership
- [ ] Verify structure

### 1.4 Create Environment Configuration
- [ ] Create `.env` file
- [ ] Configure all environment variables
- [ ] Set secure permissions (600)
- [ ] Verify configuration

### 1.5 Install NVIDIA Driver & CUDA (GPU Path - Optional)
- [ ] Install NVIDIA drivers
- [ ] Reboot system
- [ ] Install nvidia-container-toolkit
- [ ] Configure Docker for GPU

### 1.6 Acceptance Checks
- [ ] Verify Docker Compose version
- [ ] Test GPU in container (if applicable)
- [ ] Validate all configurations

---

## 🚀 Quick Start Commands

### Basic Setup (All Instances)
```bash
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install Docker
sudo apt install -y ca-certificates curl gnupg
# ... (see full details in ISSUE-1-SYSTEM-PREP.md)

# 3. Create directories
sudo mkdir -p /opt/app/{app,llm,stt,tts,rag,nginx,deploy,landing,monitoring}
sudo chown -R $USER:$USER /opt/app

# 4. Create .env
cat > /opt/app/.env << 'EOF'
OPENAI_COMPAT_BASE_URL=
MODEL_NAME=
EMBED_MODEL=
PG_DSN=
FAISS_PATH=
S3_BUCKET=
JWT_SECRET=
EOF
chmod 600 /opt/app/.env

# 5. Verify
docker compose version
```

### GPU Setup (Optional)
```bash
# Install NVIDIA drivers
sudo apt install -y nvidia-driver-535
sudo reboot

# After reboot: Configure Docker for GPU
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test GPU
docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi
```

---

## 📝 Important Notes

⚠️ **Security:**
- Use SSM to connect (not SSH)
- Keep `.env` permissions at 600
- Never commit `.env` to git

☁️ **AWS Requirements:**
- EC2 instance role needs S3 permissions
- Security groups configured appropriately
- SSM agent installed and running

🎮 **GPU Instances:**
- Use g4dn, p3, or p4 instance types
- Install NVIDIA drivers (version 535)
- Verify GPU visibility in containers

---

## ✨ Success Criteria

All items must be ✅ before moving to Issue #2:
- [ ] All 6 sub-issues completed
- [ ] Docker & Compose verified working
- [ ] Directory structure created
- [ ] Environment configured
- [ ] GPU verified (if applicable)
- [ ] All acceptance tests passing

---

## 🔗 Next Steps

After completing Issue #1:
1. Drop service `docker-compose.yml` files into subfolders
2. Set up nginx under `/opt/app/nginx`
3. Register EC2 in ALB target group
4. Move to **[Issue #2] Task 1: LLM Service Implementation**

---

**📖 For detailed instructions, see:** [ISSUE-1-SYSTEM-PREP.md](ISSUE-1-SYSTEM-PREP.md)