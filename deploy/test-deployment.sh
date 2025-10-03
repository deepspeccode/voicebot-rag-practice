#!/bin/bash

################################################################################
# Voicebot RAG - Test Deployment Script
################################################################################
#
# This script helps you test deployment to your existing EC2 instance
# It assumes you already have an EC2 instance running with the basic setup
#
# Usage: ./deploy/test-deployment.sh
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
INSTANCE_ID="i-051cb6ac6bf116c23"
AWS_REGION="us-east-1"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           VOICEBOT RAG - TEST DEPLOYMENT SCRIPT                ║"
echo "║              Deploy to Existing EC2 Instance                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Testing deployment to EC2 instance: $INSTANCE_ID"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS CLI not configured. Please run: aws configure"
    exit 1
fi

# Check instance status
log_info "Checking instance status..."
INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

if [[ "$INSTANCE_STATE" != "running" ]]; then
    log_warning "Instance is not running (current state: $INSTANCE_STATE)"
    log_info "Starting instance..."
    aws ec2 start-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
    
    log_info "Waiting for instance to start..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $AWS_REGION
    log_success "Instance is now running"
else
    log_success "Instance is running"
fi

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

log_success "Public IP: $PUBLIC_IP"
echo ""

# Test connection
log_info "Testing connection to instance..."
TEST_COMMAND_ID=$(aws ssm send-command \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["echo SSM connection test successful"]' \
    --query 'Command.CommandId' \
    --output text 2>/dev/null)

if [[ -n "$TEST_COMMAND_ID" ]]; then
    sleep 2
    TEST_RESULT=$(aws ssm get-command-invocation \
        --command-id $TEST_COMMAND_ID \
        --instance-id $INSTANCE_ID \
        --region $AWS_REGION \
        --query 'StandardOutputContent' \
        --output text 2>/dev/null)
    
    if [[ "$TEST_RESULT" == *"successful"* ]]; then
        log_success "SSM connection available"
    else
        log_error "SSM connection test failed"
        exit 1
    fi
else
    log_error "Cannot connect via SSM. Please check IAM permissions."
    exit 1
fi

echo ""
log_info "=== DEPLOYMENT INSTRUCTIONS ==="
echo ""
echo "1. Connect to your instance:"
echo -e "   ${BLUE}aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION${NC}"
echo ""
echo "2. Once connected, run these commands on the EC2 instance:"
echo ""
echo -e "${CYAN}# Update the repository${NC}"
echo -e "${BLUE}cd /home/ubuntu/voicebot-rag-practice${NC}"
echo -e "${BLUE}git fetch origin${NC}"
echo -e "${BLUE}git checkout deploy-scripts-test${NC}"
echo -e "${BLUE}git pull origin deploy-scripts-test${NC}"
echo ""
echo -e "${CYAN}# Copy updated code to app directory${NC}"
echo -e "${BLUE}sudo cp -r /home/ubuntu/voicebot-rag-practice/* /opt/app/${NC}"
echo -e "${BLUE}sudo chown -R ubuntu:ubuntu /opt/app${NC}"
echo ""
echo -e "${CYAN}# Restart services with updated code${NC}"
echo -e "${BLUE}cd /opt/app${NC}"
echo -e "${BLUE}docker compose down${NC}"
echo -e "${BLUE}docker compose up -d app postgres prometheus grafana${NC}"
echo ""
echo -e "${CYAN}# Test the deployment${NC}"
echo -e "${BLUE}curl http://localhost:8080/healthz${NC}"
echo ""
echo "3. Test from your local machine:"
echo -e "   ${BLUE}curl http://$PUBLIC_IP:8080/healthz${NC}"
echo -e "   ${BLUE}curl http://$PUBLIC_IP:8080/${NC}"
echo ""

log_info "=== QUICK COMMANDS FOR THIS INSTANCE ==="
echo ""
echo "Connect:"
echo -e "   ${BLUE}aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION${NC}"
echo ""
echo "Stop instance (save costs):"
echo -e "   ${BLUE}aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $AWS_REGION${NC}"
echo ""
echo "Start instance:"
echo -e "   ${BLUE}aws ec2 start-instances --instance-ids $INSTANCE_ID --region $AWS_REGION${NC}"
echo ""
echo "Check status:"
echo -e "   ${BLUE}aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION --query 'Reservations[0].Instances[0].State.Name' --output text${NC}"
echo ""

log_success "Ready to deploy! Follow the instructions above."
