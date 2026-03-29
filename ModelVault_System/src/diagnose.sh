#!/bin/bash

# ModelVault System Diagnostic Script
# Purpose: Check system requirements for AI model deployment
# Phase: 1 - System Diagnostic
# Author: Javier Alonso
#
# This script performs real system validation for ModelVault deployment

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Exit code
EXIT_CODE=0

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

echo -e "${BLUE}Running system diagnostics...${NC}"
log "INFO" "phase1_diagnose" "Starting comprehensive system check"

# Initialize system report log
if [ -n "$SESSION_DIR" ] && [ -d "../$SESSION_DIR" ]; then
    REPORT_LOG="../$SESSION_DIR/system_report.log"
else
    REPORT_LOG="system_report.log"
fi

echo "ModelVault System Diagnostic Report" > "$REPORT_LOG"
echo "Generated: $(date)" >> "$REPORT_LOG"
echo "=================================" >> "$REPORT_LOG"

# 1. OS Version Detection
echo -n "Checking OS version... "
if command -v lsb_release &> /dev/null; then
    OS_VERSION=$(lsb_release -ds 2>/dev/null)
    OS_CODENAME=$(lsb_release -cs 2>/dev/null)
    echo -e "${GREEN}✓${NC}"
    echo -e "  └─ ${OS_VERSION}"
    log "SUCCESS" "phase1_diagnose" "OS detected: $OS_VERSION"
    echo -e "\n## OS Information" >> "$REPORT_LOG"
    echo "OS Version: $OS_VERSION" >> "$REPORT_LOG"
    echo "Codename: $OS_CODENAME" >> "$REPORT_LOG"
else
    echo -e "${YELLOW}!${NC}"
    echo -e "  └─ Unable to detect OS version"
    log "WARNING" "phase1_diagnose" "Could not detect OS version"
fi

# 2. Docker Check
echo -n "Checking Docker installation... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
    echo -e "${GREEN}✓${NC}"
    echo -e "  └─ Docker version: $DOCKER_VERSION"
    log "SUCCESS" "phase1_diagnose" "Docker installed: version $DOCKER_VERSION"
    echo -e "\n## Docker Information" >> "$REPORT_LOG"
    echo "Docker Version: $DOCKER_VERSION" >> "$REPORT_LOG"
    
    # Check if Docker daemon is running
    echo -n "Checking Docker daemon... "
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
        echo -e "  └─ Docker daemon is running"
        log "SUCCESS" "phase1_diagnose" "Docker daemon running"
        echo "Docker Status: Running" >> "$REPORT_LOG"
    else
        echo -e "${RED}✗${NC}"
        echo -e "  └─ Docker daemon is not running"
        log "ERROR" "phase1_diagnose" "Docker daemon not running"
        EXIT_CODE=1  # Docker daemon must be running
    fi
else
    echo -e "${RED}✗${NC}"
    echo -e "  └─ Docker is not installed"
    log "ERROR" "phase1_diagnose" "Docker not installed"
    EXIT_CODE=1
fi

# 3. NVIDIA GPU Detection
echo -n "Checking for NVIDIA GPU... "
if command -v nvidia-smi &> /dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    if [ -n "$GPU_INFO" ]; then
        echo -e "${GREEN}✓${NC}"
        echo -e "  └─ GPU detected: $GPU_INFO"
        log "SUCCESS" "phase1_diagnose" "GPU found: $GPU_INFO"
        
        # Get GPU memory
        GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
        echo -e "  └─ GPU memory: $GPU_MEMORY"
        
        # Get GPU temperature
        GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1)
        echo -e "  └─ GPU temperature: ${GPU_TEMP}°C"
        
        # Get driver version
        DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
        
        echo -e "\n## GPU Information" >> "$REPORT_LOG"
        echo "GPU Model: $GPU_INFO" >> "$REPORT_LOG"
        echo "Driver Version: $DRIVER_VERSION" >> "$REPORT_LOG"
        echo "GPU Memory: $GPU_MEMORY" >> "$REPORT_LOG"
        echo "GPU Temperature: ${GPU_TEMP}°C" >> "$REPORT_LOG"
    else
        echo -e "${YELLOW}!${NC}"
        echo -e "  └─ NVIDIA driver installed but no GPU detected"
        log "WARNING" "phase1_diagnose" "NVIDIA driver present but no GPU found"
    fi
