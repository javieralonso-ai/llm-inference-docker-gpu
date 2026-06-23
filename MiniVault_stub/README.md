# 🚀 MiniVault - ModelVault Bootstrap System (Assessment Implementation)

A complete implementation of ModelVault's technical assessment requirements for an on-premise AI appliance bootstrap system. This project demonstrates system diagnostics, containerized inference simulation, structured logging, and all three bonus features - GPU monitoring, systemd service, and HTTP telemetry.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    vaultmodel_core.sh                       │
│                  (Main Orchestrator)                        │
└─────────────┬──────────────────────┬──────────────────────┘
              │                      │
    ┌─────────▼────────┐   ┌──────────▼────────┐   ┌──────────────┐
    │  diagnose.sh     │   │run_inference_stub │   │ gpu_monitor  │
    │ (System Check)   │   │ (AI Simulation)   │   │ (Health)     │
    └─────────┬────────┘   └──────────┬────────┘   └──────┬───────┘
              │                      │                     │
    ┌─────────▼──────────────────────▼─────────────────────▼──────┐
    │                     simple_logger.py                         │
    │              (Unified Logging & Telemetry)                  │
    └──────────────────────────┬───────────────────────────────────┘
                               │
                     ┌─────────▼──────────┐
                     │ telemetry_server   │
                     │  (HTTP Endpoint)   │
                     └────────────────────┘
```

### Design Principles
- **Modular Components**: Each script handles a specific responsibility
- **Graceful Degradation**: Works without Docker/GPU but leverages them when available
- **Comprehensive Logging**: Every operation is tracked in structured JSONL format
- **Operations-oriented**: Includes a systemd service draft, telemetry, and monitoring

## 🚀 Quick Start

```bash
# Navigate to the project directory
cd MiniVault_stub

# Run the complete pipeline
./vaultmodel_core.sh

# View the generated logs
ls -la logs/sessions/

# Check the simulated output
cat data/output.json
```

## 📁 Project Structure

```
MiniVault_stub/
├── vaultmodel_core.sh          # Main orchestrator
├── src/                        # Core functionality scripts
│   ├── diagnose.sh            # Phase 1: System diagnostics (real)
│   └── run_inference_stub.sh  # Phase 2: AI inference simulation (stub)
├── docker/                     # Container configurations
│   ├── Dockerfile             # Model container definition
│   ├── inference_engine.py    # Container inference logic
│   └── build_and_run.sh       # Docker operations script
├── utils/                      # Support utilities
│   ├── simple_logger.py       # Unified logging system
│   ├── gpu_monitor.py         # GPU health monitoring
│   └── clean_logs.sh          # Log cleanup utility
├── data/                       # Input/Output files
│   ├── input.json             # Model input (auto-generated)
│   └── output.json            # Model response
└── logs/sessions/              # Session-based logging
    └── vaultmodel_TIMESTAMP/   # Individual session logs
        ├── execution.jsonl     # Structured event logs
        ├── gpu_health.json     # GPU status snapshot
        └── session_info.json   # Session metadata
