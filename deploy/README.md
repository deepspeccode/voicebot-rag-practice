# Deployment Scripts

Lean deployment system for Voicebot RAG production infrastructure.

## 🚀 Quick Start

### Deploy New Instance (15 minutes)
```bash
./MASTER-DEPLOY.sh
```
Follow on-screen instructions.

---

## 📁 Files

### `MASTER-DEPLOY.sh` ⭐ **START HERE**
One-click deployment automation.

- Launches EC2 instance
- Creates security groups & IAM roles
- Provides setup commands
- Tested & working ✅

### `setup-production.sh` ✅ **CORE SCRIPT**
EC2 setup automation (runs on EC2).

- Installs Docker Engine
- Creates `/opt/app/` directory
- Generates secure environment
- Optional GPU support with `--gpu`
- Tested & working ✅

---

## 📖 Documentation

### Quick Reference
**SCRIPTS-GUIDE.md** - Daily commands you'll use

### Problem Solving  
**TROUBLESHOOTING.md** - Solutions for common issues

### Complete Guide
**DEPLOYMENT_GUIDE.md** - Full deployment walkthrough

### AWS Setup
**aws-setup-guide.md** - Getting AWS credentials

### Cost Management
**aws-billing-setup.md** - Billing alerts and cost tracking

---

## 📋 What These Scripts Do

**MASTER-DEPLOY.sh**:
1. Checks prerequisites
2. Creates AWS resources (security groups, IAM)
3. Launches EC2 instance
4. Provides setup commands

**setup-production.sh**:
1. Updates Ubuntu packages
2. Installs Docker Engine
3. Creates `/opt/app/` directory
4. Generates `.env` with secure JWT secret
5. Adds user to docker group

---

## ✅ Tested & Working

Both scripts have been tested on real EC2 instances and work perfectly.

**Total deployment time**: ~15 minutes

---

**For full details**, see the other guides in this directory.

