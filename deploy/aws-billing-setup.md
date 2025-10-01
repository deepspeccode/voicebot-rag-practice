# AWS Billing Alerts & Cost Management Setup

## Quick Start: Set Up Billing Alerts

### Step 1: Create a Budget (Recommended)

1. **Go to AWS Budgets**
   - Open: https://console.aws.amazon.com/billing/home#/budgets
   - Or: AWS Console → Billing → Budgets → Create budget

2. **Choose Budget Type**
   - Select: **Cost budget - Recommended**
   - Click: **Next**

3. **Set Budget Amount**
   ```
   Budget name: Monthly-Voicebot-Budget
   Period: Monthly
   Budget effective dates: Recurring budget
   Start month: [Current month]
   
   Budgeting method: Fixed
   Enter your budgeted amount: $10.00
   (Adjust based on your comfort level)
   ```

4. **Configure Alerts**
   ```
   Alert 1 - Actual Cost:
   Threshold: 80% of budgeted amount
   Email: your-email@example.com
   
   Alert 2 - Actual Cost:
   Threshold: 100% of budgeted amount
   Email: your-email@example.com
   
   Alert 3 - Forecasted Cost (optional):
   Threshold: 100% of budgeted amount
   Email: your-email@example.com
   ```

5. **Review and Create**
   - Review your settings
   - Click: **Create budget**

✅ **Done!** You'll get email alerts when you hit 80% and 100% of your budget.

---

## Step 2: Enable Billing Alerts (if not already enabled)

1. **Go to Billing Preferences**
   - Open: https://console.aws.amazon.com/billing/home#/preferences
   - Or: AWS Console → Billing → Billing preferences

2. **Enable Alerts**
   - ✓ Check: "Receive Billing Alerts"
   - ✓ Check: "Receive Free Tier Usage Alerts"
   - Enter your email address
   - Click: **Save preferences**

---

## Step 3: Set Up CloudWatch Billing Alarm (Alternative/Additional)

1. **Switch to US East (N. Virginia) Region**
   - Billing metrics only available in us-east-1
   - Top-right corner → Select "US East (N. Virginia)"

2. **Create Alarm**
   - Go to: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:
   - Click: **Create alarm**
   - Click: **Select metric**

3. **Choose Metric**
   - Select: **Billing** → **Total Estimated Charge**
   - Check: ✓ EstimatedCharges (USD)
   - Click: **Select metric**

4. **Define Threshold**
   ```
   Threshold type: Static
   Whenever EstimatedCharges is: Greater than
   Than: 10 (or your desired amount in USD)
   ```

5. **Configure Actions**
   - Create new topic: billing-alerts
   - Email: your-email@example.com
   - Click: **Create topic**
   - **Check your email and confirm the subscription!**

6. **Name and Create**
   ```
   Alarm name: Billing-Alert-$10
   Description: Alert when AWS charges exceed $10
   ```
   - Click: **Create alarm**

---

## Recommended Budget Amounts

Based on your usage:

| Usage Pattern | Recommended Budget | What You Can Do |
|---------------|-------------------|-----------------|
| **Learning** | $10-20/month | Run t3.large few hours/day, stop when not using |
| **Testing** | $30-50/month | Run t3.large most days, occasional 24/7 |
| **Development** | $60-100/month | Run t3.large 24/7, some testing |
| **Production** | $200+/month | 24/7 operation with GPU or multiple instances |

### Your Current Setup:
- **Instance**: c7i-flex.large
- **Cost**: ~$0.08/hour
- **If running 24/7**: ~$60/month
- **If running 8 hours/day**: ~$20/month

**💡 Tip**: Stop your instance when not using it to save money!

---

## Cost Management Best Practices

### 1. Always Stop Instances When Not Using

```bash
# Stop instance (saves compute costs, keeps storage)
aws ec2 stop-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1

# Start again when needed
aws ec2 start-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1
```

### 2. Set Up Daily Cost Checks

Add this to your daily routine:
```bash
# Check current month's costs
aws ce get-cost-and-usage \
    --time-period Start=$(date -u -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --region us-east-1
```

### 3. Enable Cost Anomaly Detection

1. Go to: https://console.aws.amazon.com/cost-management/home#/anomaly-detection
2. Click: **Get started**
3. Click: **Create monitor**
4. Monitor type: **AWS services**
5. Alerting preference: Alert when anomaly > $10
6. Create

### 4. Review Cost Explorer Weekly

- Go to: https://console.aws.amazon.com/cost-management/home#/cost-explorer
- Review your spending trends
- Identify unexpected costs

---

## What Costs Money in Your Project?

### 1. EC2 Instance (Compute)
- **c7i-flex.large**: $0.08/hour
- **Stop when not using to save!**

### 2. EBS Storage (Always charged)
- **50 GB gp3**: ~$4/month
- **Charged even when instance is stopped**
- **Delete volume to stop charges**

### 3. Data Transfer
- **First 100 GB/month**: FREE
- **After that**: $0.09/GB
- **Usually not an issue for development**

### 4. Elastic IPs (if not using)
- **FREE when attached to running instance**
- **$0.005/hour when NOT attached**
- **We're not using Elastic IPs, so no cost**

### 5. S3 Storage (minimal)
- **First 5 GB**: FREE
- **After**: $0.023/GB/month

---

## Emergency: Stop All Costs Immediately

If you get an unexpected bill:

```bash
# Stop all running instances
aws ec2 stop-instances \
    --instance-ids $(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text) \
    --region us-east-1

# Or terminate (deletes everything!)
aws ec2 terminate-instances --instance-ids i-051cb6ac6bf116c23 --region us-east-1
```

---

## Monitoring Your Costs

### Daily Check (Quick)
```bash
# Today's estimated charges
aws cloudwatch get-metric-statistics \
    --namespace AWS/Billing \
    --metric-name EstimatedCharges \
    --dimensions Name=Currency,Value=USD \
    --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 86400 \
    --statistics Maximum \
    --region us-east-1
```

### View Current Month's Cost
1. Go to: https://console.aws.amazon.com/billing/home#/bills
2. View current month's bill

---

## Free Tier Reminders

### First 12 Months:
- ✅ 750 hours/month of t2.micro EC2 (not t3 or c7i!)
- ✅ 30 GB EBS storage
- ✅ 5 GB S3 storage
- ✅ 100 GB data transfer out

### Always Free:
- ✅ AWS Lambda: 1M requests/month
- ✅ DynamoDB: 25 GB storage
- ✅ CloudWatch: 10 custom metrics

**Note**: c7i-flex.large is NOT free tier eligible!

---

## Questions?

- **How much have I spent so far?**
  - Check: https://console.aws.amazon.com/billing/home#/bills

- **How much will this cost?**
  - Calculator: https://calculator.aws/

- **How do I get credits?**
  - Students: AWS Educate ($100 credits)
  - Startups: AWS Activate (up to $100k)

---

**Remember**: The best way to save money is to **stop instances when not using them**! 💰