```

## ✅ Assessment Requirements Fulfilled

### Core Requirements (4/4)
1. **System Diagnostic Script** (`diagnose.sh`) ✓
   - Detects OS, NVIDIA drivers, GPU presence
   - Creates `system_report.log` with all findings
   - Proper exit codes and error handling
   - Gracefully handles missing components

2. **Container Setup** (`run_inference_stub.sh`) ✓
   - Dockerfile included for model container
   - Simulates inference as requested
   - Reads `input.json` and writes `output.json`
   - Error handling for missing files

3. **Structured Logging** ✓
   - All logs in JSONL format
   - ISO timestamps, levels, components, messages
   - Mock inference events included
   - Session-based organization

4. **Documentation** ✓
   - Clear Ubuntu 22.04 setup instructions
   - Design decisions explained
   - Production expansion roadmap included

### Bonus Features (3/3) 
1. **GPU Health Monitoring** ✓ - Real-time JSON output
2. **Service Management** ✓ - systemd configuration draft
3. **Mock Telemetry** ✓ - HTTP server with POST endpoint

## 🔄 Execution Flow

### Phase-Based Approach

The system executes in distinct phases, allowing for incremental validation:

1. **Initialization Phase**
   - Creates unique session with timestamp
   - Sets up logging infrastructure
   - Displays session information

2. **Phase 1: System Diagnostics** (`diagnose.sh`)
   - Detects OS version and compatibility
   - Checks Docker installation status
   - Validates GPU presence and drivers
   - Verifies Python environment
   - Assesses system resources (CPU, RAM, Disk)
   - **Fail-fast**: Aborts if critical requirements missing

3. **Phase 2: Model Inference** (`run_inference.sh`)
   - Creates/validates input.json
   - Simulates model loading (7B parameters)
   - Processes inference with progress tracking
   - Generates realistic output.json
   - Calculates token usage and timing

4. **Bonus: GPU Health Monitoring** (`gpu_monitor.py`)
   - Real-time GPU temperature reading
   - Memory usage calculation
   - Power draw monitoring
   - Health status determination
   - JSON report generation

## 📊 Logging System

### Structured Logging (JSONL Format)

Every operation is logged with structured data:

```json
{"timestamp": "2025-07-23T17:47:08.123456+00:00", "level": "INFO", "component": "core", "message": "VaultModel IA Orchestrator started"}
{"timestamp": "2025-07-23T17:47:09.234567+00:00", "level": "SUCCESS", "component": "phase1_diagnose", "message": "System ready"}
```

**Log Levels**: INFO, SUCCESS, WARNING, ERROR

**Components**: core, phase1_diagnose, phase2_inference, gpu_monitor

### Session Management

Each execution creates a unique session directory with:
- Complete operation logs
- GPU health snapshots
- Session metadata
- All outputs preserved for debugging

## 🛠️ Key Features

### 1. **Modular Design**
- Each component can be tested independently
- Clear separation of concerns
- Easy to extend with new phases

### 2. **Real System Detection**
- Actual GPU detection (not simulated)
- Real system resource monitoring
- Genuine Python/OS version checking

### 3. **Professional Error Handling**
- Graceful degradation for missing components
- Clear error messages
- Proper exit codes

### 4. **GPU Health Monitoring** (Bonus Feature)
- Temperature monitoring with thresholds
- Memory usage tracking
- Power consumption reporting
- Health status determination (healthy/warning/critical)

### 5. **Semaphore Lock System**
- Prevents concurrent model executions
- Protects GPU resources from conflicts
- Automatic stale lock detection
- Timeout protection (5 minutes default)
- Clean release on interruption (SIGINT/SIGTERM)

## 🌟 Implemented Bonus Features

### ✅ 1. GPU Health Monitoring
Real-time GPU monitoring with comprehensive metrics:
```json
{
  "status": "healthy",
  "gpu": {
    "name": "NVIDIA GeForce RTX 4060 Ti",
    "temperature_celsius": 48,
    "memory_used_mb": 1533,
    "utilization_percent": 26
  }
}
```

### ✅ 2. Systemd Service Management
Service configuration draft:
```bash
# Install as system service
sudo ./systemd/install_service.sh

# Service management
sudo systemctl start modelvault
sudo systemctl status modelvault
sudo journalctl -u modelvault -f
```

### ✅ 3. HTTP Telemetry Server
Complete telemetry collection system:
```bash
# Start telemetry server
./telemetry/telemetry_server.py --port 8080

