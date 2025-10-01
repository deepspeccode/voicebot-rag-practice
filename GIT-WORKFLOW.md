# Git Workflow & Branching Strategy

## 🤔 The Challenge

Your GitHub issues are complex with multiple sub-tasks:
- **Issue #1**: Has Part A (local) and Part B (production)  
- **Future issues**: Will have 3-6 sub-tasks each

**Question**: Should you create one branch per issue, or multiple branches per sub-task?

---

## 🌳 Three Branching Strategies

### Strategy 1: One Branch Per Issue ❌ **NOT RECOMMENDED**

```
main
 └── feat/task-0-setup (does ALL of Part A + Part B)
     → Creates giant PR with 50+ file changes
```

**Pros**:
- Simple
- Fewer branches

**Cons**:
- ❌ Massive PRs (hard to review)
- ❌ All-or-nothing (can't merge Part A before Part B done)
- ❌ Hard to get feedback on incremental progress
- ❌ If something breaks, hard to isolate
- ❌ Loses checkpoint opportunities

---

### Strategy 2: Sub-Task Branches ✅ **RECOMMENDED FOR YOU**

```
main
 ├── feat/task-0-part-a (Part A: Local development)
 │   → Small PR, merge when Part A done ✅
 │   → Create checkpoint
 │
 └── feat/task-0-part-b (Part B: Production setup)
     → Small PR, merge when Part B done ✅
     → Create checkpoint
```

**Pros**:
- ✅ Small, focused PRs (easy to review)
- ✅ Incremental progress (merge Part A, then Part B)
- ✅ Clear checkpoints after each part
- ✅ Easier to troubleshoot
- ✅ Better learning (understand each piece)
- ✅ Can get feedback along the way

**Cons**:
- More branches to manage (but worth it!)

---

### Strategy 3: Stacked Branches 🔧 **ADVANCED**

```
main
 └── feat/task-0-base
     ├── feat/task-0-part-a (based on task-0-base)
     └── feat/task-0-part-b (based on task-0-part-a)
```

**Pros**:
- Very organized
- Can work on Part B while Part A is in review

**Cons**:
- Complex to manage
- Overkill for this project

---

## 🎯 Recommended Workflow For Your Project

### **Use Strategy 2: Sub-Task Branches**

For each issue with multiple parts:

#### Example: Issue #1 (Task 0)

**Part A:**
```bash
git checkout main
git pull
git checkout -b feat/task-0-part-a-local-setup

# Work on Part A
# Commit frequently
git add .
git commit -m "feat(task-0): Part A - Create project structure"
git commit -m "feat(task-0): Part A - Add FastAPI app"
git commit -m "feat(task-0): Part A - Add GitHub templates"

# When Part A is done:
git push -u origin feat/task-0-part-a-local-setup
gh pr create --title "[Task 0 - Part A] Local Development Setup" --body "Completes Part A of #1"

# Merge PR
# Create checkpoint: git tag v0.1.0-task0-part-a
```

**Part B:**
```bash
git checkout main
git pull  # Get merged Part A
git checkout -b feat/task-0-part-b-production

# Work on Part B
git commit -m "feat(task-0): Part B - Add deployment scripts"
git commit -m "feat(task-0): Part B - Test on EC2"

# When Part B is done:
git push -u origin feat/task-0-part-b-production
gh pr create --title "[Task 0 - Part B] Production Infrastructure" --body "Completes Part B of #1"

# Merge PR
# Create checkpoint: git tag v0.1.0-task0-complete
```

---

## 📏 Branch Naming Convention

### Format:
```
feat/task-N-part-X-brief-description
```

### Examples:

**Task 0**:
- `feat/task-0-part-a-local-setup`
- `feat/task-0-part-b-production`

**Task 1** (LLM Service):
- `feat/task-1-part-a-vllm-setup`
- `feat/task-1-part-b-streaming-sse`
- `feat/task-1-part-c-performance-tuning`

**Task 2** (STT):
- `feat/task-2-part-a-whisper-setup`
- `feat/task-2-part-b-streaming-audio`

---

## 📋 Breaking Down Complex Issues

### Before Starting an Issue:

1. **Read the issue carefully**
2. **Identify natural sub-tasks** (usually 2-5)
3. **Plan your branches**:
   - Part A: Setup/foundation
   - Part B: Core functionality  
   - Part C: Testing/optimization
   - Part D: Documentation

### Example: Issue #2 (LLM Service)

**Potential Parts**:
- **Part A**: vLLM Docker setup + model download
- **Part B**: OpenAI-compatible API endpoint
- **Part C**: Streaming SSE implementation
- **Part D**: Performance tuning (hit SLO targets)

**Branches**:
```bash
feat/task-1-part-a-vllm-docker
feat/task-1-part-b-api-endpoint
feat/task-1-part-c-sse-streaming
feat/task-1-part-d-performance
```

---

## 🔄 Workflow Steps

### 1. Start a Sub-Task

```bash
# Always start from updated main
git checkout main
git pull origin main

# Create sub-task branch
git checkout -b feat/task-N-part-X-description

# Work on it
# Commit frequently with clear messages
```

### 2. Complete Sub-Task

```bash
# Push branch
git push -u origin feat/task-N-part-X-description

# Create PR
gh pr create \
  --title "[Task N - Part X] Brief Description" \
  --body "Completes Part X of #N

## What changed
- Item 1
- Item 2

## Testing
- Tested locally ✅
- Docker builds ✅

## Ready for
Part X+1"

# Get review (optional for solo learning)
# Merge PR
gh pr merge
```

### 3. Create Checkpoint (Optional)

```bash
git checkout main
git pull

# Tag if it's a significant milestone
git tag -a v0.X.Y-task-N-part-X -m "Task N Part X complete"
git push origin v0.X.Y-task-N-part-X
```

### 4. Move to Next Part

```bash
# Start fresh from updated main
git checkout main
git pull

# Next part builds on previous work
git checkout -b feat/task-N-part-Y-description
```

---

## 📊 Commit Message Convention

### Format:
```
type(task-N): Part X - Brief description

Detailed explanation if needed.

- Change 1
- Change 2

Relates to #N
```

### Examples:

```bash
git commit -m "feat(task-0): Part A - Add project structure

Created complete directory structure for all services,
landing page, deployment, and infrastructure.

- services/ with 6 subdirectories
- landing/ for Next.js frontend
- deploy/ for AWS and Docker Compose
- monitoring/ for observability

Relates to #1"
```

```bash
git commit -m "feat(task-1): Part B - Implement SSE streaming

Added Server-Sent Events support for streaming LLM responses.

- Created streaming generator function
- Implemented SSE format
- Added error handling
- Tested with curl

Performance: First token in 285ms ✅

Relates to #2"
```

---

## 🎯 Benefits of Sub-Task Branches

### For Learning:
1. ✅ **Smaller chunks** - Less overwhelming
2. ✅ **Clear progress** - See what you've completed
3. ✅ **Better understanding** - Focus on one thing at a time
4. ✅ **Easier debugging** - Isolate which part has issues

### For Quality:
1. ✅ **Reviewable PRs** - Small enough to understand
2. ✅ **Testable increments** - Test each part independently
3. ✅ **Safer merges** - Smaller changes = less risk
4. ✅ **Clear history** - Git log shows logical progression

### For Recovery:
1. ✅ **Checkpoints** - Can go back to any completed part
2. ✅ **Rollback** - Revert just Part B without losing Part A
3. ✅ **Debug** - Know exactly which part introduced a bug

---

## 📝 Updated Issue Template

When creating issues, structure them like this:

```markdown
## Goal
Implement LLM service with streaming responses

## Parts

### Part A: vLLM Setup
- [ ] Create Dockerfile
- [ ] Configure model loading
- [ ] Test Docker build

**Branch**: `feat/task-1-part-a-vllm-setup`
**Estimated**: 2-3 hours

### Part B: API Endpoint
- [ ] Implement /v1/chat/completions
- [ ] Add health check
- [ ] Test with curl

**Branch**: `feat/task-1-part-b-api-endpoint`
**Estimated**: 1-2 hours

### Part C: SSE Streaming
- [ ] Add streaming support
- [ ] Implement SSE format
- [ ] Test streaming performance

**Branch**: `feat/task-1-part-c-sse-streaming`
**Estimated**: 2 hours

### Part D: Performance Tuning
- [ ] Optimize first token latency
- [ ] Hit 30 tok/s target
- [ ] Document performance

**Branch**: `feat/task-1-part-d-performance`
**Estimated**: 2-3 hours
```

---

## 🔄 Example: Task 1 Workflow

### Week 1: Part A
```bash
git checkout -b feat/task-1-part-a-vllm-setup
# Implement vLLM Docker setup
git commit -m "feat(task-1): Part A - Add vLLM Dockerfile"
git commit -m "feat(task-1): Part A - Configure model loading"
git push -u origin feat/task-1-part-a-vllm-setup
gh pr create --title "[Task 1 - Part A] vLLM Setup"
gh pr merge
```

### Week 2: Part B  
```bash
git checkout main && git pull
git checkout -b feat/task-1-part-b-api-endpoint
# Implement API
git commit -m "feat(task-1): Part B - Add chat completions endpoint"
git push -u origin feat/task-1-part-b-api-endpoint
gh pr create --title "[Task 1 - Part B] API Endpoint"
gh pr merge
```

And so on...

---

## 🏷️ Tagging Strategy

### After Each Significant Part:

```bash
# After Part A
git tag v0.2.1-task1-part-a
git push origin v0.2.1-task1-part-a

# After Part B
git tag v0.2.2-task1-part-b
git push origin v0.2.2-task1-part-b

# After full task complete
git tag v0.2.0-task1-complete
git push origin v0.2.0-task1-complete
```

### Version Format:
```
v0.TASK.PART-description

v0.1.0-task0-complete       (whole task)
v0.2.1-task1-part-a         (sub-task)
v0.2.2-task1-part-b         (sub-task)
v0.2.0-task1-complete       (whole task)
```

---

## 📐 How to Decide: One Branch or Multiple?

### Use ONE branch when:
- Task has < 3 sub-parts
- All parts must be done together
- Parts are interdependent
- Quick task (< 4 hours total)

### Use MULTIPLE branches when:
- Task has 3+ distinct sub-parts ✅ (Your case!)
- Each part can be tested independently
- Parts could be in different PRs
- Learning value in breaking it down

---

## 🎓 Learning Benefits

### With Sub-Task Branches:

**You learn**:
- Git branching best practices
- How to break down complex work
- Incremental development
- Code review workflow (even solo)

**You build**:
- Clear project history
- Reusable checkpoints
- Better understanding of each component

---

## 💡 Practical Example: Task 1

### Issue #2: LLM Service Implementation

**Instead of**:
```bash
git checkout -b feat/task-1-llm-service
# Do EVERYTHING (10+ hours of work)
# Create massive PR
```

**Do this**:
```bash
# Part A: Docker Setup (2-3 hours)
git checkout -b feat/task-1-part-a-vllm-docker
# Setup vLLM, test it works
gh pr create --title "[Task 1 - Part A] vLLM Docker Setup"
gh pr merge

# Part B: API Endpoint (2 hours)
git checkout main && git pull
git checkout -b feat/task-1-part-b-openai-api
# Implement /v1/chat/completions
gh pr create --title "[Task 1 - Part B] OpenAI API Endpoint"
gh pr merge

# Part C: Streaming (2 hours)
git checkout main && git pull
git checkout -b feat/task-1-part-c-sse-streaming
# Add SSE streaming
gh pr create --title "[Task 1 - Part C] SSE Streaming"
gh pr merge

# Part D: Performance (2-3 hours)
git checkout main && git pull
git checkout -b feat/task-1-part-d-performance
# Optimize to hit SLO targets
gh pr create --title "[Task 1 - Part D] Performance Tuning"
gh pr merge

# Final checkpoint
git tag v0.2.0-task1-complete
```

---

## 📋 Recommended Workflow

### For Your Project:

1. **Break each issue into 2-4 parts**
2. **Create a branch for each part**
3. **Merge incrementally**
4. **Create checkpoints**

### Branch Lifecycle:

```
Create → Work → Commit → Push → PR → Review → Merge → Tag → Delete
   ↓       ↓       ↓       ↓      ↓      ↓       ↓      ↓      ↓
  Day 1  Day 1-2  Daily  Done   Done   (opt)   Done  (opt)  Auto
```

---

## 🔄 Complete Example Workflow

### Issue #2: LLM Service (Future)

**Planning Phase**:
```bash
# Read issue
gh issue view 2

# Plan parts:
# Part A: vLLM Docker setup
# Part B: API endpoint
# Part C: SSE streaming  
# Part D: Performance tuning
```

**Part A**:
```bash
# Day 1
git checkout -b feat/task-1-part-a-vllm-docker

# Work on it
# Create Dockerfile
git add services/llm/Dockerfile
git commit -m "feat(task-1): Part A - Add vLLM Dockerfile"

# Add model config
git commit -m "feat(task-1): Part A - Configure Llama 3.1 8B"

# Test it works
docker build -t voicebot-llm services/llm
git commit -m "feat(task-1): Part A - Verify Docker build works"

# Push and create PR
git push -u origin feat/task-1-part-a-vllm-docker
gh pr create \
  --title "[Task 1 - Part A] vLLM Docker Setup" \
  --body "Completes Part A of #2

## Changes
- vLLM Dockerfile
- Model configuration
- Build verification

## Testing
- Docker builds successfully ✅
- Container starts ✅
- Model loads ✅

## Next
Ready for Part B: API endpoint implementation"

# Merge when ready
gh pr merge

# Optional checkpoint
git checkout main && git pull
git tag v0.2.1-task1-part-a
git push origin v0.2.1-task1-part-a
```

**Part B**:
```bash
# Day 2
git checkout main
git pull  # Get Part A changes
git checkout -b feat/task-1-part-b-openai-api

# Implement API
git commit -m "feat(task-1): Part B - Add chat completions endpoint"
git commit -m "feat(task-1): Part B - Add request/response models"

# Push and merge
git push -u origin feat/task-1-part-b-openai-api
gh pr create --title "[Task 1 - Part B] OpenAI API Endpoint"
gh pr merge
```

Continue for Parts C and D...

---

## 🎯 Benefits For Your Learning

### Week 1: Part A Done
- ✅ Have working vLLM Docker container
- ✅ Can test and understand it
- ✅ Checkpoint to return to
- ✅ Clear accomplishment

### Week 2: Part B Done  
- ✅ Now have API endpoint
- ✅ Built on Part A (still working!)
- ✅ Another checkpoint
- ✅ Incremental learning

### Better Than:
- ❌ Week 1-2: Everything together
- ❌ Not sure what works
- ❌ Hard to debug
- ❌ Overwhelming

---

## 📊 PR Size Guidelines

### Ideal PR Size:
- **Files changed**: 3-10 files
- **Lines changed**: 100-500 lines
- **Commits**: 2-5 commits
- **Review time**: 10-20 minutes

### Too Large:
- Files changed: 20+ files
- Lines changed: 1000+ lines
- Takes hours to review
- **Solution**: Break into parts!

---

## 🔧 Git Commands Reference

### Branch Management

```bash
# List all branches
git branch -a

# Delete local branch (after merged)
git branch -d feat/task-1-part-a-vllm-docker

# Delete remote branch
git push origin --delete feat/task-1-part-a-vllm-docker

# Switch branches
git checkout main
git checkout feat/task-1-part-b-api
```

### Keeping Branches Updated

```bash
# If Part B needs changes from main
git checkout feat/task-1-part-b-api
git pull origin main  # Merge latest changes from main
```

### Viewing Changes

```bash
# See what changed in this branch
git diff main

# See commits in this branch
git log main..HEAD
```

---

## 📝 Updated Issue Structure

When creating issues, structure like this:

```markdown
## Goal
[What you're building]

---

## Part A: [Name] 

**Branch**: `feat/task-N-part-a-description`
**Time**: X hours
**Checkpoint**: Optional

### Tasks
- [ ] Task 1
- [ ] Task 2

### Acceptance
- [ ] Criteria 1
- [ ] Criteria 2

---

## Part B: [Name]

**Branch**: `feat/task-N-part-b-description`  
**Time**: X hours
**Checkpoint**: Optional

### Tasks
- [ ] Task 1
- [ ] Task 2

### Acceptance
- [ ] Criteria 1
- [ ] Criteria 2

---

## Final Acceptance (All Parts)

- [ ] All parts merged
- [ ] All tests pass
- [ ] SLO targets hit
- [ ] Documentation complete

**Final Checkpoint**: `v0.X.0-taskN-complete`
```

---

## 🎯 Summary: Your Workflow

### For Each Task:

1. **Read issue** → Identify natural parts (2-4)
2. **Create branch** for Part A
3. **Work & commit** frequently
4. **Test** thoroughly
5. **Push & PR** when Part A done
6. **Merge** Part A
7. **Optional checkpoint** tag
8. **Repeat** for Parts B, C, D...
9. **Final checkpoint** when task complete

### Benefits:
- ✅ Clear progress
- ✅ Easy to review
- ✅ Safe checkpoints
- ✅ Better learning
- ✅ Professional workflow

---

## 🎓 Pro Tips

1. **Commit early, commit often** - Multiple commits per part is good
2. **Descriptive messages** - Future you will thank you
3. **Test before merging** - Make sure it works
4. **Tag milestones** - Easy to return to
5. **Delete merged branches** - Keep repo clean

---

## 📖 Additional Resources

- **Git Branching**: https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows
- **Conventional Commits**: https://www.conventionalcommits.org/
- **GitHub Flow**: https://guides.github.com/introduction/flow/

---

**Your recommended workflow**: Sub-task branches with incremental merges! ✅

