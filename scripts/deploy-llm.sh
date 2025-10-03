#!/bin/bash
# deploy-llm.sh - Deploy LLM service as a standalone module
# This script demonstrates the modular deployment approach

set -e  # Exit on any error

echo "🚀 Deploying LLM Service (Modular Approach)"
echo "=========================================="

# Configuration
SERVICE_NAME="llm"
CONTAINER_NAME="voicebot-llm"
PORT="8001"
HEALTH_ENDPOINT="http://localhost:${PORT}/healthz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi
print_status "Docker is running"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run from project root."
    exit 1
fi
print_status "docker-compose.yml found"

# Check if port is available or container exists
if lsof -Pi :${PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Port ${PORT} is already in use. Stopping existing service..."
    docker-compose down ${SERVICE_NAME} 2>/dev/null || true
    sleep 2
fi

# Check if container exists and remove it
if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    print_warning "Container ${CONTAINER_NAME} already exists. Removing it..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
    sleep 2
fi

# Build and start the service
echo "🏗️  Building LLM service..."
docker-compose build ${SERVICE_NAME}

echo "🚀 Starting LLM service..."
docker-compose up -d ${SERVICE_NAME}

# Wait for service to be ready
echo "⏳ Waiting for service to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s -f ${HEALTH_ENDPOINT} >/dev/null 2>&1; then
        print_status "LLM service is healthy and ready!"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    echo "   Attempt ${ATTEMPT}/${MAX_ATTEMPTS} - waiting for service..."
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    print_error "Service failed to start within expected time"
    echo "📋 Debug information:"
    echo "   Container logs:"
    docker-compose logs ${SERVICE_NAME}
    echo "   Container status:"
    docker-compose ps ${SERVICE_NAME}
    exit 1
fi

# Test the service
echo "🧪 Testing service endpoints..."

# Test health endpoint
echo "   Testing /healthz endpoint..."
HEALTH_RESPONSE=$(curl -s ${HEALTH_ENDPOINT})
if echo "$HEALTH_RESPONSE" | grep -q '"status":"ok"'; then
    print_status "Health endpoint working"
else
    print_error "Health endpoint failed: $HEALTH_RESPONSE"
    exit 1
fi

# Test chat completions endpoint
echo "   Testing /v1/chat/completions endpoint..."
CHAT_RESPONSE=$(curl -s -X POST http://localhost:${PORT}/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"messages": [{"role": "user", "content": "Hello!"}]}')
if echo "$CHAT_RESPONSE" | grep -q '"object":"chat.completion"'; then
    print_status "Chat completions endpoint working"
else
    print_error "Chat completions endpoint failed: $CHAT_RESPONSE"
    exit 1
fi

# Test streaming endpoint
echo "   Testing streaming endpoint..."
STREAM_RESPONSE=$(curl -s -X POST http://localhost:${PORT}/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"messages": [{"role": "user", "content": "Hello!"}], "stream": true}' | head -1)
if echo "$STREAM_RESPONSE" | grep -q "data:"; then
    print_status "Streaming endpoint working"
else
    print_error "Streaming endpoint failed: $STREAM_RESPONSE"
    exit 1
fi

# Success!
echo ""
echo "🎉 LLM Service Deployment Successful!"
echo "====================================="
echo "📍 Service URL: http://localhost:${PORT}"
echo "🔍 Health Check: ${HEALTH_ENDPOINT}"
echo "💬 Chat API: http://localhost:${PORT}/v1/chat/completions"
echo ""
echo "📋 Useful commands:"
echo "   View logs:    docker-compose logs -f ${SERVICE_NAME}"
echo "   Stop service: docker-compose down ${SERVICE_NAME}"
echo "   Restart:      docker-compose restart ${SERVICE_NAME}"
echo ""
echo "🔧 This service is designed to be modular and can be:"
echo "   - Deployed independently"
echo "   - Scaled separately from other services"
echo "   - Integrated with orchestration systems (K8s, etc.)"
echo "   - Monitored via health checks and metrics"
