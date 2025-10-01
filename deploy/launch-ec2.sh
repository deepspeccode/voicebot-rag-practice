#!/bin/bash

################################################################################
# Interactive EC2 Instance Launcher for Voicebot RAG
################################################################################
#
# This script helps you launch an EC2 instance with the right configuration
# for the Voicebot RAG project.
#
# Usage: ./launch-ec2.sh
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

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Voicebot RAG - EC2 Instance Launcher                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# Step 1: Verify AWS CLI Configuration
################################################################################

log_info "Step 1: Verifying AWS CLI configuration..."

if ! command -v aws &> /dev/null; then
    log_error "AWS CLI not found. Please install it first:"
    echo "  brew install awscli"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured. Please run:"
    echo "  aws configure"
    echo ""
    echo "See deploy/aws-setup-guide.md for help getting credentials."
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
CURRENT_REGION=$(aws configure get region)

log_success "AWS CLI configured"
echo "  Account: $ACCOUNT_ID"
echo "  User: $USER_ARN"
echo "  Region: ${CURRENT_REGION:-us-east-1}"
echo ""

################################################################################
# Step 2: Choose Region
################################################################################

log_info "Step 2: Choose AWS Region"
echo ""
echo "Recommended regions:"
echo "  1) us-east-1 (N. Virginia) - Cheapest, most services"
echo "  2) us-east-2 (Ohio)"
echo "  3) us-west-2 (Oregon)"
echo "  4) eu-west-1 (Ireland)"
echo "  5) Custom region"
echo ""

read -p "Choose region [1-5] (default: 1): " region_choice
region_choice=${region_choice:-1}

case $region_choice in
    1) AWS_REGION="us-east-1" ;;
    2) AWS_REGION="us-east-2" ;;
    3) AWS_REGION="us-west-2" ;;
    4) AWS_REGION="eu-west-1" ;;
    5)
        read -p "Enter region code: " AWS_REGION
        ;;
    *) AWS_REGION="us-east-1" ;;
esac

log_success "Selected region: $AWS_REGION"
echo ""

################################################################################
# Step 3: Choose Instance Type
################################################################################

log_info "Step 3: Choose Instance Type"
echo ""
echo "Instance types:"
echo "  1) t3.medium  - 2 vCPU, 4 GB RAM  - \$0.04/hr (~\$30/mo)  [Dev/Testing]"
echo "  2) t3.large   - 2 vCPU, 8 GB RAM  - \$0.08/hr (~\$60/mo)  [Recommended]"
echo "  3) t3.xlarge  - 4 vCPU, 16 GB RAM - \$0.17/hr (~\$120/mo) [Production CPU]"
echo "  4) g4dn.xlarge - 4 vCPU, 16 GB RAM, NVIDIA T4 GPU - \$0.53/hr (~\$380/mo) [Production GPU]"
echo ""

read -p "Choose instance type [1-4] (default: 2): " instance_choice
instance_choice=${instance_choice:-2}

case $instance_choice in
    1) INSTANCE_TYPE="t3.medium"; USE_GPU=false ;;
    2) INSTANCE_TYPE="t3.large"; USE_GPU=false ;;
    3) INSTANCE_TYPE="t3.xlarge"; USE_GPU=false ;;
    4) INSTANCE_TYPE="g4dn.xlarge"; USE_GPU=true ;;
    *) INSTANCE_TYPE="t3.large"; USE_GPU=false ;;
esac

log_success "Selected: $INSTANCE_TYPE"
echo ""

################################################################################
# Step 4: Get or Create Security Group
################################################################################

log_info "Step 4: Setting up Security Group"
echo ""

SG_NAME="voicebot-rag-sg"
SG_DESC="Security group for Voicebot RAG application"

# Check if security group exists
SG_ID=$(aws ec2 describe-security-groups \
    --region $AWS_REGION \
    --filters "Name=group-name,Values=$SG_NAME" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null || echo "None")

