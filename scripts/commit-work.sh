#!/bin/bash
# commit-work.sh - Helper script for consistent commits

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "🔧 Git Commit Helper"
echo "==================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "Not in a git repository!"
    exit 1
fi

# Check git status
echo "📋 Current git status:"
git status --short

echo ""
echo "🔍 What would you like to commit?"

# Show options
echo "1. All changes (git add .)"
echo "2. Specific files (interactive)"
echo "3. Just check status"
echo "4. Exit"

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo "📦 Adding all changes..."
        git add .
        ;;
    2)
        echo "📁 Select files to add:"
        git status --porcelain | grep -v "^D" | while read line; do
            file=$(echo $line | cut -c4-)
            read -p "Add $file? (y/n): " add_file
            if [ "$add_file" = "y" ]; then
                git add "$file"
                print_status "Added $file"
            fi
        done
        ;;
    3)
        echo "📊 Git status:"
        git status
        exit 0
        ;;
    4)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        print_error "Invalid option!"
        exit 1
        ;;
esac

# Check if there are staged changes
if git diff --cached --quiet; then
    print_warning "No changes staged for commit!"
    exit 0
fi

echo ""
echo "📝 Staged changes:"
git diff --cached --name-only

echo ""
echo "💬 Enter commit message:"
echo "Format: type(scope): Brief description"
echo "Examples:"
echo "  feat(llm): Add OpenAI-compatible chat endpoint"
echo "  fix(docker): Resolve container name conflicts"
echo "  docs(readme): Update LLM service documentation"
echo "  test(llm): Add endpoint integration tests"

read -p "Commit message: " commit_message

if [ -z "$commit_message" ]; then
    print_error "Commit message cannot be empty!"
    exit 1
fi

# Confirm commit
echo ""
echo "🔍 About to commit:"
echo "Message: $commit_message"
echo "Files:"
git diff --cached --name-only | sed 's/^/  /'

read -p "Proceed with commit? (y/n): " confirm

if [ "$confirm" = "y" ]; then
    git commit -m "$commit_message"
    print_status "Commit successful!"
    
    echo ""
    read -p "Push to remote? (y/n): " push_confirm
    if [ "$push_confirm" = "y" ]; then
        git push origin $(git branch --show-current)
        print_status "Pushed to remote!"
    fi
else
    print_warning "Commit cancelled!"
fi

echo ""
print_info "Current branch: $(git branch --show-current)"
print_info "Last commit: $(git log -1 --oneline)"
