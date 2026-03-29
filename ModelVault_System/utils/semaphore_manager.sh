#!/bin/bash

# ModelVault Semaphore Manager
# Purpose: Prevent concurrent model executions to protect GPU resources
# Author: Javier Alonso
#
# Uses file-based locking that works across containers through volume mounting

# Configuration
LOCK_DIR="/tmp/modelvault_locks"
LOCK_FILE="$LOCK_DIR/model_inference.lock"
TIMEOUT=300  # 5 minutes max wait

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure lock directory exists
mkdir -p "$LOCK_DIR"

# Function to acquire lock
acquire_lock() {
    local pid=$$
    local start_time=$(date +%s)
    
    echo -e "${BLUE}[Semaphore]${NC} Attempting to acquire inference lock..."
    
    while true; do
        # Try to create lock file atomically
        if (set -C; echo "$pid" > "$LOCK_FILE") 2>/dev/null; then
            echo -e "${GREEN}[Semaphore]${NC} Lock acquired (PID: $pid)"
            return 0
        fi
        
        # Check if existing lock is stale
        if [ -f "$LOCK_FILE" ]; then
            local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
            if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
                echo -e "${YELLOW}[Semaphore]${NC} Removing stale lock from PID $lock_pid"
                rm -f "$LOCK_FILE"
                continue
            fi
        fi
        
        # Check timeout
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -ge $TIMEOUT ]; then
            echo -e "${RED}[Semaphore]${NC} Timeout waiting for lock after ${TIMEOUT}s"
            return 1
        fi
        
        echo -e "${YELLOW}[Semaphore]${NC} Waiting for lock... ($elapsed/${TIMEOUT}s)"
        sleep 2
    done
}

# Function to release lock
release_lock() {
    local pid=$$
    
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ "$lock_pid" = "$pid" ]; then
            rm -f "$LOCK_FILE"
            echo -e "${GREEN}[Semaphore]${NC} Lock released (PID: $pid)"
            return 0
        else
            echo -e "${YELLOW}[Semaphore]${NC} Lock owned by different process ($lock_pid)"
            return 1
        fi
    else
        echo -e "${YELLOW}[Semaphore]${NC} No lock to release"
        return 1
    fi
}

# Function to check lock status
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if kill -0 "$lock_pid" 2>/dev/null; then
            echo -e "${YELLOW}[Semaphore]${NC} Lock held by PID $lock_pid"
            return 0
        else
            echo -e "${YELLOW}[Semaphore]${NC} Stale lock found (PID $lock_pid no longer exists)"
            return 1
        fi
    else
        echo -e "${GREEN}[Semaphore]${NC} No active lock"
        return 2
    fi
}

# Function to force unlock (admin use only)
force_unlock() {
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        echo -e "${YELLOW}[Semaphore]${NC} Lock forcefully removed"
    else
        echo -e "${GREEN}[Semaphore]${NC} No lock to remove"
    fi
}

# Main execution
case "${1:-}" in
    acquire)
        acquire_lock
        ;;
    release)
        release_lock
        ;;
    check)
        check_lock
        ;;
    force-unlock)
        force_unlock
        ;;
    *)
        echo "Usage: $0 {acquire|release|check|force-unlock}"
        echo ""
        echo "  acquire      - Acquire the inference lock (blocks until available)"
        echo "  release      - Release the inference lock"
        echo "  check        - Check current lock status"
        echo "  force-unlock - Force remove lock (use with caution)"
        exit 1
        ;;
esac