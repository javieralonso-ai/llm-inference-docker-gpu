#!/bin/bash

# ModelVault Inference Engine Script
# Purpose: Simulate AI model inference with Docker container
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
MODEL_NAME="vaultmodel-llama-7b"

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

# 2. Simulate Docker container check
echo -n "Checking inference container... "
if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} (Docker available)"
    log "INFO" "phase2_inference" "Docker available for container execution"
else
    echo -e "${YELLOW}! (Simulating without Docker)${NC}"
    log "WARNING" "phase2_inference" "Docker not available - using simulation mode"
fi

# 3. Loading model (simulated)
echo -n "Loading model $MODEL_NAME... "
log "INFO" "phase2_inference" "Loading model: $MODEL_NAME"
sleep 2  # Simulate loading time
echo -e "${GREEN}✓${NC}"
echo "  └─ Model size: 7B parameters"
echo "  └─ Quantization: Q4_K_M"
echo "  └─ Context length: 4096 tokens"

# 4. Processing inference
echo -n "Processing inference... "
log "INFO" "phase2_inference" "Processing prompt with $MODEL_NAME"

# Simulate processing with progress
echo ""
for i in {1..5}; do
    echo -ne "  └─ Progress: [$(printf '%-50s' $(printf '%*s' $((i*10)) | tr ' ' '='))] $((i*20))%\r"
    sleep 0.5
done
echo -e "  └─ Progress: [$(printf '%-50s' | tr ' ' '=')] 100%"

# 5. Generate output
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROCESSING_TIME=$((RANDOM % 2000 + 1000))  # Random time between 1000-3000ms

# Create realistic output based on prompt
cat > "$DATA_DIR/output.json" << EOF
{
    "model": "$MODEL_NAME",
    "prompt": "$PROMPT",
    "response": "ModelVault is an enterprise-grade on-premise AI appliance that enables organizations to deploy and run large language models locally. It provides several key benefits:\n\n1. **Data Security**: All processing happens within your infrastructure, ensuring sensitive data never leaves your premises.\n\n2. **Compliance**: Meet regulatory requirements by maintaining complete control over data processing and storage.\n\n3. **Performance**: Optimized hardware and software stack delivers consistent, low-latency responses.\n\n4. **Cost Predictability**: One-time hardware investment eliminates ongoing cloud API costs.\n\n5. **Customization**: Deploy fine-tuned models specific to your organization's needs.\n\nModelVault supports popular open-source models like Llama, Mistral, and others, making it a versatile solution for enterprises seeking to leverage AI while maintaining complete control.",
    "usage": {
        "prompt_tokens": 12,
        "completion_tokens": 147,
        "total_tokens": 159
    },
    "metadata": {
        "processing_time_ms": $PROCESSING_TIME,
        "timestamp": "$TIMESTAMP",
        "inference_mode": "simulated",
        "temperature": 0.7,
        "max_tokens": 150,
        "version": "1.0.0"
    }
}
EOF

echo -e "${GREEN}✓${NC} Inference completed"
log "SUCCESS" "phase2_inference" "Inference completed successfully in ${PROCESSING_TIME}ms"

# 6. Display results summary
echo ""
echo -e "${CYAN}Output summary:${NC}"
echo "  • Tokens used: 159 (12 prompt + 147 completion)"
echo "  • Processing time: ${PROCESSING_TIME}ms"
echo "  • Output saved to: data/output.json"

# 7. Validate output
if [ -f "$DATA_DIR/output.json" ]; then
    OUTPUT_SIZE=$(stat -c%s "$DATA_DIR/output.json" 2>/dev/null || stat -f%z "$DATA_DIR/output.json" 2>/dev/null || echo "0")
    if [ "$OUTPUT_SIZE" -gt 0 ]; then
        log "SUCCESS" "phase2_inference" "Output validated: ${OUTPUT_SIZE} bytes"
        exit 0
    else
        log "ERROR" "phase2_inference" "Output file is empty"
        exit 1
    fi
else
    log "ERROR" "phase2_inference" "Failed to generate output.json"
    exit 1
fi