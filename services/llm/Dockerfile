# Multi-stage build for llama.cpp with CPU optimization
FROM python:3.11-slim as builder

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

# Build llama.cpp
WORKDIR /tmp
RUN git clone https://github.com/ggerganov/llama.cpp.git
WORKDIR /tmp/llama.cpp

# Configure and build with OpenBLAS
RUN mkdir build && cd build && \
    cmake .. -DLLAMA_OPENBLAS=ON && \
    make -j$(nproc)

# Runtime stage
FROM python:3.11-slim

# Install runtime dependencies including Intel MKL
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    libopenblas-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy llama.cpp binaries and shared libraries from builder
COPY --from=builder /tmp/llama.cpp/build/bin/ /usr/local/bin/

# Move shared libraries to proper location
RUN mv /usr/local/bin/*.so* /usr/local/lib/ 2>/dev/null || true && \
    ldconfig && \
    chmod +x /usr/local/bin/*

# Install Python dependencies
COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . /app

# Create models directory
RUN mkdir -p /models

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/healthz || exit 1

# Start the FastAPI application
CMD ["python", "main.py"]
