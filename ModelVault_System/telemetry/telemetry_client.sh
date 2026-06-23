#!/bin/bash

# ModelVault Telemetry Client
# Purpose: Save telemetry data to session directory
# Author: Javier Alonso

# Function to send telemetry
send_telemetry() {
    local level="$1"
    local component="$2"
    local message="$3"
    local details="$4"
    
    # Build JSON payload
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local received_at=$(date -u +"%Y-%m-%dT%H:%M:%S.%6N" | sed 's/......$//')
    local payload=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "level": "$level",
    "component": "$component",
    "message": "$message",
    "received_at": "${received_at}Z"$([ -n "$details" ] && echo ",
    \"details\": $details" || echo "")
}
EOF
)
    
    # Save to session telemetry file if session exists
    if [ -f ".current_session" ]; then
        SESSION_DIR=$(cat .current_session)
        TELEMETRY_FILE="$SESSION_DIR/telemetry.jsonl"
        echo "$payload" >> "$TELEMETRY_FILE"
    else
        # Fallback to logs/telemetry directory
        mkdir -p logs/telemetry
        echo "$payload" >> logs/telemetry/telemetry.jsonl
    fi
        
    return $?
}

# If called directly with arguments
if [ $# -ge 3 ]; then
    send_telemetry "$@"
fi