#!/bin/bash

# ModelVault Inference Engine Script
# Purpose: Real AI model inference with Docker container and Ollama
# Phase: 2 - Model Inference
# Author: Javier Alonso

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DATA_DIR="../data"
DOCKER_DIR="../docker"
LOGS_DIR="../logs"
IMAGE_NAME="vaultmodel-ollama"
IMAGE_TAG="latest"
CONTAINER_NAME="vaultmodel-inference"
MODEL_NAME="mistral"

# Log function - use parent session if available
log() {
    # If parent session exists, write directly to its log file
    if [ -n "$SESSION_DIR" ] && [ -f "../$SESSION_DIR/execution.jsonl" ]; then
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
        echo "{\"timestamp\": \"$timestamp\", \"level\": \"$1\", \"component\": \"$2\", \"message\": \"$3\"}" >> "../$SESSION_DIR/execution.jsonl"
    else
        python3 ../utils/simple_logger.py log "$1" "$2" "$3"
    fi
}

echo -e "${BLUE}Starting inference engine...${NC}"
log "INFO" "phase2_inference" "Starting model inference pipeline"

# Acquire semaphore lock to prevent concurrent model executions
echo -n "Acquiring inference lock... "
if ../utils/semaphore_manager.sh acquire; then
    log "SUCCESS" "phase2_inference" "Inference lock acquired"
else
    echo -e "${RED}✗${NC} Failed to acquire lock (timeout or error)"
    log "ERROR" "phase2_inference" "Failed to acquire inference lock - another process may be running"
    exit 1
fi

# Set trap to release lock on exit
trap 'echo "Releasing inference lock..."; ../utils/semaphore_manager.sh release; log "INFO" "phase2_inference" "Inference lock released"' EXIT INT TERM

# 1. Check/Create input file
if [ ! -f "$DATA_DIR/input.json" ]; then
    echo -e "${YELLOW}Creating sample input...${NC}"
    mkdir -p "$DATA_DIR"
    cat > "$DATA_DIR/input.json" << EOF
{
    "prompt": "What is ModelVault and how does it help enterprises?",
    "max_tokens": 150,
    "temperature": 0.7,
    "model": "$MODEL_NAME"
}
EOF
    log "INFO" "phase2_inference" "Created sample input.json"
fi

# Display input
echo -e "${CYAN}Input prompt:${NC}"
PROMPT=$(cat "$DATA_DIR/input.json" | python3 -c "import json,sys; print(json.load(sys.stdin)['prompt'])")
echo "  \"$PROMPT\""
echo ""

# 2. Check Docker availability
echo -n "Checking Docker... "
if ! command -v docker &> /dev/null || ! docker info &> /dev/null 2>&1; then
    echo -e "${RED}✗${NC}"
    echo "Docker is required for real inference. Please install Docker."
    log "ERROR" "phase2_inference" "Docker not available"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker is running"
log "INFO" "phase2_inference" "Docker verified and running"

# 3. Build Docker image if needed
echo -n "Checking Docker image... "
if ! docker images | grep -q "^${IMAGE_NAME}.*${IMAGE_TAG}"; then
    echo -e "${YELLOW}Building...${NC}"
    log "INFO" "phase2_inference" "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}"
    
    cd "$DOCKER_DIR"
    if docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .; then
        echo -e "${GREEN}✓${NC} Image built successfully"
        log "SUCCESS" "phase2_inference" "Docker image built"
    else
        echo -e "${RED}✗${NC} Failed to build image"
        log "ERROR" "phase2_inference" "Docker build failed"
        exit 1
    fi
    cd - > /dev/null
else
    echo -e "${GREEN}✓${NC} Image exists"
    log "INFO" "phase2_inference" "Using existing Docker image"
fi

# 4. Stop any existing container
docker stop $CONTAINER_NAME 2>/dev/null && docker rm $CONTAINER_NAME 2>/dev/null

# 5. Run inference container
echo -e "${BLUE}Starting real inference with Ollama...${NC}"
log "INFO" "phase2_inference" "Starting Docker container with Ollama"

# Get absolute paths for volume mounts
ABS_DATA_DIR=$(cd "$DATA_DIR" && pwd)
ABS_LOGS_DIR=$(cd "$LOGS_DIR" && pwd)
ABS_SESSION_DIR=$(cd ".." && pwd)/$SESSION_DIR

# Run container with GPU support if available
DOCKER_RUN_CMD="docker run --rm --name $CONTAINER_NAME"

# Add GPU support if nvidia-docker is available
if command -v nvidia-smi &> /dev/null && docker info 2>/dev/null | grep -q nvidia; then
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD --gpus all"
    echo "  └─ GPU acceleration enabled"
    log "INFO" "phase2_inference" "Running with GPU support"
fi

# Add volume mounts and environment
DOCKER_RUN_CMD="$DOCKER_RUN_CMD \
    --network host \
    -v $ABS_DATA_DIR:/data \
    -v $ABS_SESSION_DIR:/logs \
    -e MODEL_NAME=$MODEL_NAME \
    ${IMAGE_NAME}:${IMAGE_TAG}"

# Execute container
echo ""
if eval $DOCKER_RUN_CMD; then
    echo ""
    echo -e "${GREEN}✓${NC} Real inference completed successfully"
    log "SUCCESS" "phase2_inference" "Docker container executed successfully"
else
    echo ""
    echo -e "${RED}✗${NC} Container execution failed"
    log "ERROR" "phase2_inference" "Docker container failed"
    exit 1
fi

# 6. Display results summary
echo ""
echo -e "${CYAN}Output summary:${NC}"
if [ -f "$DATA_DIR/output.json" ]; then
    # Extract real metrics from output
    TOKENS=$(cat "$DATA_DIR/output.json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['usage']['total_tokens'])" 2>/dev/null || echo "N/A")
    PROC_TIME=$(cat "$DATA_DIR/output.json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['metadata']['processing_time_ms'])" 2>/dev/null || echo "N/A")
    
    echo "  • Total tokens: $TOKENS"
    echo "  • Processing time: ${PROC_TIME}ms"
    echo "  • Output saved to: data/output.json"
    echo "  • Inference mode: REAL (Ollama + $MODEL_NAME)"
    
    OUTPUT_SIZE=$(stat -c%s "$DATA_DIR/output.json" 2>/dev/null || stat -f%z "$DATA_DIR/output.json" 2>/dev/null || echo "0")
    if [ "$OUTPUT_SIZE" -gt 0 ]; then
        log "SUCCESS" "phase2_inference" "Real inference output validated: ${OUTPUT_SIZE} bytes"
    else
        log "ERROR" "phase2_inference" "Output file is empty"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} No output file generated"
    log "ERROR" "phase2_inference" "Failed to generate output.json"
    exit 1
fi