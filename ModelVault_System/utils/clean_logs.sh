#!/bin/bash

# Clean logs utility
# Purpose: Remove all session logs
# Author: Javier Alonso

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Confirm before cleaning
echo -e "${YELLOW}⚠️  This will delete all session logs${NC}"
echo -n "Are you sure? (y/N): "
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    # Clean logs
    echo "Cleaning session logs..."
    
    # Remove ALL logs directories
    if [ -d "$PROJECT_ROOT/logs" ]; then
        echo "  • Removing session logs..."
        rm -rf "$PROJECT_ROOT/logs/sessions"/*
        
        echo "  • Removing telemetry logs..."
        rm -rf "$PROJECT_ROOT/logs/telemetry"
        
        # Remove any other log directories
        find "$PROJECT_ROOT/logs" -type d -empty -delete 2>/dev/null
        
        echo -e "${GREEN}✓${NC} All log directories cleaned"
    fi
    
    # Remove current session file
    if [ -f "$PROJECT_ROOT/.current_session" ]; then
        rm -f "$PROJECT_ROOT/.current_session"
        echo -e "${GREEN}✓${NC} Current session marker removed"
    fi
    
    # Remove any stale semaphore files
    if [ -f "$PROJECT_ROOT/.inference_lock" ]; then
        rm -f "$PROJECT_ROOT/.inference_lock"
        echo -e "${GREEN}✓${NC} Stale lock files removed"
    fi
    
    echo ""
    echo -e "${GREEN}✓${NC} All logs and temporary files cleaned"
else
    echo -e "${YELLOW}Cancelled${NC}"
fi