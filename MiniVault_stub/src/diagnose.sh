#!/bin/bash

# ModelVault System Diagnostic Script
# Purpose: Check system requirements for AI model deployment
# Phase: 1 - System Diagnostic
# Author: Javier Alonso
#
# Note: This is a simulation for demonstration purposes.
# In production, this would include real hardware validation
# and stricter requirement checks.

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

# Helper to write to report log
report() {
    echo -e "$1" >> "$REPORT_LOG"
}

echo -e "${BLUE}Running system diagnostics...${NC}"
log "INFO" "phase1_diagnose" "Starting comprehensive system check"

# Create system report log in session directory if available, otherwise local
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
echo -e "\n## OS Information" >> "$REPORT_LOG"
if command -v lsb_release &> /dev/null; then
    OS_VERSION=$(lsb_release -ds 2>/dev/null)
    OS_CODENAME=$(lsb_release -cs 2>/dev/null)
    echo -e "${GREEN}✓${NC}"
    echo -e "  └─ ${OS_VERSION}"
    echo "OS Version: $OS_VERSION" >> "$REPORT_LOG"
    echo "Codename: $OS_CODENAME" >> "$REPORT_LOG"
    log "SUCCESS" "phase1_diagnose" "OS detected: $OS_VERSION"
else
    echo -e "${YELLOW}!${NC}"
    echo -e "  └─ Unable to detect OS version"
    echo "OS Version: Unable to detect" >> "$REPORT_LOG"
    log "WARNING" "phase1_diagnose" "Could not detect OS version"
fi

# 2. Docker Check (Simulated for demo)
echo -n "Checking Docker installation... "
report "\n## Docker Information"
# For demo purposes, we simulate Docker as available but not needed
echo -e "${GREEN}✓${NC}"
echo -e "  └─ Docker version: 24.0.7 (simulated)"
report "Docker Version: 24.0.7 (simulated)"
log "SUCCESS" "phase1_diagnose" "Docker installed: version 24.0.7 (simulated)"

# Check if Docker daemon is running
echo -n "Checking Docker daemon... "
echo -e "${YELLOW}!${NC}"
echo -e "  └─ Docker available but using simulation mode"
report "Docker Status: Available but using simulation mode for demo"
log "INFO" "phase1_diagnose" "Docker available but demo uses simulation"

# 3. NVIDIA GPU Detection
echo -n "Checking for NVIDIA GPU... "
report "\n## GPU Information"
if command -v nvidia-smi &> /dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    if [ -n "$GPU_INFO" ]; then
        echo -e "${GREEN}✓${NC}"
        echo -e "  └─ GPU detected: $GPU_INFO"
        report "GPU Model: $GPU_INFO"
        log "SUCCESS" "phase1_diagnose" "GPU found: $GPU_INFO"
        
        # Get GPU memory
        GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
        echo -e "  └─ GPU memory: $GPU_MEMORY"
        report "GPU Memory: $GPU_MEMORY"
        
        # Get GPU temperature
        GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1)
        echo -e "  └─ GPU temperature: ${GPU_TEMP}°C"
        report "GPU Temperature: ${GPU_TEMP}°C"
    else
        echo -e "${YELLOW}!${NC}"
        echo -e "  └─ NVIDIA driver installed but no GPU detected"
        log "WARNING" "phase1_diagnose" "NVIDIA driver present but no GPU found"
    fi
else
    echo -e "${YELLOW}!${NC}"
    echo -e "  └─ No NVIDIA GPU detected (CPU-only mode)"
    report "GPU: Not detected (CPU-only mode)"
    log "WARNING" "phase1_diagnose" "No GPU - will run in CPU mode"
fi

# 4. Python Check
echo -n "Checking Python installation... "
report "\n## Python Information"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC}"
    echo -e "  └─ Python $PYTHON_VERSION"
    report "Python Version: $PYTHON_VERSION"
    log "SUCCESS" "phase1_diagnose" "Python installed: $PYTHON_VERSION"
else
    echo -e "${RED}✗${NC}"
    echo -e "  └─ Python 3 is not installed"
    report "Python: Not installed"
    log "ERROR" "phase1_diagnose" "Python 3 not found"
    EXIT_CODE=1
fi

# 5. System Resources
echo "Checking system resources..."
report "\n## System Resources"

# RAM
TOTAL_RAM=$(free -h | grep "^Mem:" | awk '{print $2}')
AVAILABLE_RAM=$(free -h | grep "^Mem:" | awk '{print $7}')
echo -e "  • RAM: ${AVAILABLE_RAM} available of ${TOTAL_RAM} total"
report "RAM: ${AVAILABLE_RAM} available of ${TOTAL_RAM} total"
log "INFO" "phase1_diagnose" "RAM: $AVAILABLE_RAM/$TOTAL_RAM available"

# CPU
CPU_MODEL=$(lscpu | grep "Model name:" | cut -d':' -f2 | xargs)
CPU_CORES=$(nproc)
echo -e "  • CPU: ${CPU_CORES} cores (${CPU_MODEL})"
report "CPU: ${CPU_MODEL} (${CPU_CORES} cores)"
log "INFO" "phase1_diagnose" "CPU: $CPU_MODEL with $CPU_CORES cores"

# Disk
DISK_AVAILABLE=$(df -h . | tail -1 | awk '{print $4}')
echo -e "  • Disk: ${DISK_AVAILABLE} available"
report "Disk Space: ${DISK_AVAILABLE} available"
log "INFO" "phase1_diagnose" "Disk space available: $DISK_AVAILABLE"

# 6. Summary
echo ""

# Write final summary to report
report "\n## Summary"
report "=================="
report "Diagnostic completed at: $(date)"

# For demo purposes, always succeed if we have basic requirements
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓ System ready for ModelVault deployment${NC}"
    echo -e "${YELLOW}  Note: Some components missing but continuing for demo${NC}"
    report "Status: READY (Demo Mode)"
    report "Exit Code: 0"
    log "SUCCESS" "phase1_diagnose" "System checks passed (demo mode)"
    EXIT_CODE=0
else
    echo -e "${RED}✗ System not ready - Python 3 is required${NC}"
    report "Status: NOT READY"
    report "Exit Code: 1"
    log "ERROR" "phase1_diagnose" "System checks failed - missing Python"
    EXIT_CODE=1
fi

# Final report location
echo ""
if [ -n "$SESSION_DIR" ]; then
    echo -e "${BLUE}Report saved to session: $(basename $REPORT_LOG)${NC}"
else
    echo -e "${BLUE}Report saved to: $REPORT_LOG${NC}"
fi

exit $EXIT_CODE