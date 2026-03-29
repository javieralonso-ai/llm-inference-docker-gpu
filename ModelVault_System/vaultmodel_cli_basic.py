#!/usr/bin/env python3
"""
VaultModel CLI Basic
Purpose: Simple CLI that executes vaultmodel_core.sh with filtered output
Author: Javier Alonso
"""

import subprocess
import os
import sys
import json
import glob
import re
import requests
from datetime import datetime

class VaultModelCLI:
    def __init__(self):
        self.logs_dir = "logs/sessions"
        self.pipeline_executed = False  # Track if pipeline has been run
        self.system_context = self._load_system_context()
        self.config = self._load_config()
        
    def _load_system_context(self):
        """Load system context from MODELVAULT.md"""
        try:
            if os.path.exists('MODELVAULT.md'):
                with open('MODELVAULT.md', 'r') as f:
                    return f.read()
            else:
                return "You are a helpful AI assistant running on the VaultModel system."
        except:
            return "You are a helpful AI assistant running on the VaultModel system."
    
    def _load_config(self):
        """Load configuration from config.json"""
        try:
            if os.path.exists('config.json'):
                with open('config.json', 'r') as f:
                    return json.load(f)
            else:
                return {
                    "model": {
                        "name": "tinyllama",
                        "options": {
                            "temperature": 0.7,
                            "top_p": 0.9,
                            "num_predict": 150,
                            "stop": ["\n\n", "User:", "Human:", "Assistant:"]
                        }
                    }
                }
        except:
            return {
                "model": {
                    "name": "tinyllama",
                    "options": {
                        "temperature": 0.7,
                        "top_p": 0.9,
                        "num_predict": 150,
                        "stop": ["\n\n", "User:", "Human:", "Assistant:"]
                    }
                }
            }
        
    def print_header(self):
        """Print clean header"""
        os.system('clear' if os.name == 'posix' else 'cls')
        print("\033[0;35m╔══════════════════════════════════════════╗\033[0m")
        print("\033[0;35m║       \033[1;36mVaultModel AI System CLI\033[0;35m          ║\033[0m") 
        print("\033[0;35m║    \033[0;90mSimple Interface for Real AI\033[0;35m        ║\033[0m")
        print("\033[0;35m╚══════════════════════════════════════════╝\033[0m")
        print()
        
    def run_pipeline(self):
        """Execute vaultmodel_core.sh with filtered output"""
        print("\033[0;33m🚀 Starting VaultModel Pipeline...\033[0m")
        print()
        
        # Keywords to always show
        important_keywords = [
            '✓', '✗', 'Phase', 'GPU detected', 'Pipeline complete',
            'System ready', 'temperature:', 'GPU Temperature:', 'Real inference completed',
            'Docker is running', 'Model downloaded successfully', 'Session:', 'Path:',
            'tokens', 'Processing time', 'Output summary', 'GPU Status:', 'Memory Usage:'
        ]
        
        # Keywords to hide (Ollama spam)
        hide_keywords = [
            'pulling manifest', 'Attempt', 'level=INFO', 'level=WARN',
            'llama_model_loader', '[GIN]', 'time=', 'print_info',
            'load_tensors', 'llama_context', 'ggml_cuda_init',
            'load_backend', 'load:', 'Couldn\'t find', 'ssh-ed25519',
            'source=', 'msg=', '[?2026h', '[?25l', 'pulling 2af3b81862c6',
            'ggml_backend_cuda_buffer', 'compute_capability', 'llm_load_tensors'
        ]
        
        try:
            process = subprocess.Popen(
                ['./vaultmodel_core.sh'],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )
            
            session_id = None
            downloading = False
            download_progress_shown = False
            
            for line in iter(process.stdout.readline, ''):
                if line.strip():
                    # Capture session ID
                    if 'Session:' in line and 'vaultmodel_' in line:
                        # Extract just the timestamp part after vaultmodel_
                        parts = line.split('vaultmodel_')
                        if len(parts) > 1:
                            raw_id = parts[1].strip().split()[0]
                            # Remove ANSI color codes
                            session_id = re.sub(r'\x1b\[[0-9;]*m', '', raw_id)
                    
                    # Skip lines with keywords to hide
                    if any(keyword in line for keyword in hide_keywords):
                        continue
                        
                    # Show lines with important keywords
                    if any(keyword in line for keyword in important_keywords):
                        if '✓' in line:
                            print(f"\033[0;32m{line.rstrip()}\033[0m")
                        elif '✗' in line:
                            print(f"\033[0;31m{line.rstrip()}\033[0m")
                        elif 'Phase' in line and 'Phase' == line.strip().split()[0]:
                            print(f"\n\033[0;36m{line.rstrip()}\033[0m")
                        elif 'GPU' in line or 'temperature' in line:
                            print(f"\033[0;33m{line.rstrip()}\033[0m")
                        else:
                            print(line.rstrip())
                    # Handle model downloads with progress bar
                    elif 'Downloading' in line and 'model' in line:
                        print(f"\033[0;33m{line.rstrip()}\033[0m")
                        downloading = True
                        download_progress_shown = False
                    elif downloading and '%' in line and any(x in line for x in ['pulling', 'downloading']):
                        # Extract percentage if available
                        if not download_progress_shown:
                            print("\033[0;90m    Downloading: \033[0m", end='', flush=True)
                            download_progress_shown = True
                        # Show simple progress indicator
                        if '100%' in line:
                            print("\033[0;32m✓ Complete\033[0m")
                            downloading = False
                        else:
                            print(".", end='', flush=True)
                            
            process.wait()
            
            if process.returncode == 0:
                print("\n\033[0;32m✅ Pipeline executed successfully!\033[0m")
                self.pipeline_executed = True
                return True, session_id
            else:
                print("\n\033[0;31m❌ Pipeline failed\033[0m")
                return False, None
                
        except FileNotFoundError:
            print("\033[0;31m❌ Error: vaultmodel_core.sh not found\033[0m")
            return False, None
        except Exception as e:
            print(f"\033[0;31m❌ Error: {str(e)}\033[0m")
            return False, None
            
    def get_session_logs(self, session_id):
        """Get log files for a specific session"""
        if not session_id:
            return []
            
        session_path = os.path.join(self.logs_dir, f"vaultmodel_{session_id}")
        
        if not os.path.exists(session_path):
            return []
            
        log_files = []
        for file in os.listdir(session_path):
            if file.endswith(('.jsonl', '.json', '.log')):
                log_files.append({
                    'name': file,
                    'path': os.path.join(session_path, file),
                    'size': os.path.getsize(os.path.join(session_path, file))
                })
        return log_files
        
    def view_log_file(self, filepath):
        """Display log file contents in readable format"""
        filename = os.path.basename(filepath)
        print(f"\n\033[0;36m📄 Viewing: {filename}\033[0m")
        print("-" * 50)
        
        try:
            if filepath.endswith('.jsonl'):
                # Parse JSONL format
                with open(filepath, 'r') as f:
                    line_count = 0
                    for line in f:
                        line_count += 1
                        if line_count > 30:  # Limit output
                            print("\033[0;90m... (truncated, total lines: {})\033[0m".format(
                                sum(1 for _ in open(filepath))))
                            break
                        try:
                            entry = json.loads(line.strip())
                            level = entry.get('level', 'INFO')
                            message = entry.get('message', '')
                            component = entry.get('component', '')
                            
                            if level == 'ERROR':
                                print(f"\033[0;31m[{component}] {message}\033[0m")
                            elif level == 'SUCCESS':
                                print(f"\033[0;32m[{component}] {message}\033[0m")
                            elif level == 'WARNING':
                                print(f"\033[0;33m[{component}] {message}\033[0m")
                            else:
                                print(f"[{component}] {message}")
                        except:
                            print(line.strip())
                            
            elif filepath.endswith('.json'):
                # Pretty print JSON
                with open(filepath, 'r') as f:
                    data = json.load(f)
                    
                    # Special handling for different file types
                    if 'gpu_health.json' in filepath:
                        gpu = data.get('gpu', {})
                        print(f"GPU: {gpu.get('name', 'Unknown')}")
                        print(f"Temperature: {gpu.get('temperature_celsius', 'N/A')}°C")
                        print(f"Memory: {gpu.get('memory_used_mb', 0)}/{gpu.get('memory_total_mb', 0)} MB")
                        print(f"Driver: {gpu.get('driver_version', 'Unknown')}")
                        print(f"CUDA: {gpu.get('cuda_version', 'Unknown')}")
                        print(f"Status: {data.get('status', 'unknown')}")
                    elif 'output.json' in filepath:
                        print(f"Model: {data.get('model', 'Unknown')}")
                        print(f"Prompt: {data.get('prompt', 'N/A')}")
                        print(f"\nResponse:\n{data.get('response', 'N/A')}")
                        print(f"\nTokens: {data.get('usage', {}).get('total_tokens', 'N/A')}")
                        print(f"Processing time: {data.get('metadata', {}).get('processing_time_ms', 'N/A')}ms")
                    else:
                        print(json.dumps(data, indent=2))
                        
            elif filepath.endswith('.log'):
                # Display plain text log files
                with open(filepath, 'r') as f:
                    content = f.read()
                    print(content)
            else:
                # Unknown format, try to read as text
                with open(filepath, 'r') as f:
                    content = f.read()
                    print(content)
                    
        except Exception as e:
            print(f"\033[0;31mError reading file: {str(e)}\033[0m")
            
    def show_logs_menu(self, session_id):
        """Display logs menu"""
        print("\n\033[0;36m📋 Session Logs\033[0m")
        print("=" * 50)
        
        log_files = self.get_session_logs(session_id)
        
        if not log_files:
            print("\033[0;33mNo log files found for this session\033[0m")
            return
            
        print(f"\nSession: vaultmodel_{session_id}")
        print("\nAvailable logs:")
        
        for i, log in enumerate(log_files, 1):
            size_kb = log['size'] / 1024
            print(f"  {i}. \033[0;33m{log['name']}\033[0m ({size_kb:.1f} KB)")
            
        print(f"  0. \033[0;90mReturn to main menu\033[0m")
        
        while True:
            try:
                choice = input("\n\033[0;36mSelect log to view (0-{}): \033[0m".format(len(log_files)))
                choice = int(choice)
                
                if choice == 0:
                    break
                elif 1 <= choice <= len(log_files):
                    self.view_log_file(log_files[choice-1]['path'])
                    input("\n\033[0;90mPress Enter to continue...\033[0m")
                    
                    # Re-show the logs menu after viewing a file
                    print("\n\033[0;36m📋 Session Logs\033[0m")
                    print("=" * 50)
                    print(f"\nSession: vaultmodel_{session_id}")
                    print("\nAvailable logs:")
                    for i, log in enumerate(log_files, 1):
                        size_kb = log['size'] / 1024
                        print(f"  {i}. \033[0;33m{log['name']}\033[0m ({size_kb:.1f} KB)")
                    print(f"  0. \033[0;90mReturn to main menu\033[0m")
                else:
                    print("\033[0;31mInvalid choice\033[0m")
                    
            except ValueError:
                print("\033[0;31mPlease enter a number\033[0m")
            except KeyboardInterrupt:
                break
    
    def chat_with_ollama(self):
        """Interactive chat with Ollama"""
        print("\n\033[0;36m💬 Chat with Ollama AI\033[0m")
        print("=" * 50)
        print(f"\033[0;33mModel: {self.config['model']['name']}\033[0m")
        print("\033[0;90mType 'exit' or 'quit' to return to main menu\033[0m")
        print("\033[0;90mPress Ctrl+C to stop at any time\033[0m\n")
        
        # Start Ollama container
        print("\033[0;33m🔄 Starting Ollama chat service...\033[0m")
        result = subprocess.run(['./utils/start_ollama_chat.sh'], capture_output=True, text=True)
        
        if result.returncode != 0:
            print("\033[0;31m❌ Failed to start Ollama service\033[0m")
            print(result.stderr)
            return
            
        print("\033[0;32m✅ AI ready for chat!\033[0m\n")
        
        # Chat loop
        while True:
            try:
                # Get user input
                user_input = input("\033[0;36mYou: \033[0m")
                
                if user_input.lower() in ['exit', 'quit']:
                    break
                
                if not user_input.strip():
                    continue
                
                # Send to Ollama
                print("\033[0;33mAI: \033[0m", end='', flush=True)
                
                try:
                    # Prepare prompt with system context from MODELVAULT.md
                    # Only send context on first message or if asked about rules
                    if not hasattr(self, '_context_sent') or 'reglas' in user_input.lower() or 'rules' in user_input.lower() or 'normas' in user_input.lower():
                        full_prompt = f"""{self.system_context}

User: {user_input}
Assistant:"""
                        self._context_sent = True
                    else:
                        full_prompt = f"User: {user_input}\nAssistant:"
                    
                    # Make request to Ollama API
                    response = requests.post(
                        'http://localhost:11434/api/generate',
                        json={
                            'model': self.config['model']['name'],
                            'prompt': full_prompt,
                            'stream': True,
                            'options': self.config['model']['options']
                        },
                        stream=True
                    )
                    
                    # Stream the response
                    for line in response.iter_lines():
                        if line:
                            data = json.loads(line)
                            if 'response' in data:
                                print(data['response'], end='', flush=True)
                            if data.get('done', False):
                                print()  # New line after response
                                break
                                
                except requests.exceptions.ConnectionError:
                    print("\033[0;31mError: Cannot connect to Ollama. Make sure the container is running.\033[0m")
                except Exception as e:
                    print(f"\033[0;31mError: {str(e)}\033[0m")
                
                print()  # Extra line for spacing
                
            except KeyboardInterrupt:
                print("\n\033[0;90mReturning to main menu...\033[0m")
                break
    
    def show_gpu_dashboard(self):
        """Launch GPU dashboard"""
        print("\n\033[0;33m🚀 Launching GPU Dashboard...\033[0m")
        print("\033[0;90mPress Ctrl+C to return to menu\033[0m\n")
        try:
            subprocess.run(['./utils/gpu_dashboard.sh'])
        except KeyboardInterrupt:
            print("\n\033[0;90mReturning to main menu...\033[0m")
        except Exception as e:
            print(f"\033[0;31mError launching dashboard: {str(e)}\033[0m")
    
    def run_benchmark(self):
        """Run model benchmarks"""
        print("\n\033[0;33m🏃 Running Model Benchmarks...\033[0m")
        try:
            subprocess.run(['python3', 'utils/benchmark_inference.py'])
            input("\n\033[0;90mPress Enter to continue...\033[0m")
        except KeyboardInterrupt:
            print("\n\033[0;90mReturning to main menu...\033[0m")
        except Exception as e:
            print(f"\033[0;31mError running benchmark: {str(e)}\033[0m")
                
    def main_menu(self, session_id=None):
        """Show main menu after execution"""
        while True:
            print("\n\033[0;36m✨ Main Menu\033[0m")
            print("=" * 50)
            
            # Don't show run pipeline option if already executed
            if not self.pipeline_executed:
                print("  1. \033[0;32mRun inference pipeline\033[0m - Execute the VaultModel AI system")
            else:
                print("  1. \033[0;36mChat with Ollama AI\033[0m - Have a real conversation with the AI")
            
            if session_id:
                print("  2. \033[0;33mView session logs\033[0m - Review logs from the last run")
            print("  3. \033[0;90mExit\033[0m - Close the CLI")
            
            choice = input("\n\033[0;36mSelect option (1-3): \033[0m")
            
            if choice == '1':
                if not self.pipeline_executed:
                    # First time - run the pipeline
                    self.print_header()
                    success, new_session = self.run_pipeline()
                    if success and new_session:
                        session_id = new_session
                else:
                    # After pipeline - chat with Ollama
                    self.chat_with_ollama()
            elif choice == '2' and session_id:
                self.show_logs_menu(session_id)
            elif choice == '3':
                break
            else:
                print("\033[0;31mInvalid option\033[0m")
                
    def run(self):
        """Main execution"""
        self.print_header()
        
        # Run the pipeline
        success, session_id = self.run_pipeline()
        
        if success:
            # Show main menu
            self.main_menu(session_id)
                    
        print("\n\033[0;36mThank you for using VaultModel!\033[0m")
        
if __name__ == "__main__":
    cli = VaultModelCLI()
    cli.run()