if [[ "$SG_ID" == "None" ]] || [[ -z "$SG_ID" ]]; then
    log_info "Creating new security group..."
    
    # Get default VPC
    VPC_ID=$(aws ec2 describe-vpcs \
        --region $AWS_REGION \
        --filters "Name=is-default,Values=true" \
        --query 'Vpcs[0].VpcId' \
        --output text)
    
    # Create security group
    SG_ID=$(aws ec2 create-security-group \
        --region $AWS_REGION \
        --group-name $SG_NAME \
        --description "$SG_DESC" \
        --vpc-id $VPC_ID \
        --output text)
    
    # Add rules
    log_info "Adding security group rules..."
    
    # SSH
    aws ec2 authorize-security-group-ingress \
        --region $AWS_REGION \
        --group-id $SG_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --group-rule-description "SSH access" 2>/dev/null || true
    
    # HTTP
    aws ec2 authorize-security-group-ingress \
        --region $AWS_REGION \
        --group-id $SG_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --group-rule-description "HTTP access" 2>/dev/null || true
    
    # HTTPS
    aws ec2 authorize-security-group-ingress \
        --region $AWS_REGION \
        --group-id $SG_ID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 \
        --group-rule-description "HTTPS access" 2>/dev/null || true
    
    # API (for testing - restrict in production!)
    aws ec2 authorize-security-group-ingress \
        --region $AWS_REGION \
        --group-id $SG_ID \
        --protocol tcp \
        --port 8080 \
        --cidr 0.0.0.0/0 \
        --group-rule-description "API access" 2>/dev/null || true
    
    log_success "Security group created: $SG_ID"
else
    log_success "Using existing security group: $SG_ID"
fi
echo ""

################################################################################
# Step 5: Get Latest Ubuntu 22.04 AMI
################################################################################

log_info "Step 5: Finding Ubuntu 22.04 LTS AMI..."

AMI_ID=$(aws ec2 describe-images \
    --region $AWS_REGION \
    --owners 099720109477 \
    --filters \
        "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
        "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)

log_success "Ubuntu 22.04 AMI: $AMI_ID"
echo ""

################################################################################
# Step 6: Storage Configuration
################################################################################

log_info "Step 6: Configure Storage"
echo ""
read -p "Storage size in GB (default: 50, min: 30): " STORAGE_SIZE
STORAGE_SIZE=${STORAGE_SIZE:-50}

if [ $STORAGE_SIZE -lt 30 ]; then
    log_warning "Minimum 30GB required. Setting to 30GB."
    STORAGE_SIZE=30
fi

log_success "Storage: ${STORAGE_SIZE}GB gp3"
echo ""

################################################################################
# Step 7: Key Pair
################################################################################

log_info "Step 7: SSH Key Pair"
echo ""

# List existing key pairs
KEY_PAIRS=$(aws ec2 describe-key-pairs --region $AWS_REGION --query 'KeyPairs[*].KeyName' --output text 2>/dev/null || echo "")

if [[ -n "$KEY_PAIRS" ]]; then
    echo "Existing key pairs:"
    echo "$KEY_PAIRS" | tr '\t' '\n' | nl
    echo ""
    echo "Options:"
    echo "  1) Use existing key pair"
    echo "  2) Create new key pair"
    echo "  3) No key pair (use SSM Session Manager)"
    echo ""
    read -p "Choose [1-3] (default: 3): " key_choice
    key_choice=${key_choice:-3}
else
    echo "No existing key pairs found."
    echo ""
    echo "Options:"
    echo "  1) Create new key pair"
    echo "  2) No key pair (use SSM Session Manager)"
    echo ""
    read -p "Choose [1-2] (default: 2): " key_choice
    key_choice=${key_choice:-2}
    if [ "$key_choice" == "1" ]; then
        key_choice=2
    else
        key_choice=3
    fi
fi

case $key_choice in
    1)
        echo ""
        echo "Available key pairs:"
        echo "$KEY_PAIRS" | tr '\t' '\n' | nl
        read -p "Enter key pair number: " kp_num
        KEY_NAME=$(echo "$KEY_PAIRS" | tr '\t' '\n' | sed -n "${kp_num}p")
        KEY_PAIR_ARG="--key-name $KEY_NAME"
        log_success "Using key pair: $KEY_NAME"
        ;;
    2)
        read -p "Enter new key pair name: " KEY_NAME
        KEY_NAME=${KEY_NAME:-voicebot-rag-key}
        
        log_info "Creating key pair: $KEY_NAME"
        aws ec2 create-key-pair \
            --region $AWS_REGION \
            --key-name $KEY_NAME \
            --query 'KeyMaterial' \
            --output text > "${KEY_NAME}.pem"
        
        chmod 400 "${KEY_NAME}.pem"
        
        KEY_PAIR_ARG="--key-name $KEY_NAME"
        log_success "Key pair created and saved to: ${KEY_NAME}.pem"
        log_warning "Keep this file safe! You'll need it to SSH into the instance."
        ;;
    3)
        KEY_PAIR_ARG=""
        log_success "No key pair - you'll use AWS Systems Manager to connect"
        ;;
