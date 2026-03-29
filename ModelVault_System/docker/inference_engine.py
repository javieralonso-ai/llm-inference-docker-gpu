#!/usr/bin/env python3
"""
ModelVault Real Inference Engine
Purpose: Process AI inference requests using Ollama
Author: Javier Alonso
"""

import json
import requests
import sys
import os
from datetime import datetime, timezone

class ModelVaultInference:
    def __init__(self):
        ollama_host = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
        self.ollama_api = f"{ollama_host}/api/generate"
        self.model = os.environ.get("MODEL_NAME", "mistral")
        self.data_dir = "/data"
        self.logs_dir = "/logs"
        
    def log_event(self, level, message, details=None):
        """Log events in JSONL format"""
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": level,
            "component": "inference_engine",
            "message": message
        }
        if details:
            log_entry["details"] = details
            
        # Write to inference log
        log_file = os.path.join(self.logs_dir, "inference.jsonl")
        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry) + "\n")
            
    def process_inference(self):
        """Main inference processing"""
        input_file = os.path.join(self.data_dir, "input.json")
        output_file = os.path.join(self.data_dir, "output.json")
        
        self.log_event("INFO", "Starting inference processing")
        
        # 1. Load input
        try:
            with open(input_file, 'r') as f:
                input_data = json.load(f)
            self.log_event("INFO", "Input loaded successfully", {"file": input_file})
        except FileNotFoundError:
            self.log_event("ERROR", "Input file not found", {"file": input_file})
            return False
        except json.JSONDecodeError as e:
            self.log_event("ERROR", "Invalid JSON in input file", {"error": str(e)})
            return False
            
        # 2. Extract parameters
        prompt = input_data.get("prompt", "Hello, how are you?")
        max_tokens = input_data.get("max_tokens", 150)
        temperature = input_data.get("temperature", 0.7)
        
        self.log_event("INFO", "Processing prompt", {
            "prompt_length": len(prompt),
            "max_tokens": max_tokens,
            "temperature": temperature
        })
        
        # 3. Call Ollama API
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens
            }
        }
        
        try:
            start_time = datetime.now()
            self.log_event("INFO", "Calling Ollama API", {"model": self.model})
            
            response = requests.post(self.ollama_api, json=payload, timeout=60)
            end_time = datetime.now()
            processing_time_ms = int((end_time - start_time).total_seconds() * 1000)
            
            if response.status_code == 200:
                result = response.json()
                
                # 4. Create output
                output_data = {
                    "model": self.model,
                    "prompt": prompt,
                    "response": result.get("response", ""),
                    "usage": {
                        "prompt_tokens": len(prompt.split()),
                        "completion_tokens": len(result.get("response", "").split()),
                        "total_tokens": len(prompt.split()) + len(result.get("response", "").split())
                    },
                    "metadata": {
                        "processing_time_ms": processing_time_ms,
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                        "inference_mode": "real",
                        "temperature": temperature,
                        "max_tokens": max_tokens,
                        "model_info": {
                            "name": self.model,
                            "context_length": result.get("context", 2048),
                            "eval_count": result.get("eval_count", 0),
                            "eval_duration": result.get("eval_duration", 0)
                        },
                        "version": "2.0.0"
                    }
                }
                
                # 5. Save output
                with open(output_file, 'w') as f:
                    json.dump(output_data, f, indent=2)
                    
                self.log_event("SUCCESS", "Inference completed", {
                    "processing_time_ms": processing_time_ms,
                    "tokens_generated": output_data["usage"]["completion_tokens"],
                    "output_file": output_file
                })
                
                print(f"✅ Real inference completed in {processing_time_ms}ms")
                print(f"📊 Generated {output_data['usage']['completion_tokens']} tokens")
                return True
                
            else:
                self.log_event("ERROR", "Ollama API error", {
                    "status_code": response.status_code,
                    "response": response.text
                })
                print(f"❌ API Error: {response.status_code}")
                return False
                
        except requests.exceptions.ConnectionError:
            self.log_event("ERROR", "Cannot connect to Ollama service")
            print("❌ Cannot connect to Ollama. Is the service running?")
            return False
        except requests.exceptions.Timeout:
            self.log_event("ERROR", "Request timeout", {"timeout": 60})
            print("❌ Request timeout - inference took too long")
            return False
        except Exception as e:
            self.log_event("ERROR", "Unexpected error", {"error": str(e)})
            print(f"❌ Unexpected error: {str(e)}")
            return False

def main():
    """Main entry point"""
    print("🚀 ModelVault Real Inference Engine v2.0")
    print(f"📁 Data directory: /data")
    print(f"📝 Logs directory: /logs")
    
    engine = ModelVaultInference()
    success = engine.process_inference()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()