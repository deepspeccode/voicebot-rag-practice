#!/bin/bash

################################################################################
# Voicebot RAG - Production Environment Setup Script
################################################################################
#
# This script automates Part B of Task 0: Production Infrastructure Setup
# Designed for: EC2 Ubuntu 22.04 LTS
#
# What it does:
# - Updates system packages
# - Installs Docker Engine and Docker Compose
# - Creates application directory structure
# - Sets up environment file template
# - (Optional) Configures GPU support
#
# Usage:
#   chmod +x deploy/setup-production.sh
#   ./deploy/setup-production.sh
#
# For GPU setup:
#   ./deploy/setup-production.sh --gpu
#
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/opt/app"
SETUP_GPU=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --gpu)
            SETUP_GPU=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--gpu]"
            echo "  --gpu    Enable GPU support (NVIDIA)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root. It will use sudo when needed."
        exit 1
    fi
}

check_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect OS. This script is for Ubuntu 22.04."
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] || [[ "$VERSION_ID" != "22.04" ]]; then
        log_warning "This script is designed for Ubuntu 22.04. You're running: $PRETTY_NAME"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

################################################################################
# Part B.1: System Preparation
################################################################################

step_system_update() {
    log_info "Step B.1: System Preparation"
    
    log_info "Updating package lists..."
    sudo apt update
    log_success "Package lists updated"
    
    log_info "Upgrading installed packages (this may take a few minutes)..."
    sudo apt upgrade -y
    log_success "System packages upgraded"
    
    log_info "Installing essential tools..."
    sudo apt install -y \
        curl \
        wget \
        git \
        vim \
        htop \
        net-tools \
        jq
    log_success "Essential tools installed"
}

################################################################################
# Part B.2: Docker Engine Installation
################################################################################

step_docker_installation() {
    log_info "Step B.2: Docker Engine Installation"
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        log_warning "Docker is already installed: $(docker --version)"
        read -p "Reinstall Docker? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Docker installation"
            return 0
        fi
    fi
    
    log_info "Installing Docker prerequisites..."
    sudo apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    log_info "Setting up Docker repository..."
    sudo install -m 0755 -d /etc/apt/keyrings
    
    # Add Docker's official GPG key
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi
    
    # Set up the repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    log_info "Installing Docker Engine..."
    sudo apt update
    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    
    log_info "Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully"
    log_info "Docker version: $(docker --version)"
    log_info "Docker Compose version: $(docker compose version)"
    
    log_warning "You need to log out and back in for docker group changes to take effect"
    log_warning "Or run: newgrp docker"
}

################################################################################
# Part B.3: Application Directory Structure
################################################################################

step_directory_structure() {
    log_info "Step B.3: Application Directory Structure"
    
    if [[ -d "$APP_DIR" ]]; then
        log_warning "Directory $APP_DIR already exists"
        read -p "Remove and recreate? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo rm -rf "$APP_DIR"
        else
            log_info "Using existing directory structure"
            return 0
        fi
    fi
    
    log_info "Creating application directory structure..."
    sudo mkdir -p ${APP_DIR}/{app,llm,stt,tts,rag,nginx,deploy,landing,monitoring}
    
    log_info "Setting ownership to current user..."
    sudo chown -R $USER:$USER "$APP_DIR"
    
    log_info "Directory structure:"
    ls -la "$APP_DIR"
    
    log_success "Application directory structure created"
}

################################################################################
# Part B.4: Environment Configuration
################################################################################

step_environment_config() {
    log_info "Step B.4: Environment Configuration"
    
    ENV_FILE="${APP_DIR}/.env"
    
    if [[ -f "$ENV_FILE" ]]; then
        log_warning "Environment file already exists: $ENV_FILE"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing environment file"
            return 0
        fi
    fi
    
    log_info "Creating environment file template..."
    
    # Generate a secure JWT secret
    JWT_SECRET=$(openssl rand -hex 32)
    
    cat > "$ENV_FILE" << 'EOF'
# =============================================================================
# Voicebot RAG - Production Environment Configuration
# =============================================================================
# Generated by setup-production.sh
# IMPORTANT: Update all placeholder values before deployment!

# LLM Service Configuration
OPENAI_COMPAT_BASE_URL=http://llm:8001/v1
MODEL_NAME=llama-3.1-8b-instruct
MAX_TOKENS=2048
TEMPERATURE=0.7

# Embedding & RAG Configuration
EMBED_MODEL=intfloat/e5-small-v2
VECTOR_DB=faiss
FAISS_PATH=/data/faiss.index
PG_DSN=postgresql://user:CHANGE_ME@postgres:5432/rag

# Speech Services
STT_URL=http://stt:8002
WHISPER_MODEL=base
TTS_URL=http://tts:8003
PIPER_VOICE=en_US-lessac-medium

# Storage Configuration
S3_BUCKET=voicebot-practice-CHANGE_ME
S3_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

# Security & Authentication
EOF
    
    echo "JWT_SECRET=${JWT_SECRET}" >> "$ENV_FILE"
    
    cat >> "$ENV_FILE" << 'EOF'
CORS_ORIGINS=https://yourdomain.com
RATE_LIMIT=60

# Service Endpoints
APP_HOST=0.0.0.0
APP_PORT=8080
FRONTEND_URL=https://yourdomain.com

# Monitoring & Logging
LOG_LEVEL=INFO
LOG_FORMAT=json
METRICS_PORT=9100
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=CHANGE_ME

# Performance Tuning
CUDA_VISIBLE_DEVICES=0
WORKERS=4
MAX_CONCURRENT_REQUESTS=100

# Production Settings
DEBUG=false
RELOAD=false
EOF
    
    log_info "Setting secure permissions on environment file..."
    chmod 600 "$ENV_FILE"
    
    log_success "Environment file created: $ENV_FILE"
    log_warning "IMPORTANT: Edit $ENV_FILE and update all CHANGE_ME values!"
}

