#!/bin/bash
# Start a persistent Ollama container for chat

CONTAINER_NAME="vaultmodel_ollama_chat"

# Check if container already exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "Ollama chat container is already running"
    else
        echo "Starting existing Ollama chat container..."
        docker start "$CONTAINER_NAME"
    fi
else
    echo "Creating new Ollama chat container..."
    docker run -d \
        --name "$CONTAINER_NAME" \
        --gpus all \
        -p 11434:11434 \
        -v ollama:/root/.ollama \
        ollama/ollama:latest
    
    # Wait for container to be ready
    echo "Waiting for Ollama to start..."
    sleep 5
    
    # Get model from config.json if exists
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_FILE="$(dirname "$SCRIPT_DIR")/config.json"
    
    if [ -f "$CONFIG_FILE" ]; then
        MODEL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['model']['name'])" 2>/dev/null || echo "tinyllama")
    else
        MODEL="tinyllama"
    fi
    
    # Pull the model
    echo "Loading $MODEL model..."
    docker exec "$CONTAINER_NAME" ollama pull $MODEL
fi

# Test connection
echo "Testing connection..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✓ Ollama is ready for chat!"
else
    echo "✗ Failed to connect to Ollama"
    exit 1
fi