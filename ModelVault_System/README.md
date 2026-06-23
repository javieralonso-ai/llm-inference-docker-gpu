# ModelVault System - Local LLM Inference Demo

Functional local prototype for running an LLM inference workflow with Docker, Ollama, GPU diagnostics, JSONL logs, telemetry, and an interactive CLI.

This is the extended version of the baseline assignment in `../MiniVault_stub`. It demonstrates a real local inference path, but it is not presented as a production enterprise platform.

## Overview

This demo provides:

- local LLM inference through Ollama;
- Docker-based inference workflow;
- interactive Python CLI;
- system diagnostics for OS, Docker, Python, and NVIDIA GPU;
- session-based JSONL logging;
- GPU health reporting through `nvidia-smi`;
- local HTTP telemetry during the run;
- benchmark and dashboard helper scripts.

## Requirements

- Ubuntu 22.04+ or WSL2 Ubuntu
- Docker running
- Python 3.10+
- Host Python dependencies from the repo root: `python3 -m pip install -r ../requirements.txt`
- NVIDIA GPU and NVIDIA Container Toolkit for GPU acceleration
- Disk space for the selected Ollama model

The demo can document missing components, but real inference requires Docker and a working Ollama path.

## Quickstart

From this directory:

```bash
python3 -m pip install -r ../requirements.txt
find . -name "*.sh" -exec chmod +x {} \;
python3 vaultmodel_cli_basic.py
```

The CLI runs the pipeline first. After a successful run, it opens a menu where you can inspect session logs or start an interactive Ollama chat.

## Project Structure

```text
ModelVault_System/
├── vaultmodel_cli_basic.py
├── vaultmodel_core.sh
├── config.json
├── src/
│   ├── diagnose.sh
│   └── run_inference.sh
├── docker/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── inference_engine.py
├── utils/
│   ├── benchmark_inference.py
│   ├── gpu_dashboard.sh
│   ├── gpu_monitor.py
│   ├── semaphore_manager.sh
│   ├── simple_logger.py
│   └── start_ollama_chat.sh
├── telemetry/
└── systemd/
```

## Configuration

Edit `config.json` to choose the model and generation parameters:

```json
{
  "model": {
    "name": "mistral",
    "options": {
      "temperature": 0.7,
      "top_p": 0.9,
      "num_predict": 250
    }
  }
}
```

## Operational Notes

- Logs are written to `logs/sessions/` and ignored by Git.
- `data/output.json` is generated at runtime and ignored by Git.
- The telemetry server is intended for local demo use.
- The `systemd` unit is a design artifact until tested end-to-end on a target machine.
- The current lock implementation expresses the concurrency intent, but should be replaced with a verified `flock` flow before production use.

## Evidence

Sanitized public samples are stored in `../docs/evidence/`. They show a local run with:

- Ubuntu 24.04.2 LTS;
- Docker 28.3.2;
- NVIDIA GeForce RTX 4060 Ti;
- CUDA 12.9 reported by the driver;
- real Docker workflow with GPU support;
- JSONL execution logs and telemetry events.

## License

MIT. See the repository root.
