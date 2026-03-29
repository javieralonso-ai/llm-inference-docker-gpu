# ModelVault Technical Assessment

## Context

ModelVault asked candidates to build a system bootstrap script for their on-premise AI appliance. The assignment was designed for ~2 hours, with 3 optional bonus features (pick 1).

## What I Delivered

### MiniVault_stub — The Assignment (Complete + All 3 Bonuses)

- System diagnostic script with real GPU detection (nvidia-smi, Docker, CUDA)
- Docker containerization with structured JSONL logging and session management
- **Bonus 1**: GPU health monitoring with JSON output (temperature, memory, utilization)
- **Bonus 2**: systemd service file with security hardening (PrivateTmp, ProtectSystem, resource limits)
- **Bonus 3**: HTTP telemetry server with POST /telemetry, GET /health, GET /metrics

### ModelVault_System — Beyond the Assignment (Initiative)

A fully functional AI inference system with real LLM execution, built to demonstrate hands-on experience with the ModelVault stack:

- Real inference with Mistral 7B via Ollama in Docker
- Interactive CLI with chat interface
- GPU dashboard with live terminal metrics
- Model benchmarking suite (multi-model comparison)
- Semaphore-based concurrency control for GPU access
- Telemetry server with structured logging

## Result

Delivered 3 days before the deadline. Considered for both Software Engineer and Systems Engineer roles simultaneously.

> "I believe you would be a great fit for our team" — Hiring Manager

The process ended at the oral interview stage due to English conversational level, not technical capability.

## Tech Stack

Bash, Python, Docker, Ollama, NVIDIA CUDA, systemd, PostgreSQL concepts, structured JSONL logging

## How to Run

Each project has its own README with setup instructions. Both require Ubuntu 22.04+ and Docker.
