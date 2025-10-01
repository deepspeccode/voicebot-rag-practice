# Voicebot RAG Practice Repo Setup Guide

This document provides a detailed, step-by-step set of instructions for
setting up a practice GitHub repository in Cursor IDE to learn and
implement all the project tasks (Tasks 0--9).

------------------------------------------------------------------------

## 0) Prerequisites

1.  Install GitHub CLI and authenticate:

    ``` bash
    brew install gh               # macOS; Linux: apt/yum/pacman as needed
    gh auth login                 # follow prompts (HTTPS, your account, device code)
    ```

2.  In Cursor: sign into GitHub (lower-left account menu).\

3.  Install Node 18+, Python 3.10+, Docker Desktop (with GPU
    pass-through if available).

------------------------------------------------------------------------

## 1) Create the repo in Cursor

**Repo name suggestion:** `voicebot-rag-practice`

``` bash
mkdir voicebot-rag-practice && cd voicebot-rag-practice
git init -b main
gh repo create voicebot-rag-practice --public --source=. --remote=origin --push
```

Scaffold repo structure:

``` bash
mkdir -p services/{app,llm,stt,tts,rag,nginx}/
mkdir -p landing/
mkdir -p deploy/{aws,compose}/
mkdir -p monitoring/{grafana,prometheus}/
mkdir -p infra/{terraform,vpc-examples}/
mkdir -p .github/ISSUE_TEMPLATE
touch README.md .env.example docker-compose.yml
```

**README.md**

``` md
# Voice+Text Chatbot (Practice Repo)
Targets: low-latency voice+text, open-source 7B–8B model, Whisper STT, local TTS, RAG, FastAPI orchestration, Next.js landing, observability, TLS.

SLOs:
- First token ≤ 300 ms (text) / ≤ 700 ms (voice)
- Audio → partial transcript ≤ 800 ms
- Streaming ≥ 30 tok/s on 8B (GPU)
- P99 end-to-end ≤ 2.5 s
```

**.env.example**

``` bash
OPENAI_COMPAT_BASE_URL=http://localhost:8001/v1
MODEL_NAME=llama-3.1-8b-instruct
EMBED_MODEL=intfloat/e5-small-v2
PG_DSN=postgresql://user:pass@postgres:5432/rag
FAISS_PATH=/data/faiss.index
S3_BUCKET=voicebot-practice
JWT_SECRET=replace_me
```

------------------------------------------------------------------------

## 2) Minimal Docker Compose

**docker-compose.yml**

``` yaml
version: "3.9"
services:
  app:
    build: ./services/app
    env_file: .env
    ports: ["8080:8080"]
    depends_on: [llm, stt, tts]
  llm:
    build: ./services/llm
    environment:
      - MODEL_NAME=${MODEL_NAME}
    ports: ["8001:8001"]
  stt:
    build: ./services/stt
    ports: ["8002:8002"]
  tts:
    build: ./services/tts
    ports: ["8003:8003"]
  rag:
    build: ./services/rag
    volumes:
      - rag_data:/data
    ports: ["8004:8004"]
  nginx:
    build: ./services/nginx
    ports: ["80:80"]
    depends_on: [app]
volumes:
  rag_data:
```

------------------------------------------------------------------------

## 3) Starter Files

**services/app/Dockerfile**

``` dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY main.py requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**services/app/requirements.txt**

    fastapi
    uvicorn[standard]
    httpx
    pydantic
    python-socketio

**services/app/main.py**

``` python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
app = FastAPI()

@app.get("/healthz")
def health():
    return {"ok": True}

@app.get("/chat")
def chat():
    def gen():
        yield "data: boot\n\n"
        yield "data: ready\n\n"
    return StreamingResponse(gen(), media_type="text/event-stream")
```

------------------------------------------------------------------------

## 4) GitHub Hygiene

**Labels**

``` bash
gh label create "phase:foundations" --color BFD4F2 || true
gh label create "phase:services" --color C2E0C6 || true
gh label create "phase:rag" --color FEF2C0 || true
gh label create "phase:orchestration" --color FAE1E1 || true
gh label create "phase:frontend" --color E6E6FA || true
gh label create "phase:observability" --color E99695 || true
gh label create "type:doc" --color D4C5F9 || true
gh label create "type:infra" --color F9D0C4 || true
gh label create "type:bug" --color D73A4A || true
gh label create "good first issue" --color 7057ff || true
```

**Milestones**

``` bash
gh milestone create "Phase 1: Foundations"
gh milestone create "Phase 2: Core AI Services"
gh milestone create "Phase 3: RAG"
gh milestone create "Phase 4: Orchestration"
gh milestone create "Phase 5: Frontend"
gh milestone create "Phase 6: Observability & Hardening"
```

**Issue template** `.github/ISSUE_TEMPLATE/task.yml`

``` yaml
name: Task
description: Track a single task
title: "[Task] "
labels: []
body:
  - type: input
    id: goal
    attributes: {label: Goal, placeholder: "What outcome proves this is done?"}
  - type: textarea
    id: steps
    attributes: {label: Steps, placeholder: "- Step 1\n- Step 2"}
  - type: textarea
    id: acceptance
    attributes: {label: Acceptance, placeholder: "- Check 1\n- Check 2"}
```

**PR template** `.github/pull_request_template.md`

``` md
## What changed?
- 

## How to test
- 

## SLO alignment
- TTFB / STT latency / tok/s targeted here?
```

**CI** `.github/workflows/ci.yml`

``` yaml
name: CI
on:
  push: {branches: [main]}
  pull_request: {branches: [main]}
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Docker build
        run: docker build -q -f services/app/Dockerfile services/app
```

------------------------------------------------------------------------

## 5) Create GitHub Project

``` bash
gh project create "Voicebot RAG Learning Path" --format json
```

-   Columns: Backlog, In Progress, Blocked, Review, Done.\
-   Create issues for Tasks 0--9 using `gh issue create` and link to
    project.\
-   Use labels and milestones created earlier.

------------------------------------------------------------------------

## 6) Project Workflow

-   Open an issue in Cursor → "GitHub: Checkout Issue".\

-   Work in branch `feat/<task>`.\

-   Commit and push:

    ``` bash
    git checkout -b feat/llm-vllm
    git commit -am "feat(llm): add vLLM server with SSE support"
    git push -u origin HEAD
    gh pr create --fill
    ```

-   Link PR to issue and move card in Project board.

------------------------------------------------------------------------

## 7) Next Steps

-   Replace placeholder services with real ones:
    -   vLLM or llama.cpp in `services/llm`
    -   faster-whisper in `services/stt`
    -   Piper/Coqui-TTS in `services/tts`
-   Implement `/chat` (SSE) and `/voice` (WebSocket) in app.\
-   Build `landing/` with Next.js push-to-talk + streaming UI.\
-   Add observability with Prometheus, Grafana, CloudWatch.

------------------------------------------------------------------------

End of instructions.