esac
echo ""

################################################################################
# Step 8: IAM Instance Profile (for SSM and S3)
################################################################################

log_info "Step 8: Setting up IAM Instance Profile"
echo ""

ROLE_NAME="VoicebotEC2Role"
PROFILE_NAME="VoicebotEC2Profile"

# Check if role exists
if aws iam get-role --role-name $ROLE_NAME &>/dev/null; then
    log_success "IAM role already exists: $ROLE_NAME"
else
    log_info "Creating IAM role..."
    
    # Create trust policy
    cat > /tmp/trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
    
    # Create role
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "Role for Voicebot RAG EC2 instances" &>/dev/null
    
    # Attach policies
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
    
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
    
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
    
    # Create instance profile
    aws iam create-instance-profile \
        --instance-profile-name $PROFILE_NAME &>/dev/null || true
    
    aws iam add-role-to-instance-profile \
        --instance-profile-name $PROFILE_NAME \
        --role-name $ROLE_NAME &>/dev/null || true
    
    # Wait for profile to be ready
    sleep 10
    
    log_success "IAM role and instance profile created"
fi
echo ""

################################################################################
# Step 9: User Data (Automated Setup)
################################################################################

log_info "Step 9: Configure Automated Setup"
echo ""
echo "Would you like to run the setup script automatically on launch?"
echo "  1) Yes - Instance will be ready to use when it starts"
echo "  2) No - I'll run setup manually after launch"
echo ""
read -p "Choose [1-2] (default: 1): " setup_choice
setup_choice=${setup_choice:-1}

if [[ "$setup_choice" == "1" ]]; then
    USER_DATA_FILE="/tmp/user-data.sh"
    
    GPU_FLAG=""
    if [[ "$USE_GPU" == "true" ]]; then
        GPU_FLAG="--gpu"
    fi
    
    cat > $USER_DATA_FILE << EOF
#!/bin/bash
exec > >(tee -a /var/log/voicebot-setup.log)
exec 2>&1

echo "=========================================="
echo "Voicebot RAG - EC2 Initialization"
echo "Started: \$(date)"
echo "=========================================="

# Wait for cloud-init
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    sleep 1
done

cd /home/ubuntu

# Clone repository
git clone https://github.com/deepspeccode/voicebot-rag-practice.git
cd voicebot-rag-practice

# Run setup
chmod +x deploy/setup-production.sh
sudo -u ubuntu ./deploy/setup-production.sh $GPU_FLAG

touch /home/ubuntu/.voicebot-setup-complete
echo "Setup complete: \$(date)" >> /home/ubuntu/.voicebot-setup-complete

echo "=========================================="
echo "Initialization Complete"
echo "=========================================="
EOF
    
    USER_DATA_ARG="--user-data file://${USER_DATA_FILE}"
    log_success "Automated setup enabled"
else
    USER_DATA_ARG=""
    log_info "Manual setup - you'll run the setup script after launch"
fi
echo ""

################################################################################
# Step 10: Summary and Confirmation
################################################################################

log_info "Step 10: Launch Summary"
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║            Launch Configuration              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Region:          $AWS_REGION"
echo "  Instance Type:   $INSTANCE_TYPE"
echo "  AMI:             $AMI_ID (Ubuntu 22.04)"
echo "  Storage:         ${STORAGE_SIZE}GB gp3"
echo "  Security Group:  $SG_ID"
if [[ -n "$KEY_NAME" ]]; then
echo "  Key Pair:        $KEY_NAME"
fi
echo "  IAM Profile:     $PROFILE_NAME"
echo "  Auto-Setup:      $([ "$setup_choice" == "1" ] && echo "Yes" || echo "No")"
echo ""

