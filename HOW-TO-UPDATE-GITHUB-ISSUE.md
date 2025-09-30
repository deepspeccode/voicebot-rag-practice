# How to Add Sub-Issues to GitHub Issue #1

Your sub-issues are documented locally but not visible on GitHub yet. Here's how to fix that:

---

## ✅ Quick Solution (Manual - 2 minutes)

1. **Open the template file:** `github-issue-1-body.md` (in this workspace)
2. **Copy all contents** from that file
3. **Go to your GitHub repository** and find Issue #1
   - Or go directly to: https://github.com/users/deepspeccode/projects/8
4. **Click "Edit"** on the issue description
5. **Paste the contents** to replace the current issue body
6. **Click "Update comment"**

✅ **Done!** Your sub-issues will now appear with checkboxes in the GitHub issue.

---

## 🤖 Automated Solution (Using GitHub CLI)

### Step 1: Authenticate with GitHub
```bash
gh auth login
```
Follow the prompts to authenticate (choose browser or token method).

### Step 2: Update the Repository Details
Edit the `update-github-issue.sh` file and replace:
- `REPO_OWNER="deepspeccode"` - Your GitHub username
- `REPO_NAME="voicebot-rag-practice"` - Your actual repository name

### Step 3: Run the Update Script
```bash
./update-github-issue.sh
```

This will automatically update Issue #1 with all sub-issues.

---

## 📝 What Gets Added

The sub-issues that will be added to your GitHub Issue #1:

✅ **1.1** - Connect and Update System  
✅ **1.2** - Install Docker Engine and Compose Plugin  
✅ **1.3** - Create Application Directory Structure  
✅ **1.4** - Create Environment Configuration  
✅ **1.5** - Install NVIDIA Driver & CUDA (GPU Path - Optional)  
✅ **1.6** - Acceptance Checks

Each will appear as a checkbox that you can check off as you complete them!

---

## 💡 Pro Tip

After updating the issue on GitHub:
- Check off sub-issues directly on GitHub as you complete them
- The checkboxes will automatically update
- Your progress will be visible to anyone viewing the issue

---

## 🆘 Troubleshooting

**Q: I don't know my repository name**  
A: Run: `gh repo view` (after authentication) or check your GitHub profile

**Q: The issue number is not 1**  
A: Update the script to use the correct issue number: `gh issue edit <NUMBER>`

**Q: I can't find Issue #1 on GitHub**  
A: Make sure you've created the issue on GitHub first. These markdown files are just local documentation.

---

**Questions?** The sub-issues are already well-documented in `ISSUE-1-SYSTEM-PREP.md` - this is just about making them visible on GitHub!