################################################################################
# Part B.5: GPU Setup (Optional)
################################################################################

step_gpu_setup() {
    if [[ "$SETUP_GPU" != "true" ]]; then
        log_info "Step B.5: GPU Setup - SKIPPED (use --gpu to enable)"
        return 0
    fi
    
    log_info "Step B.5: GPU Setup"
    
    # Check if NVIDIA GPU is present
    if ! lspci | grep -i nvidia > /dev/null; then
        log_warning "No NVIDIA GPU detected. Skipping GPU setup."
        return 0
    fi
    
    log_info "NVIDIA GPU detected"
    lspci | grep -i nvidia
    
    log_info "Installing Linux headers..."
    sudo apt install -y linux-headers-$(uname -r)
    
    log_info "Installing NVIDIA driver 535..."
    sudo apt install -y nvidia-driver-535
    
    log_warning "System will reboot after this step to load NVIDIA drivers"
    read -p "Continue with reboot? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "GPU setup incomplete. Reboot manually and run this script again with --gpu"
        return 0
    fi
    
    log_info "Rebooting in 10 seconds... (Ctrl+C to cancel)"
    sleep 10
    sudo reboot
}

step_gpu_setup_post_reboot() {
    if [[ "$SETUP_GPU" != "true" ]]; then
        return 0
    fi
    
    log_info "Continuing GPU setup after reboot..."
    
    # Check if nvidia-smi works
    if ! command -v nvidia-smi &> /dev/null; then
        log_error "nvidia-smi not found. Driver installation may have failed."
        exit 1
    fi
    
    log_info "NVIDIA driver status:"
    nvidia-smi
    
    log_info "Installing NVIDIA Container Toolkit..."
    
    # Add NVIDIA Container Toolkit repository
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    
    log_info "Configuring Docker runtime..."
    sudo nvidia-ctk runtime configure --runtime=docker
    
    log_info "Restarting Docker..."
    sudo systemctl restart docker
    
    log_info "Testing GPU access in Docker..."
    if docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi; then
        log_success "GPU is accessible in Docker containers!"
    else
        log_error "GPU test failed. Check configuration."
        exit 1
    fi
}

################################################################################
# Verification
################################################################################

step_verify_installation() {
    log_info "Verifying installation..."
    
    echo ""
    log_info "=== System Information ==="
    echo "OS: $(lsb_release -ds)"
    echo "Kernel: $(uname -r)"
    echo ""
    
    log_info "=== Docker Information ==="
    docker --version || log_error "Docker not found"
    docker compose version || log_error "Docker Compose not found"
    echo "Docker group: $(groups | grep docker && echo 'OK' || echo 'MISSING - log out and back in')"
    echo ""
    
    log_info "=== Application Directory ==="
    echo "Location: $APP_DIR"
    echo "Owner: $(stat -c '%U:%G' $APP_DIR)"
    echo "Permissions: $(stat -c '%a' $APP_DIR)"
    echo ""
    
    log_info "=== Environment File ==="
    if [[ -f "${APP_DIR}/.env" ]]; then
        echo "Location: ${APP_DIR}/.env"
        echo "Permissions: $(stat -c '%a' ${APP_DIR}/.env)"
    else
        log_warning "Environment file not found"
    fi
    echo ""
    
    if [[ "$SETUP_GPU" == "true" ]]; then
        log_info "=== GPU Information ==="
        if command -v nvidia-smi &> /dev/null; then
            nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
        else
            log_warning "NVIDIA driver not installed or not loaded"
        fi
        echo ""
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║   Voicebot RAG - Production Environment Setup Script         ║"
    echo "║   Part B: Production Infrastructure Setup (EC2 Ubuntu 22.04) ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Pre-flight checks
    check_root
    check_ubuntu
    
    log_info "Starting setup process..."
    echo ""
    
    # Run setup steps
    step_system_update
    echo ""
    
    step_docker_installation
    echo ""
    
    step_directory_structure
    echo ""
    
    step_environment_config
    echo ""
    
    step_gpu_setup
    # If GPU setup triggered a reboot, script will exit here
    
    step_gpu_setup_post_reboot
    echo ""
    
    step_verify_installation
    echo ""
    
    # Final instructions
    log_success "✅ Production environment setup complete!"
    echo ""
    log_info "=== Next Steps ==="
    echo "1. Edit environment file: vim ${APP_DIR}/.env"
    echo "2. Update all CHANGE_ME values"
    echo "3. Clone your repository: cd ${APP_DIR} && git clone <your-repo>"
    echo "4. Deploy services: docker compose up -d"
    echo "5. Check health: curl http://localhost:8080/healthz"
    echo ""
    
    if [[ "$(groups | grep docker)" == "" ]]; then
        log_warning "⚠️  Log out and back in for docker group changes to take effect"
        log_warning "    Or run: newgrp docker"
    fi
}

# Run main function
main "$@"

