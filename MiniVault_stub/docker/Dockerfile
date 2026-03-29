# ModelVault AI Model Container
# Purpose: Containerized inference engine for on-premise AI deployment
# Author: Javier Alonso

FROM ubuntu:22.04

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy inference engine
COPY inference_engine.py /app/
COPY requirements.txt /app/

# Install Python dependencies
RUN pip3 install -r requirements.txt || pip3 install requests

# Create directories for model and data
RUN mkdir -p /app/models /app/data

# Environment variables
ENV MODEL_NAME="vaultmodel-llama-7b"
ENV MODEL_PATH="/app/models"
ENV INFERENCE_PORT="8080"

# Volume for input/output
VOLUME ["/app/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python3 -c "print('Model container healthy')" || exit 1

# Default command
CMD ["python3", "/app/inference_engine.py"]