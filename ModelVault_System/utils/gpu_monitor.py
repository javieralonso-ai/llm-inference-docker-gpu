#!/usr/bin/env python3
"""
GPU Health Monitoring
Purpose: Monitor GPU temperature and memory usage
Author: Javier Alonso
"""

import json
import subprocess
import sys
from datetime import datetime
import os
import requests

def get_gpu_info():
    """Get GPU information using nvidia-smi"""
    try:
        # Check if nvidia-smi is available
        result = subprocess.run(['which', 'nvidia-smi'], capture_output=True)
        if result.returncode != 0:
            return None
        
        # Get GPU info
        gpu_data = {}
        
        # GPU Name
        cmd = ['nvidia-smi', '--query-gpu=name', '--format=csv,noheader,nounits']
        result = subprocess.run(cmd, capture_output=True, text=True)
        gpu_data['name'] = result.stdout.strip() if result.returncode == 0 else "Unknown"
        
        # Temperature
        cmd = ['nvidia-smi', '--query-gpu=temperature.gpu', '--format=csv,noheader,nounits']
        result = subprocess.run(cmd, capture_output=True, text=True)
        gpu_data['temperature_celsius'] = int(result.stdout.strip()) if result.returncode == 0 else 0
        
        # Memory Total
        cmd = ['nvidia-smi', '--query-gpu=memory.total', '--format=csv,noheader,nounits']
        result = subprocess.run(cmd, capture_output=True, text=True)
        gpu_data['memory_total_mb'] = int(result.stdout.strip()) if result.returncode == 0 else 0
        
        # Memory Used
        cmd = ['nvidia-smi', '--query-gpu=memory.used', '--format=csv,noheader,nounits']
        result = subprocess.run(cmd, capture_output=True, text=True)
        gpu_data['memory_used_mb'] = int(result.stdout.strip()) if result.returncode == 0 else 0
        
        # Memory Free
        cmd = ['nvidia-smi', '--query-gpu=memory.free', '--format=csv,noheader,nounits']
        result = subprocess.run(cmd, capture_output=True, text=True)
        gpu_data['memory_free_mb'] = int(result.stdout.strip()) if result.returncode == 0 else 0
        
        # Utilization
        cmd = ['nvidia-smi', '--query-gpu=utilization.gpu', '--format=csv,noheader,nounits']
        result = subprocess.run(cmd, capture_output=True, text=True)
        gpu_data['utilization_percent'] = int(result.stdout.strip()) if result.returncode == 0 else 0
        
        # Power Draw
        cmd = ['nvidia-smi', '--query-gpu=power.draw', '--format=csv,noheader,nounits']
        result = subprocess.run(cmd, capture_output=True, text=True)
        try:
            gpu_data['power_draw_watts'] = float(result.stdout.strip()) if result.returncode == 0 else 0
        except:
            gpu_data['power_draw_watts'] = 0
        
        # Driver Version
        cmd = ['nvidia-smi', '--query-gpu=driver_version', '--format=csv,noheader,nounits']
        result = subprocess.run(cmd, capture_output=True, text=True)
        gpu_data['driver_version'] = result.stdout.strip() if result.returncode == 0 else "Unknown"
        
        # Get CUDA version from nvidia-smi
        result = subprocess.run(['nvidia-smi'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if 'CUDA Version' in line:
                cuda_version = line.split('CUDA Version:')[1].strip().split()[0]
                gpu_data['cuda_version'] = cuda_version
                break
        else:
            gpu_data['cuda_version'] = "Unknown"
        
        return gpu_data
        
    except Exception as e:
        return None

def generate_health_report():
    """Generate GPU health report"""
    report = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "status": "unknown",
        "gpu": None,
        "health_checks": {}
    }
    
    gpu_info = get_gpu_info()
    
    if gpu_info:
        report["gpu"] = gpu_info
        report["status"] = "healthy"
        
        # Health checks
        health_checks = {}
        
        # Temperature check
        temp = gpu_info['temperature_celsius']
        if temp < 80:
            health_checks["temperature"] = "normal"
        elif temp < 85:
            health_checks["temperature"] = "warning"
            report["status"] = "warning"
        else:
            health_checks["temperature"] = "critical"
            report["status"] = "critical"
        
        # Memory check
        memory_usage_percent = (gpu_info['memory_used_mb'] / gpu_info['memory_total_mb'] * 100) if gpu_info['memory_total_mb'] > 0 else 0
        if memory_usage_percent < 85:
            health_checks["memory"] = "normal"
        elif memory_usage_percent < 95:
            health_checks["memory"] = "warning"
            if report["status"] == "healthy":
                report["status"] = "warning"
        else:
            health_checks["memory"] = "critical"
            report["status"] = "critical"
        
        health_checks["memory_usage_percent"] = round(memory_usage_percent, 2)
        report["health_checks"] = health_checks
        
    else:
        # No GPU or nvidia-smi not available
        report["status"] = "no_gpu"
        report["message"] = "No NVIDIA GPU detected or nvidia-smi not available"
    
    return report

def send_telemetry(data):
    """Send GPU health data to telemetry server"""
    try:
        # Check for telemetry port (default 8082)
        telemetry_port = os.environ.get('TELEMETRY_PORT', '8082')
        
        # Prepare telemetry data
        telemetry_data = {
            "level": data.get("status", "INFO").upper(),
            "component": "gpu_monitor",
            "message": f"GPU health check - status: {data.get('status', 'unknown')}",
            "gpu_data": data
        }
        
        # Send to telemetry server
        response = requests.post(
            f"http://localhost:{telemetry_port}/telemetry",
            json=telemetry_data,
            timeout=2
        )
        
        if response.status_code != 200:
            print(f"Warning: Failed to send telemetry (status: {response.status_code})", file=sys.stderr)
    except Exception:
        # Silently fail if telemetry is not available
        pass

def main():
    """Main function"""
    if len(sys.argv) > 1 and sys.argv[1] == "--pretty":
        # Pretty print
        report = generate_health_report()
        send_telemetry(report)  # Send to telemetry server
        print(json.dumps(report, indent=2))
    else:
        # Single line JSON
        report = generate_health_report()
        send_telemetry(report)  # Send to telemetry server
        print(json.dumps(report))

if __name__ == "__main__":
    main()