else
    echo -e "${YELLOW}!${NC}"
    echo -e "  └─ No NVIDIA GPU detected (CPU-only mode)"
    log "WARNING" "phase1_diagnose" "No GPU - will run in CPU mode"
fi

# 4. Python Check
echo -n "Checking Python installation... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC}"
    echo -e "  └─ Python $PYTHON_VERSION"
    log "SUCCESS" "phase1_diagnose" "Python installed: $PYTHON_VERSION"
    echo -e "\n## Python Information" >> "$REPORT_LOG"
    echo "Python Version: $PYTHON_VERSION" >> "$REPORT_LOG"
else
    echo -e "${RED}✗${NC}"
    echo -e "  └─ Python 3 is not installed"
    log "ERROR" "phase1_diagnose" "Python 3 not found"
    EXIT_CODE=1
fi

# 5. Ollama Check
echo -n "Checking Ollama availability... "
if command -v ollama &> /dev/null; then
    OLLAMA_VERSION=$(ollama --version 2>&1 | grep -o 'ollama version [0-9.]*' | cut -d' ' -f3)
    echo -e "${GREEN}✓${NC}"
    echo -e "  └─ Ollama version: $OLLAMA_VERSION"
    log "SUCCESS" "phase1_diagnose" "Ollama installed: version $OLLAMA_VERSION"
    
    # Check available models
    echo -n "Checking Ollama models... "
    MODELS=$(ollama list 2>/dev/null | tail -n +2 | wc -l)
    if [ "$MODELS" -gt 0 ]; then
        echo -e "${GREEN}✓${NC}"
        echo -e "  └─ $MODELS model(s) available locally"
        log "INFO" "phase1_diagnose" "Ollama has $MODELS models available"
    else
        echo -e "${YELLOW}!${NC}"
        echo -e "  └─ No models downloaded yet"
        log "WARNING" "phase1_diagnose" "No Ollama models found locally"
    fi
else
    echo -e "${GREEN}✓${NC}"
    echo -e "  └─ Ollama will run in Docker container (expected)"
    log "INFO" "phase1_diagnose" "Ollama not found locally - will use containerized version as designed"
fi

# 6. System Resources
echo "Checking system resources..."

# RAM
TOTAL_RAM=$(free -h | grep "^Mem:" | awk '{print $2}')
AVAILABLE_RAM=$(free -h | grep "^Mem:" | awk '{print $7}')
echo -e "  • RAM: ${AVAILABLE_RAM} available of ${TOTAL_RAM} total"
log "INFO" "phase1_diagnose" "RAM: $AVAILABLE_RAM/$TOTAL_RAM available"

# CPU
CPU_MODEL=$(lscpu | grep "Model name:" | cut -d':' -f2 | xargs)
CPU_CORES=$(nproc)
echo -e "  • CPU: ${CPU_CORES} cores (${CPU_MODEL})"
log "INFO" "phase1_diagnose" "CPU: $CPU_MODEL with $CPU_CORES cores"

# Disk
DISK_AVAILABLE=$(df -h . | tail -1 | awk '{print $4}')
echo -e "  • Disk: ${DISK_AVAILABLE} available"
log "INFO" "phase1_diagnose" "Disk space available: $DISK_AVAILABLE"

# Add final summary to report
echo -e "\n## System Resources" >> "$REPORT_LOG"
echo "RAM: $AVAILABLE_RAM available of $TOTAL_RAM total" >> "$REPORT_LOG"
echo "CPU: $CPU_MODEL with $CPU_CORES cores" >> "$REPORT_LOG"
echo "Disk: $DISK_AVAILABLE available" >> "$REPORT_LOG"

echo -e "\n## Summary" >> "$REPORT_LOG"

# 7. Summary
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ System ready for ModelVault deployment${NC}"
    log "SUCCESS" "phase1_diagnose" "All system checks passed"
    echo "Status: READY - All checks passed" >> "$REPORT_LOG"
else
    echo -e "${RED}✗ System not ready for ModelVault deployment${NC}"
    echo -e "${YELLOW}  Please install missing components:${NC}"
    
    # Check what's missing
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}  - Docker: curl -fsSL https://get.docker.com | sh${NC}"
    fi
    if ! docker info &> /dev/null 2>&1; then
        echo -e "${YELLOW}  - Start Docker daemon: sudo systemctl start docker${NC}"
    fi
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}  - Python 3: sudo apt install python3${NC}"
    fi
    
    log "ERROR" "phase1_diagnose" "System checks failed - missing requirements"
fi

exit $EXIT_CODE