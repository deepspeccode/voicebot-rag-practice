# Issue #1: Task 0 - Project Setup & Infrastructure

**Status:** 🟡 In Progress  
**Phase:** Phase 1: Foundations  
**Labels:** `phase:foundations`, `type:infra`

---

## Overview
Complete system preparation and infrastructure setup for Ubuntu 22.04 EC2 instance to host the Voicebot RAG Practice application.

---

## Sub-Issues (6):

- [ ] **1.1 - Connect and Update System**
  - Connect to EC2 instance (using SSM)
  - Run system update and upgrade
  - Verify system is up to date

- [ ] **1.2 - Install Docker Engine and Compose Plugin**
  - Install required packages and Docker GPG key
  - Add Docker repository and install Docker CE
  - Add user to docker group and verify installation

- [ ] **1.3 - Create Application Directory Structure**
  - Create base directory at `/opt/app`
  - Create subdirectories for all services
  - Set correct ownership and verify structure

- [ ] **1.4 - Create Environment Configuration**
  - Create `.env` file at `/opt/app/.env`
  - Configure all required environment variables
  - Set secure file permissions (600)

- [ ] **1.5 - Install NVIDIA Driver & CUDA (GPU Path - Optional)**
  - Install NVIDIA Container Toolkit
  - Configure Docker for GPU support
  - Verify GPU is accessible in containers

- [ ] **1.6 - Acceptance Checks**
  - Verify Docker and Docker Compose installation
  - Verify GPU support (if applicable)
  - Run all acceptance tests

---

## 📚 Reference Documentation
- **Full Details:** [ISSUE-1-SYSTEM-PREP.md](./ISSUE-1-SYSTEM-PREP.md)
- **Quick Reference:** [ISSUE-1-QUICK-REFERENCE.md](./ISSUE-1-QUICK-REFERENCE.md)

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