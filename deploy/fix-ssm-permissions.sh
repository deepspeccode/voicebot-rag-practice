#!/bin/bash

################################################################################
# Fix SSM Permissions for Voicebot RAG Deployment
################################################################################
#
# This script fixes IAM permissions to enable SSM Session Manager
# for connecting to EC2 instances
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              FIX SSM PERMISSIONS FOR DEPLOYMENT                ║"
echo "║              Enable Session Manager Access                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS CLI not configured. Please run: aws configure"
    exit 1
fi

# Get current user info
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
USER_NAME=$(aws sts get-caller-identity --query UserName --output text)

log_info "Current user: $USER_NAME"
log_info "User ARN: $USER_ARN"
echo ""

# Check if user has SSM permissions
log_info "Checking current SSM permissions..."

if aws ssm describe-instance-information --max-items 1 &> /dev/null; then
    log_success "SSM permissions are already configured"
else
    log_warning "SSM permissions need to be configured"
    
    echo ""
    log_info "To fix SSM permissions, you need to:"
    echo ""
    echo "1. Go to AWS Console → IAM → Users → $USER_NAME"
    echo "2. Click 'Add permissions' → 'Attach policies directly'"
    echo "3. Search for and select: AmazonSSMFullAccess"
    echo "4. Click 'Next' → 'Add permissions'"
    echo ""
    echo "OR run this AWS CLI command:"
    echo -e "${BLUE}aws iam attach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess${NC}"
    echo ""
    
    read -p "Would you like me to run the AWS CLI command now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Attaching SSM policy to user..."
        aws iam attach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess
        log_success "SSM policy attached"
        log_warning "Wait 1-2 minutes for permissions to propagate, then try connecting again"
    else
        log_info "Please manually add the SSM permissions and then run the deployment script again"
    fi
fi

echo ""
log_info "Testing SSM connection to instance..."

INSTANCE_ID="i-051cb6ac6bf116c23"
AWS_REGION="us-east-1"

# Wait a moment for permissions to propagate
sleep 5

if aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION --dry-run &> /dev/null; then
    log_success "SSM connection test passed!"
    echo ""
    log_info "You can now connect to your instance with:"
    echo -e "   ${BLUE}aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION${NC}"
else
    log_error "SSM connection test failed"
    echo ""
    log_info "Troubleshooting steps:"
    echo "1. Verify the policy was attached (wait 1-2 minutes)"
    echo "2. Check that the EC2 instance has the SSM agent running"
    echo "3. Verify the instance has the correct IAM role attached"
    echo ""
    log_info "To check instance IAM role:"
    echo -e "   ${BLUE}aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn'${NC}"
fi
