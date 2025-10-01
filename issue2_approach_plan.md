# Issue 2: LLM Service Implementation Plan

## Overview

Based on your current EC2 type (`c7i-flex.large`, CPU-only) noted in `SESSION-SUMMARY.md`, we will implement the service using `llama.cpp` for both local macOS (Metal) and EC2 CPU. We'll maintain OpenAI-compatible APIs and SSE streaming now, and reserve the performance SLOs for a later GPU upgrade.

- **Reference**: Issue details and acceptance criteria: [Task 1 LLM Service Implementation](https://github.com/deepspeccode/voicebot-rag-practice/issues/2)

## Branches

- `feat/task-1-part-a-llamacpp-docker`
- `feat/task-1-part-b-openai-api`
- `feat/task-1-part-c-sse-streaming`
- `feat/task-1-part-d-performance`

## Scope per part

### Part A (Setup)
- Create `services/llm/Dockerfile` using `llama.cpp` (build with OpenBLAS/Metal locally; pure CPU path for EC2)
- Add model bootstrap scripts and config (Llama 3.1 8B Instruct in GGUF, e.g., Q4_K_M)
- Wire `docker-compose.yml` service `llm` with resource limits and volumes
- Basic `/healthz` from a thin FastAPI wrapper in `services/llm/main.py`

### Part B (OpenAI API)
- Implement `POST /v1/chat/completions` in `services/llm/main.py` to call `llama.cpp` server/binary
- Request/response schemas matching OpenAI compatibility
- Add `/metrics` (Prometheus) and structured logging

### Part C (Streaming SSE)
- Implement streaming via SSE on `/v1/chat/completions` when `stream=true`
- Proper data framing (event: message, data: {...}), flush, and end-of-stream token
- Cancellation handling (client disconnect) and time-to-first-token capture

### Part D (Performance)
- Tune CPU parameters: context length, batch size, CPU threads, `--mirostat`/`--grammar` if helpful
- Attempt first-token latency improvements and throughput on EC2 CPU (best-effort)
- Document that meeting ≤300ms and ≥30 tok/s likely requires GPU; propose `g5.xlarge` + vLLM for Phase 2.5

## File touchpoints

- `services/llm/Dockerfile`
- `services/llm/main.py`
- `services/llm/requirements.txt` (minimal FastAPI/uvicorn if wrapper used)
- `docker-compose.yml` (add `llm` service, network, env)
- `README.md` updates for running LLM service locally and on EC2

## Notes

- Keep OpenAI-compatible API for easy client reuse
- Use GGUF Q4_K_M to keep memory < 16GB (target ≈ 5–8GB)
- Expose `/metrics` for existing Prometheus stack
- Defer GPU migration to a follow-up sub-task; we'll preserve the same API surface for a transparent swap later

## To-dos

- [ ] Create `services/llm` with llama.cpp Dockerfile and model setup
- [ ] Add `llm` service to `docker-compose.yml` with env/volumes/healthcheck
- [ ] Implement OpenAI-compatible `/v1/chat/completions` in FastAPI wrapper
- [ ] Add `/healthz` and `/metrics` (Prometheus) to LLM service
- [ ] Add SSE streaming to chat completions with proper framing
- [ ] Tune CPU params; measure TTFB and tok/s; document results
- [ ] Draft GPU migration plan (g5.xlarge + vLLM) to hit SLOs