# Endpoints available:
curl http://localhost:8080/health
curl http://localhost:8080/metrics
curl -X POST http://localhost:8080/telemetry -d '{"level":"INFO","message":"test"}'
```

## 📈 Sample Outputs

### GPU Health Report
```json
{
  "timestamp": "2025-07-23T17:47:14.003461Z",
  "status": "healthy",
  "gpu": {
    "name": "NVIDIA GeForce RTX 4060 Ti",
    "temperature_celsius": 51,
    "memory_used_mb": 2701,
    "memory_total_mb": 8188,
    "utilization_percent": 4
  },
  "health_checks": {
    "temperature": "normal",
    "memory": "normal",
    "memory_usage_percent": 32.99
  }
}
```

### Model Output
```json
{
  "model": "vaultmodel-llama-7b",
  "response": "ModelVault is a local on-premise AI prototype...",
  "usage": {
    "prompt_tokens": 12,
    "completion_tokens": 147,
    "total_tokens": 159
  },
  "metadata": {
    "processing_time_ms": 1944,
    "inference_mode": "simulated"
  }
}
```

## 🔧 Customization

### Adding New Phases

1. Create new script in `src/`
2. Add execution block in `vaultmodel_core.sh`
3. Implement logging using the helper function
4. Handle errors appropriately

### Extending GPU Monitoring

The GPU monitor can be extended to track:
- Multiple GPUs
- Historical data
- Alert thresholds
- Performance trends

## 🎯 Design Decisions & Technical Rationale

### 1. **Hybrid Bash/Python Architecture**
- **Bash** for system-level operations and orchestration (natural fit for Linux environments)
- **Python** for complex data processing, HTTP servers, and GPU monitoring
- This resembles common Linux startup patterns where shell scripts handle deployment/startup

### 2. **Container Simulation Approach**
- Simulates container execution as requested in the assessment
- Includes real Dockerfile for reference
- Demonstrates understanding of containerization concepts
- Works without Docker daemon requirements

### 3. **Session-Based Isolation**
- Each execution creates a unique session directory
- Complete audit trail for debugging and compliance
- No log file conflicts in concurrent executions

### 4. **JSONL Logging Format**
- Industry-standard structured logging
- Easy to parse and aggregate
- Compatible with log management systems (ELK, Splunk)

### 5. **Real GPU Monitoring**
- Actual nvidia-smi integration, not mocked
- Demonstrates ability to work with hardware APIs
- Critical for AI workload management

### 6. **Telemetry as a Separate Service**
- Decoupled architecture for scalability
- HTTP API allows integration with any monitoring stack
- Optional component that doesn't break core functionality

## 🔮 Production Roadmap

If this were to evolve into a production system:

1. **Model Management**
   - Integration with Ollama/vLLM for real inference
   - Model versioning and A/B testing
   - Fine-tuning pipeline integration

2. **Scalability**
   - Kubernetes operators for container orchestration
   - Multi-GPU support with load balancing
   - Distributed inference across nodes

3. **Security Hardening**
   - mTLS for all communications
   - Secrets management (HashiCorp Vault)
   - RBAC for multi-tenant deployments

4. **Observability**
   - Prometheus metrics export
   - Distributed tracing (OpenTelemetry)
   - Advanced GPU utilization analytics

5. **Enterprise Features**
   - High availability with failover
   - Backup and disaster recovery
   - Compliance reporting (SOC2, HIPAA)

## 📋 Requirements

- Ubuntu 22.04+ (tested on 24.04)
- Python 3.x
- NVIDIA GPU + drivers (optional, for GPU monitoring)
- Docker (optional, system works without it)

## 🚦 Exit Codes

- `0`: Success
- `1`: System requirements not met
- `2`: Inference failed

## 📊 Script Summary

| Script | Purpose | Phase | Key Features |
|--------|---------|-------|--------------|
| `vaultmodel_core.sh` | Main orchestrator | All | Coordinates all phases, manages session logging |
| `diagnose.sh` | System diagnostics | Phase 1 | Checks OS, Docker, GPU, Python, resources |
| `run_inference.sh` | AI model inference | Phase 2 | Simulates model loading and inference |
| `simple_logger.py` | Logging system | All | Creates JSONL logs with session management |
| `gpu_monitor.py` | GPU health check | Bonus | Real-time GPU temperature, memory, status |
| `clean_logs.sh` | Log cleanup | Utility | Removes old session logs |
| `semaphore_manager.sh` | Lock management | Phase 2 | Prevents concurrent model executions |
| `build_and_run.sh` | Docker operations | Phase 2 | Builds and runs inference container |
| `inference_engine.py` | Container logic | Phase 2 | Simulates AI model processing |

## 💡 Technical Context

This implementation draws from real-world experience with:
- **Ollama**: Local LLM deployment and management
- **Docker**: Containerized inference workloads  
- **NVIDIA Stack**: GPU monitoring and optimization
- **Structured Logging**: JSONL logs for review and troubleshooting
- **Service Management**: systemd service design for reliable daemon operations

The architecture reflects best practices from deploying AI systems at scale while maintaining the flexibility needed for on-premise environments.

## 👤 Author

**Javier Alonso** - AI Systems Designer

*Built with an AI-native approach using Cursor and Claude Code to demonstrate modern development practices while delivering reviewable infrastructure code.*
