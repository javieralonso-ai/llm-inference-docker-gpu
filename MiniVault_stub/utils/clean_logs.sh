#!/bin/bash

# Clean logs utility
# Purpose: Remove all session logs
# Author: Javier Alonso

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Clean logs
echo "Cleaning session logs..."
rm -rf ../logs/sessions/*
rm -f ../.current_session

echo -e "${GREEN}✓${NC} Logs cleaned"