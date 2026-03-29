#!/usr/bin/env python3
"""
Simple Logger for VaultModel IA
Purpose: Handle all logging from a single Python script
Author: Javier Alonso
"""

import json
import os
import sys
import subprocess
from datetime import datetime, timezone
from pathlib import Path

# Global session path (shared across calls)
SESSION_FILE = Path(".current_session")

def init_session(name="vaultmodel"):
    """Initialize a new logging session"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    session_id = f"{name}_{timestamp}"
    session_dir = Path(f"logs/sessions/{session_id}")
    session_dir.mkdir(parents=True, exist_ok=True)
    
    # Save session path for other calls
    SESSION_FILE.write_text(str(session_dir))
    
    # Create session info
    info = {
        "session_id": session_id,
        "start_time": datetime.now().isoformat(),
        "working_dir": os.getcwd()
    }
    
    with open(session_dir / "session_info.json", 'w') as f:
        json.dump(info, f, indent=2)
    
    print(f"SESSION_DIR={session_dir}")
    print(f"SESSION_ID={session_id}")
    return str(session_dir)

def log_event(level, component, message):
    """Log an event to the current session"""
    if not SESSION_FILE.exists():
        return
    
    session_dir = Path(SESSION_FILE.read_text().strip())
    log_file = session_dir / "execution.jsonl"
    
    event = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": level,
        "component": component,
        "message": message
    }
    
    with open(log_file, 'a') as f:
        f.write(json.dumps(event) + '\n')

def show_summary():
    """Show summary of current session"""
    if not SESSION_FILE.exists():
        print("No active session")
        return
    
    session_dir = Path(SESSION_FILE.read_text().strip())
    
    print(f"\n\033[0;34m{'='*50}\033[0m")
    print(f"\033[0;32mSession Complete!\033[0m")
    print(f"\n\033[0;34mLogs saved in:\033[0m")
    print(f"  \033[0;36m{session_dir.absolute()}\033[0m")
    
    print(f"\n\033[0;34mFiles created:\033[0m")
    for file in session_dir.glob("*"):
        if file.is_file():
            size = file.stat().st_size
            print(f"  \033[0;32m✓\033[0m {file.name} ({size:,} bytes)")
    
    # Clean up session file
    SESSION_FILE.unlink(missing_ok=True)

# CLI
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: simple_logger.py <command> [args]")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "init":
        name = sys.argv[2] if len(sys.argv) > 2 else "vaultmodel"
        init_session(name)
    
    elif cmd == "log":
        if len(sys.argv) < 5:
            print("Usage: simple_logger.py log <level> <component> <message>")
            sys.exit(1)
        log_event(sys.argv[2], sys.argv[3], sys.argv[4])
    
    elif cmd == "summary":
        show_summary()