read -p "Launch instance? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Launch cancelled"
    exit 0
fi

################################################################################
# Step 11: Launch Instance
################################################################################

log_info "Launching EC2 instance..."
echo ""

LAUNCH_OUTPUT=$(aws ec2 run-instances \
    --region $AWS_REGION \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --security-group-ids $SG_ID \
    --iam-instance-profile Name=$PROFILE_NAME \
    $KEY_PAIR_ARG \
    $USER_DATA_ARG \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":$STORAGE_SIZE,\"VolumeType\":\"gp3\"}}]" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=voicebot-rag-prod},{Key=Project,Value=voicebot-rag}]" \
    --output json)

INSTANCE_ID=$(echo $LAUNCH_OUTPUT | jq -r '.Instances[0].InstanceId')

log_success "Instance launched: $INSTANCE_ID"
echo ""

################################################################################
# Step 12: Wait for Instance
################################################################################

log_info "Waiting for instance to be running..."
aws ec2 wait instance-running --region $AWS_REGION --instance-ids $INSTANCE_ID

log_success "Instance is running!"
echo ""

# Get instance details
INSTANCE_INFO=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --output json)

PUBLIC_IP=$(echo $INSTANCE_INFO | jq -r '.Reservations[0].Instances[0].PublicIpAddress')
PRIVATE_IP=$(echo $INSTANCE_INFO | jq -r '.Reservations[0].Instances[0].PrivateIpAddress')

################################################################################
# Final Instructions
################################################################################

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                 🎉 Instance Launched Successfully! 🎉        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Instance Details:"
echo "  Instance ID:   $INSTANCE_ID"
echo "  Public IP:     $PUBLIC_IP"
echo "  Private IP:    $PRIVATE_IP"
echo "  Region:        $AWS_REGION"
echo ""
echo "Next Steps:"
echo ""

if [[ -n "$KEY_NAME" ]]; then
    echo "1. Connect via SSH:"
    echo "   ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
    echo ""
fi

echo "2. Connect via AWS Systems Manager (No key needed!):"
echo "   aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION"
echo ""

if [[ "$setup_choice" == "1" ]]; then
    echo "3. Wait for automated setup (~10 minutes)"
    echo "   Check progress:"
    echo "   ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP} 'tail -f /var/log/voicebot-setup.log'"
    echo ""
    echo "4. Setup complete when you see:"
    echo "   ls /home/ubuntu/.voicebot-setup-complete"
else
    echo "3. Run setup manually:"
    echo "   cd voicebot-rag-practice"
    echo "   ./deploy/setup-production.sh"
fi
echo ""

echo "5. Test your API:"
echo "   curl http://${PUBLIC_IP}:8080/healthz"
echo ""

echo "6. Stop instance when not in use (to save costs!):"
echo "   aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $AWS_REGION"
echo ""

log_warning "⚠️  Remember: Instance is running and incurring charges!"
log_info "💰 Estimated cost: \$$(aws pricing get-products --service-code AmazonEC2 --filters \"Type=TERM_MATCH,Field=instanceType,Value=$INSTANCE_TYPE\" --region us-east-1 --query 'PriceList[0]' --output text 2>/dev/null | grep -oP 'USD.*?[0-9]+\.[0-9]+' | head -1 | grep -oP '[0-9]+\.[0-9]+' || echo '0.08')/hour"
echo ""

# Save instance info
cat > instance-info.txt << EOF
Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
Private IP: $PRIVATE_IP
Region: $AWS_REGION
Instance Type: $INSTANCE_TYPE
Key Pair: ${KEY_NAME:-None (use SSM)}
Launched: $(date)

Connect:
  SSH: ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}
  SSM: aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION

Stop: aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
Terminate: aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
EOF

log_success "Instance info saved to: instance-info.txt"
echo ""
log_success "✅ All done! Your EC2 instance is ready!"

