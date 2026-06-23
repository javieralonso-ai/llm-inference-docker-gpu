# Evidence Samples

This directory contains public, sanitized evidence from a local run of the extended ModelVault system.

Raw logs are not committed because they can include local paths, machine-specific details, and other environment noise. These samples preserve the technical signal while removing private context.

| File | Purpose |
|---|---|
| `execution.sample.jsonl` | Main pipeline event sequence |
| `gpu_health.sample.json` | GPU health snapshot from `nvidia-smi` |
| `telemetry.sample.jsonl` | HTTP telemetry events received during the run |
| `system_report.sample.md` | Human-readable diagnostics summary |
| `pipeline-run.svg` | Clean visual snapshot of the successful pipeline |
| `telemetry-summary.svg` | Clean visual snapshot of telemetry/log evidence |

The evidence demonstrates a functional local prototype. It should not be read as proof of enterprise production readiness.
