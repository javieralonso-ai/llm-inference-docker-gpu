#!/bin/bash

# ModelVault Container Entrypoint
# Purpose: Start Ollama service and run inference
# Author: Javier Alonso

echo "🚀 ModelVault Real Inference Engine starting..."

# Check if Ollama is already running on host
echo "🔍 Checking for Ollama service..."
if curl -s http://host.docker.internal:11434/api/tags >/dev/null 2>&1; then
    echo "✅ Using existing Ollama service on host"
    export OLLAMA_HOST="http://host.docker.internal:11434"
else
    # Start Ollama service in background
    echo "📦 Starting Ollama service..."
    ollama serve &
    OLLAMA_PID=$!
    
    # Wait for Ollama to be ready
    echo "⏳ Waiting for Ollama service to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            echo "✅ Ollama service is ready!"
            break
        fi
        echo "  Attempt $i/30..."
        sleep 2
    done
    
    # Check if Ollama is running
    if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo "❌ Failed to start Ollama service"
        exit 1
    fi
    export OLLAMA_HOST="http://localhost:11434"
fi

# Pull the model if not available
echo "🤖 Checking for model: $MODEL_NAME"
if ! ollama list | grep -q "$MODEL_NAME"; then
    echo "📥 Downloading $MODEL_NAME model (this may take a few minutes)..."
    ollama pull $MODEL_NAME
    if [ $? -ne 0 ]; then
        echo "❌ Failed to download model"
        exit 1
    fi
    echo "✅ Model downloaded successfully!"
else
    echo "✅ Model $MODEL_NAME already available"
fi

# Run the inference engine
echo "🧠 Starting inference engine..."
python3 /app/inference_engine.py

# Keep container alive if inference fails (for debugging)
INFERENCE_EXIT=$?
if [ $INFERENCE_EXIT -ne 0 ]; then
    echo "⚠️  Inference failed with exit code $INFERENCE_EXIT"
    echo "Container will stay alive for debugging. Press Ctrl+C to exit."
    wait $OLLAMA_PID
else
    echo "✅ Inference completed successfully!"
fi

# Cleanup
kill $OLLAMA_PID 2>/dev/null
exit $INFERENCE_EXIT