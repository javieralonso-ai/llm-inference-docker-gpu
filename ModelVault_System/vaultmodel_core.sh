#!/bin/bash

# VaultModel IA Core - Clean Version
# Purpose: Main orchestrator using simple Python logger
# Author: Javier Alonso

# Colors
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Change to script directory (force absolute path)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Initialize logger and capture session info
eval $(python3 utils/simple_logger.py init)
export SESSION_DIR SESSION_ID  # Export for child scripts

# Banner
clear
echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║        ${CYAN}VaultModel IA Orchestrator${PURPLE}              ║${NC}"
echo -e "${PURPLE}║      ${BLUE}Designed by Javier Alonso${PURPLE}                 ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Session:${NC} ${GREEN}$SESSION_ID${NC}"
echo -e "${BLUE}Path:${NC} ${CYAN}$SESSION_DIR${NC}"
echo ""

# Helper function to log
log() {
    python3 utils/simple_logger.py log "$1" "$2" "$3"
}

# Start pipeline
log "INFO" "core" "VaultModel IA Orchestrator started"

# Save current session for telemetry server
echo "$SESSION_DIR" > .current_session

# Start telemetry server in background
echo -n "Starting telemetry server... "
TELEMETRY_PORT=8082
python3 telemetry/telemetry_server.py --port $TELEMETRY_PORT > "$SESSION_DIR/telemetry_server.log" 2>&1 &
TELEMETRY_PID=$!
sleep 2  # Give it time to start

# Check if telemetry server started
if kill -0 $TELEMETRY_PID 2>/dev/null; then
    echo -e "${GREEN}✓${NC} (port $TELEMETRY_PORT, PID: $TELEMETRY_PID)"
    log "SUCCESS" "core" "Telemetry server started on port $TELEMETRY_PORT"
else
    echo -e "${YELLOW}!${NC} (failed to start, continuing anyway)"
    log "WARNING" "core" "Telemetry server failed to start"
fi

echo -e "${GREEN}✓${NC} System initialized"
log "SUCCESS" "core" "System initialized"

echo ""
echo -e "${YELLOW}Executing pipeline...${NC}"
echo ""

# Phase 1: System Diagnostic (diagnose.sh)
echo -e "${BLUE}Phase 1:${NC} System diagnostic"
log "INFO" "core" "Executing Phase 1 - diagnose.sh"
echo ""

# Run real diagnostic script
cd src
./diagnose.sh
DIAG_EXIT_CODE=$?
cd ..

if [ $DIAG_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "${RED}Pipeline aborted due to system requirements${NC}"
    log "ERROR" "core" "Pipeline aborted - system not ready"
    python3 utils/simple_logger.py summary
    exit 1
fi

echo ""

# Phase 2: Model Inference (run_inference.sh)
echo -e "${BLUE}Phase 2:${NC} Model inference"
log "INFO" "core" "Executing Phase 2 - run_inference.sh"
echo ""

# Run real inference script
cd src
./run_inference.sh
INFERENCE_EXIT_CODE=$?
cd ..

if [ $INFERENCE_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "${RED}Inference failed${NC}"
    log "ERROR" "core" "Pipeline failed during inference"
    python3 utils/simple_logger.py summary
    exit 1
fi

echo ""

# Bonus: GPU Health Monitoring
echo -e "${BLUE}Bonus:${NC} GPU Health Monitoring"
log "INFO" "gpu_monitor" "Checking GPU health status"
GPU_HEALTH=$(TELEMETRY_PORT=$TELEMETRY_PORT python3 utils/gpu_monitor.py 2>/dev/null)
if [ -n "$GPU_HEALTH" ]; then
    echo "$GPU_HEALTH" > "$SESSION_DIR/gpu_health.json"
    # Parse and display key metrics
    GPU_TEMP=$(echo "$GPU_HEALTH" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['gpu']['temperature_celsius'])" 2>/dev/null || echo "N/A")
    GPU_MEM=$(echo "$GPU_HEALTH" | python3 -c "import json,sys; data=json.load(sys.stdin); print(round(data['health_checks']['memory_usage_percent'], 2))" 2>/dev/null || echo "N/A")
    GPU_STATUS=$(echo "$GPU_HEALTH" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['status'])" 2>/dev/null || echo "unknown")
    
    echo -e "  ${GREEN}✓${NC} GPU Temperature: ${GPU_TEMP}°C"
    echo -e "  ${GREEN}✓${NC} GPU Memory Usage: ${GPU_MEM}%"
    echo -e "  ${GREEN}✓${NC} GPU Status: ${GPU_STATUS}"
    log "SUCCESS" "gpu_monitor" "GPU health check completed - status: $GPU_STATUS"
else
    echo -e "  ${YELLOW}!${NC} GPU monitoring not available"
    log "WARNING" "gpu_monitor" "GPU monitoring not available"
fi

echo ""
echo -e "${GREEN}Pipeline complete!${NC}"
log "INFO" "core" "Pipeline finished successfully"

# Send telemetry about pipeline completion
if kill -0 $TELEMETRY_PID 2>/dev/null; then
    curl -s -X POST http://localhost:$TELEMETRY_PORT/telemetry \
        -H "Content-Type: application/json" \
        -d "{\"level\": \"SUCCESS\", \"component\": \"pipeline\", \"message\": \"Pipeline completed successfully\"}" \
        > /dev/null 2>&1
fi

# Show summary
python3 utils/simple_logger.py summary

# Stop telemetry server
if [ -n "$TELEMETRY_PID" ] && kill -0 $TELEMETRY_PID 2>/dev/null; then
    echo ""
    echo -n "Stopping telemetry server... "
    kill $TELEMETRY_PID 2>/dev/null
    echo -e "${GREEN}✓${NC}"
    log "INFO" "core" "Telemetry server stopped"
fi

# Clean up session marker
rm -f .current_session