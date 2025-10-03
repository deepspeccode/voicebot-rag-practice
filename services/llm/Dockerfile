# Stage 1: Builder for llama.cpp
FROM python:3.11-slim AS builder

WORKDIR /tmp

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    libcurl4-openssl-dev \
    libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone llama.cpp
RUN git clone https://github.com/ggerganov/llama.cpp.git

WORKDIR /tmp/llama.cpp

# Build llama.cpp with OpenBLAS for CPU optimization
RUN mkdir build && cd build && \
    cmake .. -DLLAMA_OPENBLAS=ON && \
    make -j$(nproc)

# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    libopenblas-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy llama.cpp binaries
COPY --from=builder /tmp/llama.cpp/build/bin/ /usr/local/bin/
# Ensure .so files are in a path ldconfig can find
RUN mv /usr/local/bin/*.so* /usr/local/lib/ 2>/dev/null || true && \
    ldconfig && \
    chmod +x /usr/local/bin/*

# Install Python dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Download TinyLlama model during build
RUN mkdir -p /models && \
    echo "Downloading TinyLlama 1.1B model..." && \
    wget -O /models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
        https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf && \
    echo "Model downloaded successfully!" && \
    ls -la /models/

# Copy application code
COPY . /app

# Create model config
RUN cat > /app/model_config.json << EOF
{
  "model_name": "tinyllama-1.1b-chat",
  "model_file": "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
  "model_path": "/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
  "quantization": "Q4_K_M",
  "context_size": 2048,
  "max_tokens": 512,
  "temperature": 0.7,
  "top_p": 0.9,
  "threads": 2,
  "batch_size": 256,
  "n_gpu_layers": 0,
  "description": "TinyLlama 1.1B Chat model - perfect for 4GB RAM"
}
EOF

EXPOSE 8001

CMD ["python", "main.py"]