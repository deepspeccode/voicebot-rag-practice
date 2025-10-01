# Deployment Scripts

This directory contains automated deployment scripts for setting up the production environment.

## 📁 Files

### `setup-production.sh` ⭐
**Main automated setup script** - Run this on your EC2 instance to set up everything automatically.

- Installs Docker Engine and Docker Compose
- Creates application directory structure
- Generates environment configuration
- (Optional) Configures GPU support with `--gpu` flag
- Idempotent - safe to run multiple times
- Full error checking and logging

**Usage:**
```bash
# For CPU instances
./setup-production.sh

# For GPU instances (g4dn, g5, p3, p4, etc.)
./setup-production.sh --gpu
```

### `ec2-user-data.sh`
**EC2 launch automation** - Use this as User Data when launching a new EC2 instance.

- Runs automatically on first boot
- Downloads and executes setup-production.sh
- Logs output to `/var/log/voicebot-setup.log`
- Creates marker file when complete

**Usage:**
1. Copy contents of this file
2. Update the repository URL
3. Paste into "User Data" field when launching EC2
4. Instance will be fully configured when it starts

### `DEPLOYMENT_GUIDE.md` 📖
**Comprehensive deployment guide** with:
- Three deployment options (automated script, user data, manual)
- Step-by-step instructions with screenshots
- Troubleshooting common issues
- Verification checklist
- Security and performance tips

**Read this first!**

## 🚀 Quick Start

### Option 1: Automated Script (Recommended)

1. **Connect to your EC2 instance**
   ```bash
   ssh -i your-key.pem ubuntu@your-instance-ip
   # OR
   aws ssm start-session --target i-your-instance-id
   ```

2. **Clone the repository**
   ```bash
   git clone https://github.com/deepspeccode/voicebot-rag-practice.git
   cd voicebot-rag-practice
   ```

3. **Run the setup script**
   ```bash
   chmod +x deploy/setup-production.sh
   ./deploy/setup-production.sh
   ```

4. **Configure environment**
   ```bash
   vim /opt/app/.env
   # Update: passwords, bucket names, domains
   ```

5. **Deploy**
   ```bash
   cd /opt/app
   git clone https://github.com/deepspeccode/voicebot-rag-practice.git .
   docker compose up -d
   ```

### Option 2: EC2 User Data

When launching a new EC2 instance:

1. Update `ec2-user-data.sh` with your repository URL
2. Paste contents into "User Data" field in EC2 launch wizard
3. Launch instance
4. Wait ~10 minutes for setup to complete
5. Check `/var/log/voicebot-setup.log` for progress

## 📋 What Gets Set Up

The scripts configure:

- ✅ **System packages** - Updates and essential tools
- ✅ **Docker Engine** - Latest stable version with Compose plugin
- ✅ **Directory structure** - `/opt/app/` with all service folders
- ✅ **Environment file** - Template with secure JWT secret
- ✅ **Docker permissions** - User added to docker group
- ✅ **GPU support** (optional) - NVIDIA drivers and container toolkit

## 🔍 Verification

After setup completes:

```bash
# Check Docker
docker --version
docker compose version
docker ps

# Check directory
ls -la /opt/app/

# Check environment file
ls -la /opt/app/.env  # Should be -rw------- (600)

# Check GPU (if applicable)
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi
```

## 🆘 Troubleshooting

### Docker Permission Denied
```bash
newgrp docker
# OR log out and back in
```

### GPU Not Working
```bash
# Reboot is required after driver installation
sudo reboot

# After reboot, verify
nvidia-smi
```

### Environment File Issues
```bash
# Fix permissions
chmod 600 /opt/app/.env

# Verify contents (without exposing secrets)
grep -v "SECRET\|PASSWORD" /opt/app/.env
```

See `DEPLOYMENT_GUIDE.md` for more detailed troubleshooting.

## 📚 Documentation

- **Full Guide**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Project Setup**: [../project_instructions.md](../project_instructions.md)
- **Getting Started**: [../GETTING_STARTED.md](../GETTING_STARTED.md)

## 🔒 Security Notes

- Environment file permissions are set to `600` (owner read/write only)
- JWT secrets are generated with `openssl rand -hex 32`
- Update all `CHANGE_ME` values before deployment
- Use AWS Secrets Manager for production secrets
- Never commit `.env` files to git

## ⚙️ AWS Configuration

### Required IAM Permissions

Your EC2 instance role should have:
- `AmazonSSMManagedInstanceCore` (for SSM access)
- `AmazonS3ReadOnlyAccess` (or specific S3 bucket access)
- `CloudWatchAgentServerPolicy` (for metrics)

### Security Group Ports

- `22` - SSH (can disable if using SSM)
- `80` - HTTP (for web access)
- `443` - HTTPS (for TLS)
- `8080` - Application API (internal only, use ALB)

## 📊 Instance Recommendations

### Development/Testing
- **Type**: t3.large
- **vCPU**: 2
- **RAM**: 8 GB
- **Storage**: 50 GB gp3
- **Cost**: ~$0.08/hour

### Production (CPU)
- **Type**: t3.xlarge or m5.xlarge
- **vCPU**: 4
- **RAM**: 16 GB
- **Storage**: 100 GB gp3
- **Cost**: ~$0.15-0.20/hour

### Production (GPU)
- **Type**: g4dn.xlarge
- **GPU**: 1x NVIDIA T4 (16 GB)
- **vCPU**: 4
- **RAM**: 16 GB
- **Storage**: 100 GB gp3
- **Cost**: ~$0.50/hour

## 🎯 Next Steps

After production setup:

1. ✅ Configure environment variables
2. ✅ Deploy application code
3. ✅ Start Docker services
4. 🔲 Set up nginx reverse proxy (Task 0 complete after this)
5. 🔲 Configure TLS certificates
6. 🔲 Set up monitoring dashboards
7. 🔲 Implement LLM service (Task 1)

---

**Questions?** Check `DEPLOYMENT_GUIDE.md` or open an issue on GitHub.

