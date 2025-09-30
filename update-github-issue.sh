#!/bin/bash
# Script to update GitHub Issue #1 with sub-issues

# Step 1: Authenticate with GitHub (run this first)
echo "Step 1: Authenticate with GitHub CLI"
echo "Run: gh auth login"
echo ""

# Step 2: Set your repository (replace with your actual repo)
echo "Step 2: Set your repository owner and name"
REPO_OWNER="deepspeccode"  # Replace with your GitHub username
REPO_NAME="voicebot-rag-practice"  # Replace with your repository name

# Step 3: Update the issue
echo "Step 3: Update Issue #1"
gh issue edit 1 \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --body-file github-issue-1-body.md

echo "Done! Issue #1 has been updated with sub-issues."