#!/bin/bash

################################################################################
# Voicebot RAG - EC2 User Data Script
################################################################################
#
# This script runs automatically when an EC2 instance launches
# Use this as "User Data" in EC2 launch configuration
#
# What it does:
# - Runs the full production setup automatically
# - Logs all output to /var/log/voicebot-setup.log
# - Creates a marker file when complete
#
################################################################################

# Redirect all output to log file
exec > >(tee -a /var/log/voicebot-setup.log)
exec 2>&1

echo "=========================================="
echo "Voicebot RAG - EC2 Instance Initialization"
echo "Started: $(date)"
echo "=========================================="

# Wait for cloud-init to finish
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    echo "Waiting for cloud-init to finish..."
    sleep 1
done

echo "Cloud-init complete, starting setup..."

# Change to ubuntu user's home directory
cd /home/ubuntu

# Download the setup script from your repository
# TODO: Update this URL to your actual repository
SETUP_SCRIPT_URL="https://raw.githubusercontent.com/deepspeccode/voicebot-rag-practice/main/deploy/setup-production.sh"

echo "Downloading setup script..."
curl -fsSL "$SETUP_SCRIPT_URL" -o setup-production.sh
chmod +x setup-production.sh

# Run setup script as ubuntu user
echo "Running setup script..."
sudo -u ubuntu bash -c "./setup-production.sh"

# Mark setup as complete
touch /home/ubuntu/.voicebot-setup-complete
echo "Setup complete: $(date)" >> /home/ubuntu/.voicebot-setup-complete

echo "=========================================="
echo "EC2 Instance Initialization Complete"
echo "Completed: $(date)"
echo "=========================================="

