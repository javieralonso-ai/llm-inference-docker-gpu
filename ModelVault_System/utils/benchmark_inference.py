#!/usr/bin/env python3
"""
ModelVault Inference Benchmark
Compares performance across different models and configurations
"""

import json
import time
import requests
import statistics
from datetime import datetime

# Colors for output
class Colors:
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'

def benchmark_model(model_name, prompt, runs=3):
    """Benchmark a specific model"""
    print(f"\n{Colors.CYAN}Testing model: {model_name}{Colors.NC}")
    
    times = []
    tokens = []
    
    for i in range(runs):
        print(f"  Run {i+1}/{runs}...", end='', flush=True)
        
        start_time = time.time()
        
        try:
            response = requests.post(
                'http://localhost:11434/api/generate',
                json={
                    'model': model_name,
                    'prompt': prompt,
                    'stream': False,
                    'options': {
                        'temperature': 0.7,
                        'num_predict': 100
                    }
                }
            )
            
            if response.status_code == 200:
                result = response.json()
                elapsed = time.time() - start_time
                times.append(elapsed)
                
                # Count tokens
                response_text = result.get('response', '')
                token_count = len(response_text.split())
                tokens.append(token_count)
                
                print(f" {Colors.GREEN}✓{Colors.NC} ({elapsed:.2f}s)")
            else:
                print(f" {Colors.RED}✗{Colors.NC} (Error: {response.status_code})")
                
        except Exception as e:
            print(f" {Colors.RED}✗{Colors.NC} (Error: {str(e)})")
    
    if times:
        avg_time = statistics.mean(times)
        avg_tokens = statistics.mean(tokens)
        tokens_per_sec = avg_tokens / avg_time if avg_time > 0 else 0
        
        return {
            'model': model_name,
            'avg_time': avg_time,
            'avg_tokens': avg_tokens,
            'tokens_per_second': tokens_per_sec,
            'runs': len(times)
        }
    else:
        return None

def main():
    """Run benchmarks"""
    print(f"{Colors.BOLD}{Colors.BLUE}╔════════════════════════════════════════════╗{Colors.NC}")
    print(f"{Colors.BOLD}{Colors.BLUE}║     ModelVault Inference Benchmark         ║{Colors.NC}")
    print(f"{Colors.BOLD}{Colors.BLUE}╚════════════════════════════════════════════╝{Colors.NC}")
    
    # Test prompt
    test_prompt = "Explain the benefits of on-premise AI deployment in one paragraph."
    
    # Models to test (only test installed models)
    models_to_test = ['tinyllama', 'mistral']
    
    print(f"\nTest prompt: '{test_prompt[:50]}...'\n")
    print("Checking available models...")
    
    # Check which models are available
    available_models = []
    try:
        response = requests.get('http://localhost:11434/api/tags')
        if response.status_code == 200:
            models_data = response.json()
            installed_models = [m['name'].split(':')[0] for m in models_data.get('models', [])]
            for model in models_to_test:
                if model in installed_models:
                    available_models.append(model)
                    print(f"  {Colors.GREEN}✓{Colors.NC} {model}")
                else:
                    print(f"  {Colors.YELLOW}○{Colors.NC} {model} (not installed)")
    except:
        print(f"{Colors.RED}Error: Cannot connect to Ollama{Colors.NC}")
        return
    
    if not available_models:
        print(f"\n{Colors.YELLOW}No models available for testing{Colors.NC}")
        return
    
    # Run benchmarks
    print(f"\nRunning benchmarks (3 runs each)...")
    results = []
    
    for model in available_models:
        result = benchmark_model(model, test_prompt)
        if result:
            results.append(result)
    
    # Display results
    if results:
        print(f"\n{Colors.BOLD}═══ BENCHMARK RESULTS ═══{Colors.NC}\n")
        
        # Sort by performance
        results.sort(key=lambda x: x['tokens_per_second'], reverse=True)
        
        for i, result in enumerate(results):
            if i == 0:
                medal = "🥇"
            elif i == 1:
                medal = "🥈"
            else:
                medal = "🥉"
                
            print(f"{medal} {Colors.BOLD}{result['model']}{Colors.NC}")
            print(f"   Average time: {result['avg_time']:.2f}s")
            print(f"   Tokens generated: {result['avg_tokens']:.0f}")
            print(f"   Performance: {Colors.GREEN}{result['tokens_per_second']:.1f} tokens/sec{Colors.NC}")
            print()
        
        # Save results
        output_file = f"benchmark_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(output_file, 'w') as f:
            json.dump({
                'timestamp': datetime.now().isoformat(),
                'prompt': test_prompt,
                'results': results
            }, f, indent=2)
        
        print(f"Results saved to: {output_file}")
        
        # Performance comparison
        if len(results) > 1:
            fastest = results[0]
            slowest = results[-1]
            speedup = fastest['tokens_per_second'] / slowest['tokens_per_second']
            print(f"\n{Colors.CYAN}Performance Analysis:{Colors.NC}")
            print(f"{fastest['model']} is {speedup:.1f}x faster than {slowest['model']}")

if __name__ == "__main__":
    main()