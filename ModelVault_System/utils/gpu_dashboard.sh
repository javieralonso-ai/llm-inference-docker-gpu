#!/bin/bash
# GPU Real-time Dashboard for ModelVault
# Shows live GPU metrics in a beautiful terminal interface

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Function to draw a progress bar
progress_bar() {
    local percent=$1
    local width=30
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]"
}

# Function to get color based on value
get_color() {
    local value=$1
    local warning=$2
    local critical=$3
    
    if [ "$value" -lt "$warning" ]; then
        echo "$GREEN"
    elif [ "$value" -lt "$critical" ]; then
        echo "$YELLOW"
    else
        echo "$RED"
    fi
}

# Main dashboard loop
clear
echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${PURPLE}║          ModelVault GPU Dashboard v1.0                 ║${NC}"
echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Press Ctrl+C to exit"
echo ""

while true; do
    # Get GPU info
    if command -v nvidia-smi &> /dev/null; then
        # Parse nvidia-smi output
        GPU_INFO=$(nvidia-smi --query-gpu=name,temperature.gpu,memory.used,memory.total,utilization.gpu,power.draw,power.limit --format=csv,noheader,nounits 2>/dev/null)
        
        if [ -n "$GPU_INFO" ]; then
            IFS=',' read -r GPU_NAME TEMP MEM_USED MEM_TOTAL GPU_UTIL POWER_DRAW POWER_LIMIT <<< "$GPU_INFO"
            
            # Clean up values
            GPU_NAME=$(echo "$GPU_NAME" | xargs)
            TEMP=${TEMP:-0}
            MEM_USED=${MEM_USED:-0}
            MEM_TOTAL=${MEM_TOTAL:-1}
            GPU_UTIL=${GPU_UTIL:-0}
            POWER_DRAW=${POWER_DRAW:-0}
            POWER_LIMIT=${POWER_LIMIT:-1}
            
            # Calculate percentages
            MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
            POWER_PERCENT=$((${POWER_DRAW%.*} * 100 / ${POWER_LIMIT%.*}))
            
            # Clear previous output
            tput cup 7 0
            
            # Display GPU info
            echo -e "${BOLD}${CYAN}GPU:${NC} $GPU_NAME"
            echo ""
            
            # Temperature
            TEMP_COLOR=$(get_color $TEMP 70 85)
            echo -e "${BOLD}Temperature:${NC} ${TEMP_COLOR}${TEMP}°C${NC}"
            echo -n "  "
            progress_bar $((TEMP * 100 / 100))
            echo ""
            echo ""
            
            # Memory Usage
            MEM_COLOR=$(get_color $MEM_PERCENT 80 95)
            echo -e "${BOLD}Memory:${NC} ${MEM_COLOR}${MEM_USED}/${MEM_TOTAL} MB (${MEM_PERCENT}%)${NC}"
            echo -n "  "
            progress_bar $MEM_PERCENT
            echo ""
            echo ""
            
            # GPU Utilization
            UTIL_COLOR=$(get_color $GPU_UTIL 70 90)
            echo -e "${BOLD}GPU Load:${NC} ${UTIL_COLOR}${GPU_UTIL}%${NC}"
            echo -n "  "
            progress_bar $GPU_UTIL
            echo ""
            echo ""
            
            # Power Usage
            echo -e "${BOLD}Power:${NC} ${POWER_DRAW}W / ${POWER_LIMIT}W"
            echo -n "  "
            progress_bar $POWER_PERCENT
            echo ""
            echo ""
            
            # Timestamp
            echo -e "${BOLD}Last Update:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
            
            # Status summary
            echo ""
            if [ $TEMP -gt 85 ] || [ $MEM_PERCENT -gt 95 ]; then
                echo -e "${RED}${BOLD}⚠ WARNING: Critical values detected!${NC}"
            elif [ $TEMP -gt 70 ] || [ $MEM_PERCENT -gt 80 ]; then
                echo -e "${YELLOW}${BOLD}⚡ Performance may be impacted${NC}"
            else
                echo -e "${GREEN}${BOLD}✓ All systems operational${NC}"
            fi
            
        else
            tput cup 7 0
            echo -e "${RED}Unable to read GPU information${NC}"
        fi
    else
        tput cup 7 0
        echo -e "${YELLOW}No NVIDIA GPU detected${NC}"
    fi
    
    sleep 1
done