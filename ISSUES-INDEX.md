# Voicebot RAG Practice - Issues Index

📊 **[Project Tracking](PROJECT_TRACKING.md)** | 🎯 **[GitHub Project](https://github.com/users/deepspeccode/projects/8)**

---

## 📋 All Issues & Sub-Tasks

### ✅ Phase 1: Foundations

#### [Issue #1] Task 0: Project Setup & Infrastructure
**Status:** 🟡 In Progress  
**Files:** [Full Details](ISSUE-1-SYSTEM-PREP.md) | [Quick Ref](ISSUE-1-QUICK-REFERENCE.md)

**Sub-Issues (6):**
- [ ] 1.1 - Connect and Update System
- [ ] 1.2 - Install Docker Engine and Compose Plugin
- [ ] 1.3 - Create Application Directory Structure
- [ ] 1.4 - Create Environment Configuration
- [ ] 1.5 - Install NVIDIA Driver & CUDA (GPU Path - Optional)
- [ ] 1.6 - Acceptance Checks

---

### 🤖 Phase 2: Core AI Services

#### [Issue #2] Task 1: LLM Service Implementation
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- vLLM or llama.cpp setup
- Streaming responses via SSE
- Performance: ≤ 300ms first token, ≥ 30 tok/s

---

#### [Issue #3] Task 2: Speech-to-Text (STT) Service
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- faster-whisper implementation
- Real-time streaming transcription
- Performance: ≤ 800ms audio → transcript

---

#### [Issue #4] Task 3: Text-to-Speech (TTS) Service
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- Piper or Coqui-TTS setup
- Natural voice synthesis
- Streaming audio generation

---

### 🔍 Phase 3: RAG

#### [Issue #5] Task 4: RAG Service Implementation
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- Vector database setup (FAISS/pgvector)
- Document ingestion and indexing
- Semantic search and retrieval

---

### 🔄 Phase 4: Orchestration

#### [Issue #6] Task 5: FastAPI Orchestration Layer
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- WebSocket support for real-time chat
- Service coordination and management
- Performance: P99 ≤ 2.5s end-to-end

---

### 🎨 Phase 5: Frontend

#### [Issue #7] Task 6: Next.js Frontend with Push-to-Talk
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- Modern responsive UI
- Push-to-talk audio recording
- Real-time chat interface

---

### 📊 Phase 6: Observability & Hardening

#### [Issue #8] Task 7: Observability & Monitoring
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- Prometheus metrics and Grafana dashboards
- Structured logging and alerting
- Performance monitoring

---

#### [Issue #9] Task 8: Production Deployment & Security
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- TLS/SSL and authentication
- Infrastructure as code
- Security best practices

---

#### [Issue #10] Task 9: Performance Optimization & Testing
**Status:** ⚪ Not Started  
**Files:** TBD

**Key Tasks:**
- Load testing and optimization
- SLO validation
- Performance regression testing

---

## 📈 Overall Progress

**Total Issues:** 10  
**Completed:** 0/10 (0%)

**Phase Progress:**
- Phase 1: 🟡 1/1 In Progress
- Phase 2: ⚪ 0/3 Not Started
- Phase 3: ⚪ 0/1 Not Started
- Phase 4: ⚪ 0/1 Not Started
- Phase 5: ⚪ 0/1 Not Started
- Phase 6: ⚪ 0/3 Not Started

---

## 🎯 Current Focus

**Active:** Issue #1 - System Prep & Infrastructure  
**Next:** Issue #2 - LLM Service Implementation

---

## 📚 Quick Links

- [Project Tracking Guide](PROJECT_TRACKING.md)
- [Issue #1 - Full Details](ISSUE-1-SYSTEM-PREP.md)
- [Issue #1 - Quick Reference](ISSUE-1-QUICK-REFERENCE.md)
- [GitHub Project Board](https://github.com/users/deepspeccode/projects/8)

---

## ℹ️ How to Use This Index

1. **Start Here:** Begin with Issue #1 and work sequentially
2. **Track Progress:** Check off sub-tasks as you complete them
3. **Reference:** Use the linked detail files for step-by-step instructions
4. **Update Status:** Change status indicators as you progress:
   - ⚪ Not Started
   - 🟡 In Progress
   - 🟢 Completed
   - 🔴 Blocked

---

**Last Updated:** 2025-09-30