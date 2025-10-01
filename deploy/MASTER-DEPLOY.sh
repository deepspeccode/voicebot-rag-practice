#!/bin/bash

################################################################################
# Voicebot RAG - Master One-Click Deployment Script
################################################################################
#
# This script handles EVERYTHING from start to finish:
# 1. AWS CLI setup and verification
# 2. EC2 instance launch
# 3. Provides step-by-step setup instructions
# 4. Saves deployment state
#
# Usage: ./deploy/MASTER-DEPLOY.sh
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_header() { echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
log_info() { echo -e "${BLUE}  ℹ $1${NC}"; }
log_success() { echo -e "${GREEN}  ✓ $1${NC}"; }
log_warning() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
log_error() { echo -e "${RED}  ✗ $1${NC}"; }

clear
log_header
echo -e "${MAGENTA}"
cat << 'BANNER'
╔══════════════════════════════════════════════════════════════════╗
║           VOICEBOT RAG - MASTER DEPLOYMENT SCRIPT                ║
║              One-Click Cloud Deployment System                   ║
╚══════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"
log_header
echo ""

STATE_FILE="$HOME/.voicebot-deploy-state"
save_state() { echo "$1=$2" >> "$STATE_FILE"; }
get_state() { grep "^$1=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2 || echo ""; }

################################################################################
# Step 1: Prerequisites Check
################################################################################

echo -e "${CYAN}━━━ Step 1: Prerequisites Check ━━━${NC}"
echo ""

for tool in aws jq curl; do
    if ! command -v $tool &> /dev/null; then
        log_error "Missing: $tool"
        log_info "Install with: brew install $tool"
        exit 1
    fi
done
log_success "All tools installed"
echo ""

################################################################################
# Step 2: AWS Configuration
################################################################################

echo -e "${CYAN}━━━ Step 2: AWS Configuration ━━━${NC}"
echo ""

if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS not configured"
    log_info "Please run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
log_success "AWS configured: $ACCOUNT_ID in $AWS_REGION"
save_state "aws_region" "$AWS_REGION"
echo ""

################################################################################
# Step 3: Instance Configuration
################################################################################

echo -e "${CYAN}━━━ Step 3: Instance Configuration ━━━${NC}"
echo ""
echo "Choose instance type:"
echo "  1) t3.large - 2 vCPU, 8 GB RAM (~\$0.08/hr) [Recommended]"
echo "  2) t3.xlarge - 4 vCPU, 16 GB RAM (~\$0.17/hr)"
echo ""
read -p "Choice [1-2] (default: 1): " choice
INSTANCE_TYPE=$([[ "$choice" == "2" ]] && echo "t3.xlarge" || echo "t3.large")
log_info "Using: $INSTANCE_TYPE"
save_state "instance_type" "$INSTANCE_TYPE"
echo ""

################################################################################
# Step 4: Security Group
################################################################################

echo -e "${CYAN}━━━ Step 4: Security Group Setup ━━━${NC}"
echo ""

SG_NAME="voicebot-rag-sg"
SG_ID=$(aws ec2 describe-security-groups \
    --region $AWS_REGION \
    --filters "Name=group-name,Values=$SG_NAME" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null)

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
    log_info "Creating security group..."
    
    VPC_ID=$(aws ec2 describe-vpcs \
        --region $AWS_REGION \
        --filters "Name=is-default,Values=true" \
        --query 'Vpcs[0].VpcId' \
        --output text)
    
    SG_ID=$(aws ec2 create-security-group \
        --region $AWS_REGION \
        --group-name $SG_NAME \
        --description "Voicebot RAG Security Group" \
        --vpc-id $VPC_ID \
        --output text)
    
    # Add rules for all required ports
    for port in 22 80 443 8080 9090 3001; do
        aws ec2 authorize-security-group-ingress \
            --region $AWS_REGION \
            --group-id $SG_ID \
            --protocol tcp \
            --port $port \
            --cidr 0.0.0.0/0 2>/dev/null || true
    done
    
    log_success "Security group created: $SG_ID"
else
    log_success "Using existing security group: $SG_ID"
fi
save_state "security_group_id" "$SG_ID"
echo ""

################################################################################
# Step 5: IAM Role
################################################################################

echo -e "${CYAN}━━━ Step 5: IAM Role Setup ━━━${NC}"
echo ""

ROLE_NAME="VoicebotEC2Role"
PROFILE_NAME="VoicebotEC2Profile"

if ! aws iam get-role --role-name $ROLE_NAME &>/dev/null; then
    log_info "Creating IAM role..."
    
    cat > /tmp/trust-policy.json << 'TRUST_EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
TRUST_EOF
    
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "Role for Voicebot RAG EC2 instances" &>/dev/null
    
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
    
    aws iam create-instance-profile --instance-profile-name $PROFILE_NAME &>/dev/null || true
    aws iam add-role-to-instance-profile --instance-profile-name $PROFILE_NAME --role-name $ROLE_NAME &>/dev/null || true
    
    sleep 10
    log_success "IAM role created"
else
    log_success "Using existing IAM role"
fi
echo ""

################################################################################
# Step 6: Launch EC2 Instance
################################################################################

echo -e "${CYAN}━━━ Step 6: Launching EC2 Instance ━━━${NC}"
echo ""

# Get latest Ubuntu 22.04 AMI
AMI_ID=$(aws ec2 describe-images \
    --region $AWS_REGION \
    --owners 099720109477 \
    --filters \
        "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
        "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)

log_info "Using AMI: $AMI_ID"
log_info "Launching instance..."

INSTANCE_ID=$(aws ec2 run-instances \
    --region $AWS_REGION \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --security-group-ids $SG_ID \
    --iam-instance-profile Name=$PROFILE_NAME \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":50,"VolumeType":"gp3"}}]' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=voicebot-rag},{Key=Project,Value=voicebot-rag},{Key=ManagedBy,Value=master-deploy}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

save_state "instance_id" "$INSTANCE_ID"
log_success "Instance launched: $INSTANCE_ID"

log_info "Waiting for instance to start..."
aws ec2 wait instance-running --region $AWS_REGION --instance-ids $INSTANCE_ID
log_success "Instance is running"
echo ""

################################################################################
# Step 7: Get Instance Information
################################################################################

echo -e "${CYAN}━━━ Step 7: Getting Instance Info ━━━${NC}"
echo ""

PUBLIC_IP=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

PRIVATE_IP=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

log_success "Public IP: $PUBLIC_IP"
log_success "Private IP: $PRIVATE_IP"
save_state "public_ip" "$PUBLIC_IP"
save_state "private_ip" "$PRIVATE_IP"
echo ""

log_info "Waiting 60 seconds for instance to fully initialize..."
sleep 60
echo ""

################################################################################
# Final Summary
################################################################################

log_header
echo -e "${GREEN}"
cat << 'SUCCESS'
╔══════════════════════════════════════════════════════════════════╗
║              ✓  INSTANCE LAUNCHED SUCCESSFULLY  ✓                ║
╚══════════════════════════════════════════════════════════════════╝
SUCCESS
echo -e "${NC}"
log_header
echo ""

echo -e "${CYAN}🎯 Your Instance:${NC}"
echo ""
echo -e "  Instance ID: ${GREEN}$INSTANCE_ID${NC}"
echo -e "  Public IP:   ${GREEN}$PUBLIC_IP${NC}"
echo -e "  Region:      ${GREEN}$AWS_REGION${NC}"
echo ""

echo -e "${CYAN}📋 Setup Instructions (Run on EC2):${NC}"
echo ""
echo "1. Connect to instance:"
echo -e "   ${BLUE}aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION${NC}"
echo ""
echo "2. Download and run setup (copy entire block):"
echo -e "${BLUE}"
cat << 'SETUP_COMMANDS'
cd ~
wget -q https://github.com/deepspeccode/voicebot-rag-practice/archive/refs/heads/main.zip
sudo apt install -y unzip
unzip -q main.zip
mv voicebot-rag-practice-main voicebot-rag-practice
cd voicebot-rag-practice
chmod +x deploy/setup-production.sh
./deploy/setup-production.sh
SETUP_COMMANDS
echo -e "${NC}"
echo ""
echo "3. Deploy application (after setup completes, copy entire block):"
echo -e "${BLUE}"
cat << 'DEPLOY_COMMANDS'
sudo cp -r ~/voicebot-rag-practice/* /opt/app/
sudo chown -R ubuntu:ubuntu /opt/app
cd /opt/app
mkdir -p services/{llm,stt,tts,rag,nginx} monitoring/prometheus monitoring/grafana/{dashboards,datasources}
echo -e 'FROM alpine:latest\nCMD sleep infinity' | tee services/{llm,stt,tts,rag,nginx}/Dockerfile > /dev/null
cat > monitoring/prometheus/prometheus.yml << 'PROM'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['app:8080']
PROM
newgrp docker
docker compose up -d app postgres prometheus grafana
DEPLOY_COMMANDS
echo -e "${NC}"
echo ""
echo "4. Test from your Mac:"
echo -e "   ${BLUE}curl http://$PUBLIC_IP:8080/healthz${NC}"
echo ""

echo -e "${CYAN}💰 Cost Management:${NC}"
echo ""
echo -e "  Stop:  ${BLUE}aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $AWS_REGION${NC}"
echo -e "  Start: ${BLUE}aws ec2 start-instances --instance-ids $INSTANCE_ID --region $AWS_REGION${NC}"
echo ""

# Save deployment info
cat > deployment-info.txt << INFO
Voicebot RAG Deployment
=======================
Deployed: $(date)

Instance Details:
  Instance ID: $INSTANCE_ID
  Public IP: $PUBLIC_IP
  Private IP: $PRIVATE_IP
  Region: $AWS_REGION
  Type: $INSTANCE_TYPE

Access URLs:
  API: http://$PUBLIC_IP:8080
  Health: http://$PUBLIC_IP:8080/healthz
  Prometheus: http://$PUBLIC_IP:9090
  Grafana: http://$PUBLIC_IP:3001

Connect:
  aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION

Manage:
  Stop: aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
  Start: aws ec2 start-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
  Terminate: aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION

State File: $STATE_FILE
INFO

log_success "Deployment info saved to: deployment-info.txt"
log_success "State saved to: $STATE_FILE"
echo ""
log_header
echo -e "${GREEN}✨ Ready! Follow the steps above to complete deployment. ✨${NC}"
log_header

