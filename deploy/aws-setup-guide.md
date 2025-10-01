# AWS Account Setup Guide

## Getting Your AWS Credentials

### If You Don't Have an AWS Account Yet

1. **Create an AWS Account**
   - Go to https://aws.amazon.com/
   - Click "Create an AWS Account"
   - Follow the signup process (requires credit card)
   - AWS Free Tier includes 750 hours/month of t2.micro (first 12 months)

### If You Have an AWS Account

#### Get Your Access Keys:

1. **Go to AWS Console**
   - Visit https://console.aws.amazon.com/
   - Sign in with your account

2. **Create IAM User (Recommended for Security)**
   ```
   Console → IAM → Users → Add users
   
   User name: voicebot-admin
   Access type: ✓ Programmatic access
   
   Permissions: 
   - Attach policies directly
   - Select: AdministratorAccess (for testing)
     OR for production: Create custom policy with these permissions:
     - EC2 Full Access
     - S3 Full Access
     - Systems Manager Full Access
     - CloudWatch Full Access
   
   Click: Create user
   ```

3. **Download Credentials**
   - After creating user, you'll see:
     - Access Key ID (like: AKIAIOSFODNN7EXAMPLE)
     - Secret Access Key (like: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY)
   - **IMPORTANT**: Download the CSV or copy these now! 
   - You won't be able to see the Secret Access Key again!

4. **Configure AWS CLI**
   ```bash
   aws configure
   ```
   
   Enter:
   - AWS Access Key ID: [paste your access key]
   - AWS Secret Access Key: [paste your secret key]
   - Default region name: us-east-1
   - Default output format: json

5. **Verify Configuration**
   ```bash
   aws sts get-caller-identity
   ```
   
   Should show your account information.

## Security Best Practices

### For Production:

1. **Use IAM Roles Instead of Access Keys**
   - Attach IAM roles to EC2 instances
   - No need to store credentials in .env

2. **Enable MFA (Multi-Factor Authentication)**
   - Console → IAM → Users → Security credentials
   - Enable MFA device

3. **Use AWS SSM Session Manager**
   - No need for SSH keys
   - Better security and auditability
   - Install Session Manager plugin:
     ```bash
     brew install --cask session-manager-plugin
     ```

4. **Rotate Access Keys Regularly**
   - Create new keys every 90 days
   - Delete old keys

## Cost Management

### AWS Free Tier (First 12 Months)

- **EC2**: 750 hours/month of t2.micro
- **EBS**: 30 GB of storage
- **S3**: 5 GB of storage
- **Data Transfer**: 15 GB/month

### Estimated Costs (After Free Tier)

| Instance Type | vCPU | RAM | GPU | Cost/Hour | Cost/Month |
|---------------|------|-----|-----|-----------|------------|
| t3.medium | 2 | 4 GB | - | $0.04 | ~$30 |
| t3.large | 2 | 8 GB | - | $0.08 | ~$60 |
| t3.xlarge | 4 | 16 GB | - | $0.17 | ~$120 |
| g4dn.xlarge | 4 | 16 GB | T4 16GB | $0.53 | ~$380 |

**Tip**: Stop instances when not using them to save costs!

### Set Up Billing Alerts

1. **Create Budget**
   ```
   Console → Billing → Budgets → Create budget
   
   Budget type: Cost budget
   Budget amount: $10/month (or your limit)
   Alert threshold: 80%
   Email notification: your-email@example.com
   ```

2. **Enable Cost Anomaly Detection**
   ```
   Console → Cost Management → Cost Anomaly Detection
   Create monitor → Enable
   ```

## Regions and Availability

### Recommended Regions:

| Region | Location | Code | Notes |
|--------|----------|------|-------|
| N. Virginia | US East | us-east-1 | Cheapest, most services |
| Ohio | US East | us-east-2 | Good backup |
| Oregon | US West | us-west-2 | West coast users |
| Ireland | Europe | eu-west-1 | European users |

**Tip**: Use `us-east-1` for learning - it's cheapest and has all services.

## Next Steps

After AWS CLI is configured:

1. **Test Connection**
   ```bash
   aws ec2 describe-regions
   ```

2. **Launch EC2 Instance**
   ```bash
   cd /path/to/voicebot-rag-practice
   # Follow the EC2 launch guide
   ```

3. **Set Up Cost Tracking**
   - Enable billing alerts
   - Check costs daily while learning

## Troubleshooting

### "Credentials are not configured"
```bash
# Check configuration
aws configure list

# Reconfigure if needed
aws configure
```

### "Access Denied"
```bash
# Check your permissions
aws iam get-user

# Verify you have the right policies attached
aws iam list-attached-user-policies --user-name your-username
```

### "Region not supported"
```bash
# List available regions
aws ec2 describe-regions --output table

# Change your default region
aws configure set region us-east-1
```

## Resources

- **AWS Free Tier**: https://aws.amazon.com/free/
- **IAM Best Practices**: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- **Cost Management**: https://aws.amazon.com/aws-cost-management/
- **EC2 Pricing**: https://aws.amazon.com/ec2/pricing/

---

**Ready?** Once AWS CLI is configured, come back to launch your EC2 instance!

