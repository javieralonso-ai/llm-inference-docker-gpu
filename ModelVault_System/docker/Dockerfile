# ModelVault AI Model Container with Real Ollama
# Purpose: Real inference engine for on-premise AI deployment
# Author: Javier Alonso

FROM ubuntu:22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.ai/install.sh | sh

# Set working directory
WORKDIR /app

# Copy application files
COPY inference_engine.py /app/
COPY entrypoint.sh /app/
COPY requirements.txt /app/

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

# Install Python dependencies
RUN pip3 install -r requirements.txt || pip3 install requests

# Create directories for data and logs
RUN mkdir -p /data /logs

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV OLLAMA_HOST=0.0.0.0:11434
ENV MODEL_NAME="tinyllama"

# Volume for input/output and logs
VOLUME ["/data", "/logs"]

# Expose Ollama API port (for debugging)
EXPOSE 11434

# Use entrypoint script to start Ollama and run inference
ENTRYPOINT ["/app/entrypoint.sh"]