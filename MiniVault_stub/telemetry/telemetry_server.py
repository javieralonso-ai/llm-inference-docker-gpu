#!/usr/bin/env python3
"""
ModelVault Telemetry Server
Purpose: HTTP endpoint for collecting and storing telemetry data
Author: Javier Alonso
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
from datetime import datetime
import threading
import time
import signal
import sys

class TelemetryHandler(BaseHTTPRequestHandler):
    """HTTP request handler for telemetry endpoints"""
    
    def log_message(self, format, *args):
        """Custom log format"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {self.address_string()} - {format % args}")
    
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            health_data = {
                "status": "healthy",
                "service": "ModelVault Telemetry",
                "timestamp": datetime.now().isoformat(),
                "uptime_seconds": int(time.time() - self.server.start_time),
                "events_received": self.server.event_count
            }
            
            self.wfile.write(json.dumps(health_data, indent=2).encode())
            
        elif self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            metrics_data = {
                "total_events": self.server.event_count,
                "events_by_level": self.server.events_by_level,
                "events_by_component": self.server.events_by_component,
                "last_event_time": self.server.last_event_time
            }
            
            self.wfile.write(json.dumps(metrics_data, indent=2).encode())
            
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"error": "Not found"}')
    
    def do_POST(self):
        """Handle POST requests"""
        if self.path == '/telemetry':
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length > 10240:  # Limit to 10KB
                self.send_response(413)
                self.end_headers()
                self.wfile.write(b'{"error": "Payload too large"}')
                return
            
            try:
                # Read and parse JSON data
                post_data = self.rfile.read(content_length)
                telemetry_data = json.loads(post_data.decode('utf-8'))
                
                # Add server timestamp
                telemetry_data['received_at'] = datetime.now().isoformat()
                
                # Save to telemetry log in session directory
                log_file = os.path.join(self.server.telemetry_dir, 'telemetry.jsonl')
                os.makedirs(os.path.dirname(log_file), exist_ok=True)
                with open(log_file, 'a') as f:
                    f.write(json.dumps(telemetry_data) + '\n')
                
                # Update metrics
                self.server.event_count += 1
                self.server.last_event_time = telemetry_data['received_at']
                
                # Track by level and component
                level = telemetry_data.get('level', 'UNKNOWN')
                component = telemetry_data.get('component', 'UNKNOWN')
                
                self.server.events_by_level[level] = self.server.events_by_level.get(level, 0) + 1
                self.server.events_by_component[component] = self.server.events_by_component.get(component, 0) + 1
                
                # Send success response
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                
                response = {
                    "status": "success",
                    "message": "Telemetry data received",
                    "event_id": self.server.event_count
                }
                
                self.wfile.write(json.dumps(response).encode())
                
            except json.JSONDecodeError:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"error": "Invalid JSON"}')
                
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"error": "Not found"}')

class TelemetryServer(HTTPServer):
    """Extended HTTP server with telemetry tracking"""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.start_time = time.time()
        self.event_count = 0
        self.events_by_level = {}
        self.events_by_component = {}
        self.last_event_time = None
        
        # Use session directory if available, otherwise create default
        # Look for session file in parent directory
        parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        session_file = os.path.join(parent_dir, '.current_session')
        
        if os.path.exists(session_file):
            with open(session_file, 'r') as f:
                session_dir = f.read().strip()
                # Use absolute path for telemetry directory
                self.telemetry_dir = os.path.join(parent_dir, session_dir)
        else:
            self.telemetry_dir = os.path.join(parent_dir, 'logs/telemetry')
            os.makedirs(self.telemetry_dir, exist_ok=True)

def run_server(port=8080):
    """Run the telemetry server"""
    print(f"🚀 ModelVault Telemetry Server v1.0")
    print(f"📡 Starting server on port {port}...")
    
    server = TelemetryServer(('0.0.0.0', port), TelemetryHandler)
    
    # Handle shutdown gracefully
    def signal_handler(sig, frame):
        print("\n👋 Shutting down telemetry server...")
        server.shutdown()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    print(f"✅ Server running at http://0.0.0.0:{port}")
    print(f"📊 Endpoints:")
    print(f"   - POST /telemetry - Submit telemetry data")
    print(f"   - GET  /health    - Health check")
    print(f"   - GET  /metrics   - View metrics")
    print(f"\nPress Ctrl+C to stop")
    
    # Run server in a separate thread
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()
    
    # Keep main thread alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='ModelVault Telemetry Server')
    parser.add_argument('--port', type=int, default=8080, help='Port to listen on (default: 8080)')
    args = parser.parse_args()
    
    run_server(args.port)