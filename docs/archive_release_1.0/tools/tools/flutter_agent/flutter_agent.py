#!/usr/bin/env python3
"""
🚀 FLUTTER AGENT CONTROLLER - BULLETPROOF EDITION 🚀

A foolproof controller for AI agents to run and interact with Flutter apps.
Uses file-based IPC to avoid terminal conflicts.

=============================================================================
CRITICAL FOR AGENTS: Use Start-Process to launch, then send commands normally!
=============================================================================

WORKFLOW FOR AGENTS:
--------------------
1. START FLUTTER (in separate window):
   Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command",
     "cd '<working_dir>'; python tools/flutter_agent/flutter_agent.py run <target.dart> -d chrome"

2. WAIT FOR READY:
   python tools/flutter_agent/flutter_agent.py wait --timeout 30

3. SEND COMMANDS:
   python tools/flutter_agent/flutter_agent.py cmd s          # screenshot
   python tools/flutter_agent/flutter_agent.py cmd r          # hot reload
   python tools/flutter_agent/flutter_agent.py cmd R          # hot restart
   python tools/flutter_agent/flutter_agent.py cmd h          # help

4. CHECK STATUS:
   python tools/flutter_agent/flutter_agent.py status

5. READ OUTPUT:
   python tools/flutter_agent/flutter_agent.py output
   python tools/flutter_agent/flutter_agent.py output --tail 50

6. STOP FLUTTER:
   python tools/flutter_agent/flutter_agent.py stop

=============================================================================

FLUTTER INTERACTIVE COMMANDS:
-----------------------------
  r  - Hot reload
  R  - Hot restart (full restart)
  h  - Show help
  d  - Detach (terminate but keep app running)
  c  - Clear screen
  q  - Quit (stop app and exit)
  s  - Screenshot (saves to build/screenshots/)
  w  - Toggle WebSocket debugging
  p  - Toggle performance overlay
  P  - Toggle performance overlay (with FPS)
  a  - Toggle accessibility (semantics)
  I  - Toggle widget inspector
  o  - Toggle operating system (iOS/Android simulation)
  b  - Toggle platform brightness
  t  - Dump widget tree
  L  - Dump layer tree
  S  - Dump accessibility tree (semantics)

=============================================================================
"""

import argparse
import json
import os
import subprocess
import sys
import threading
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

# ============================================================================
# CONFIGURATION
# ============================================================================

# Control directory - relative to this script's location
SCRIPT_DIR = Path(__file__).parent
CONTROL_DIR = SCRIPT_DIR / ".flutter_control"

# Control files
STATUS_FILE = CONTROL_DIR / "status.json"
COMMAND_FILE = CONTROL_DIR / "command.json"
RESPONSE_FILE = CONTROL_DIR / "response.json"
OUTPUT_FILE = CONTROL_DIR / "output.log"
ERROR_FILE = CONTROL_DIR / "error.log"
READY_FILE = CONTROL_DIR / "ready.flag"
PID_FILE = CONTROL_DIR / "flutter.pid"

# Timeouts
DEFAULT_STARTUP_TIMEOUT = 30  # seconds to wait for Flutter to be ready
COMMAND_CHECK_INTERVAL = 0.3  # how often to check for commands
COMMAND_TIMEOUT = 5  # seconds to wait for command acknowledgment


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================


def ensure_control_dir():
    """Ensure the control directory exists."""
    CONTROL_DIR.mkdir(exist_ok=True)


def clean_control_files():
    """Remove all control files for a fresh start."""
    ensure_control_dir()
    for f in [STATUS_FILE, COMMAND_FILE, RESPONSE_FILE, READY_FILE, PID_FILE]:
        if f.exists():
            try:
                f.unlink()
            except:
                pass


def write_json(filepath: Path, data: dict):
    """Write JSON data to file with timestamp."""
    ensure_control_dir()
    data["_timestamp"] = datetime.now().isoformat()
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def read_json(filepath: Path) -> Optional[dict]:
    """Read JSON data from file."""
    if filepath.exists():
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return None
    return None


def write_status(status: str, **kwargs):
    """Write status with additional data."""
    data = {"status": status, **kwargs}
    write_json(STATUS_FILE, data)


def read_status() -> dict:
    """Read current status."""
    data = read_json(STATUS_FILE)
    return data if data else {"status": "unknown"}


def log_output(message: str, is_error: bool = False):
    """Log output to file and optionally print."""
    ensure_control_dir()
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    line = f"[{timestamp}] {message}"

    target = ERROR_FILE if is_error else OUTPUT_FILE
    with open(target, "a", encoding="utf-8") as f:
        f.write(line + "\n")


# ============================================================================
# FLUTTER RUNNER (runs in separate window)
# ============================================================================


def run_flutter(
    target: str,
    device: str = "chrome",
    working_dir: str = None,
    extra_args: list = None,
):
    """
    Run Flutter app and monitor for commands.
    This function runs in the SEPARATE PowerShell window.
    """
    if working_dir:
        os.chdir(working_dir)

    clean_control_files()
    ensure_control_dir()

    # Build command
    cmd = ["flutter", "run", "-t", target, "-d", device]
    if extra_args:
        cmd.extend(extra_args)

    print("=" * 70)
    print("🚀 FLUTTER AGENT CONTROLLER - STARTING")
    print("=" * 70)
    print(f"Command: {' '.join(cmd)}")
    print(f"Working Directory: {os.getcwd()}")
    print(f"Control Directory: {CONTROL_DIR}")
    print("=" * 70)

    write_status(
        "starting",
        command=" ".join(cmd),
        working_dir=os.getcwd(),
        device=device,
        target=target,
    )

    try:
        # Start Flutter process
        process = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            shell=True,  # Required on Windows for PATH resolution
        )

        # Save PID
        with open(PID_FILE, "w") as f:
            f.write(str(process.pid))

        write_status("running", pid=process.pid, device=device, target=target)

        print(f"✅ Flutter started with PID: {process.pid}")

        # Output reader thread
        flutter_ready = threading.Event()
        output_lines = []

        def read_output():
            """Continuously read Flutter output."""
            try:
                with open(OUTPUT_FILE, "w", encoding="utf-8") as log:
                    for line in iter(process.stdout.readline, ""):
                        if not line:
                            break

                        # Write to log and console
                        log.write(line)
                        log.flush()
                        print(line, end="", flush=True)
                        output_lines.append(line)

                        # Detect when Flutter is ready
                        if (
                            "Flutter run key commands" in line
                            or "To hot restart" in line
                        ):
                            flutter_ready.set()
                            READY_FILE.touch()
                            write_status(
                                "ready", pid=process.pid, device=device, target=target
                            )
                            print("\n" + "=" * 70)
                            print("✅ FLUTTER IS READY - Monitoring for commands...")
                            print(
                                f"   Send commands via: python flutter_agent.py cmd <command>"
                            )
                            print("=" * 70 + "\n")
            except Exception as e:
                log_output(f"Output reader error: {e}", is_error=True)

        # Start output reader
        reader_thread = threading.Thread(target=read_output, daemon=True)
        reader_thread.start()

        # Wait for ready or timeout
        if not flutter_ready.wait(timeout=60):
            print("⚠️ Warning: Flutter ready signal not detected, but continuing...")
            READY_FILE.touch()
            write_status(
                "ready_timeout",
                pid=process.pid,
                device=device,
                target=target,
                warning="Ready signal not detected",
            )

        # Command monitoring loop
        last_command_id = None
        while process.poll() is None:
            # Check for commands
            cmd_data = read_json(COMMAND_FILE)
            if cmd_data and cmd_data.get("id") != last_command_id:
                last_command_id = cmd_data.get("id")
                command = cmd_data.get("command", "")

                print(f"\n>>> Received command: '{command}' (id: {last_command_id})")

                if command.upper() == "QUIT" or command == "q":
                    print(">>> Stopping Flutter...")
                    process.stdin.write("q\n")
                    process.stdin.flush()
                    write_json(
                        RESPONSE_FILE,
                        {
                            "id": last_command_id,
                            "command": command,
                            "status": "executed",
                            "message": "Quit command sent",
                        },
                    )
                    break
                else:
                    try:
                        process.stdin.write(command)
                        process.stdin.flush()
                        print(f">>> Command '{command}' sent to Flutter")
                        write_json(
                            RESPONSE_FILE,
                            {
                                "id": last_command_id,
                                "command": command,
                                "status": "executed",
                                "message": f"Command '{command}' sent successfully",
                            },
                        )
                    except Exception as e:
                        print(f">>> Error sending command: {e}")
                        write_json(
                            RESPONSE_FILE,
                            {
                                "id": last_command_id,
                                "command": command,
                                "status": "error",
                                "message": str(e),
                            },
                        )

            time.sleep(COMMAND_CHECK_INTERVAL)

        # Process ended
        exit_code = process.wait()
        write_status("stopped", exit_code=exit_code, pid=process.pid)

        # Clean up ready flag
        if READY_FILE.exists():
            READY_FILE.unlink()

        print(f"\n{'=' * 70}")
        print(f"Flutter exited with code: {exit_code}")
        print(f"{'=' * 70}")

        return exit_code

    except KeyboardInterrupt:
        print("\n⚠️ Interrupted by user")
        write_status("interrupted")
        return 1
    except Exception as e:
        print(f"\n❌ Error: {e}")
        write_status("error", error=str(e))
        return 1


# ============================================================================
# AGENT COMMANDS (run from agent's terminal)
# ============================================================================


def cmd_status():
    """Show current Flutter status."""
    status = read_status()
    print(json.dumps(status, indent=2))
    return 0 if status.get("status") in ["running", "ready", "ready_timeout"] else 1


def cmd_wait(timeout: int = DEFAULT_STARTUP_TIMEOUT):
    """Wait for Flutter to be ready."""
    print(f"Waiting for Flutter to be ready (timeout: {timeout}s)...")

    start = time.time()
    while time.time() - start < timeout:
        if READY_FILE.exists():
            status = read_status()
            print(f"✅ Flutter is ready! (PID: {status.get('pid', 'unknown')})")
            return 0

        status = read_status()
        if status.get("status") in ["error", "stopped", "interrupted"]:
            print(f"❌ Flutter failed to start: {status}")
            return 1

        time.sleep(0.5)

    print(f"❌ Timeout waiting for Flutter after {timeout}s")
    return 1


def cmd_send(command: str):
    """Send a command to Flutter."""
    if not READY_FILE.exists():
        status = read_status()
        if status.get("status") not in ["running", "ready", "ready_timeout"]:
            print(
                f"❌ Flutter is not running (status: {status.get('status', 'unknown')})"
            )
            return 1

    # Generate unique command ID
    cmd_id = f"{time.time():.6f}"

    # Write command
    write_json(COMMAND_FILE, {"id": cmd_id, "command": command})

    print(f"📤 Command '{command}' sent (id: {cmd_id})")

    # Wait for response
    start = time.time()
    while time.time() - start < COMMAND_TIMEOUT:
        response = read_json(RESPONSE_FILE)
        if response and response.get("id") == cmd_id:
            if response.get("status") == "executed":
                print(f"✅ {response.get('message', 'Command executed')}")
                return 0
            else:
                print(f"❌ {response.get('message', 'Command failed')}")
                return 1
        time.sleep(0.2)

    print(f"⚠️ Command sent but no confirmation received")
    return 0  # Still return 0 as command was written


def cmd_stop():
    """Stop Flutter gracefully."""
    return cmd_send("q")


def cmd_screenshot():
    """Take a screenshot."""
    return cmd_send("s")


def cmd_hot_reload():
    """Hot reload the app."""
    return cmd_send("r")


def cmd_hot_restart():
    """Hot restart the app."""
    return cmd_send("R")


def cmd_output(tail: int = None, follow: bool = False):
    """Show Flutter output."""
    if not OUTPUT_FILE.exists():
        print("No output file found")
        return 1

    with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if tail:
        lines = lines[-tail:]

    for line in lines:
        print(line, end="")

    return 0


def cmd_clean():
    """Clean all control files."""
    clean_control_files()
    print("✅ Control files cleaned")
    return 0


def generate_start_command(
    target: str, device: str = "chrome", working_dir: str = None
) -> str:
    """Generate the PowerShell Start-Process command for agents."""
    if working_dir is None:
        working_dir = os.getcwd()

    script_path = Path(__file__).resolve()

    cmd = (
        f'Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", '
        f"\"cd '{working_dir}'; python '{script_path}' run '{target}' -d {device}\""
    )

    return cmd


def cmd_generate(target: str, device: str = "chrome", working_dir: str = None):
    """Generate the start command for agents to copy."""
    cmd = generate_start_command(target, device, working_dir)

    print("=" * 70)
    print("📋 COPY THIS COMMAND TO START FLUTTER:")
    print("=" * 70)
    print(cmd)
    print("=" * 70)
    print("\nThen use these commands to interact:")
    print(f"  python {Path(__file__).name} wait --timeout 30")
    print(f"  python {Path(__file__).name} cmd s    # screenshot")
    print(f"  python {Path(__file__).name} cmd r    # hot reload")
    print(f"  python {Path(__file__).name} stop")
    print("=" * 70)

    return 0


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================


def main():
    parser = argparse.ArgumentParser(
        description="🚀 Flutter Agent Controller - Bulletproof Edition",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    subparsers = parser.add_subparsers(dest="action", help="Action to perform")

    # RUN - Start Flutter (runs in separate window)
    run_parser = subparsers.add_parser(
        "run", help="Run Flutter app (use with Start-Process)"
    )
    run_parser.add_argument("target", help="Dart file to run (e.g., lib/main.dart)")
    run_parser.add_argument(
        "-d", "--device", default="chrome", help="Device to run on (default: chrome)"
    )
    run_parser.add_argument(
        "-w", "--working-dir", help="Working directory (default: current)"
    )
    run_parser.add_argument("--args", nargs="*", help="Additional Flutter arguments")

    # WAIT - Wait for Flutter to be ready
    wait_parser = subparsers.add_parser("wait", help="Wait for Flutter to be ready")
    wait_parser.add_argument(
        "-t",
        "--timeout",
        type=int,
        default=DEFAULT_STARTUP_TIMEOUT,
        help=f"Timeout in seconds (default: {DEFAULT_STARTUP_TIMEOUT})",
    )

    # CMD - Send a command
    cmd_parser = subparsers.add_parser("cmd", help="Send command to Flutter")
    cmd_parser.add_argument("command", help="Command to send (s/r/R/q/h/etc.)")

    # STATUS - Check status
    subparsers.add_parser("status", help="Show Flutter status")

    # STOP - Stop Flutter
    subparsers.add_parser("stop", help="Stop Flutter gracefully")

    # SCREENSHOT - Take screenshot
    subparsers.add_parser("screenshot", help="Take a screenshot")

    # RELOAD - Hot reload
    subparsers.add_parser("reload", help="Hot reload the app")

    # RESTART - Hot restart
    subparsers.add_parser("restart", help="Hot restart the app")

    # OUTPUT - Show output
    output_parser = subparsers.add_parser("output", help="Show Flutter output")
    output_parser.add_argument("-t", "--tail", type=int, help="Show last N lines")

    # CLEAN - Clean control files
    subparsers.add_parser("clean", help="Clean all control files")

    # GENERATE - Generate start command
    gen_parser = subparsers.add_parser(
        "generate", help="Generate start command for agents"
    )
    gen_parser.add_argument("target", help="Dart file to run")
    gen_parser.add_argument("-d", "--device", default="chrome", help="Device")
    gen_parser.add_argument("-w", "--working-dir", help="Working directory")

    args = parser.parse_args()

    # Execute action
    if args.action == "run":
        sys.exit(run_flutter(args.target, args.device, args.working_dir, args.args))
    elif args.action == "wait":
        sys.exit(cmd_wait(args.timeout))
    elif args.action == "cmd":
        sys.exit(cmd_send(args.command))
    elif args.action == "status":
        sys.exit(cmd_status())
    elif args.action == "stop":
        sys.exit(cmd_stop())
    elif args.action == "screenshot":
        sys.exit(cmd_screenshot())
    elif args.action == "reload":
        sys.exit(cmd_hot_reload())
    elif args.action == "restart":
        sys.exit(cmd_hot_restart())
    elif args.action == "output":
        sys.exit(cmd_output(args.tail))
    elif args.action == "clean":
        sys.exit(cmd_clean())
    elif args.action == "generate":
        sys.exit(cmd_generate(args.target, args.device, args.working_dir))
    else:
        parser.print_help()
        print("\n" + "=" * 70)
        print("QUICK START FOR AGENTS:")
        print("=" * 70)
        print("1. Start Flutter in separate window:")
        print(
            '   Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command",'
        )
        print(
            "     \"cd '<working_dir>'; python tools/flutter_agent.py run lib/main.dart -d chrome\""
        )
        print("\n2. Wait for ready:")
        print("   python tools/flutter_agent.py wait --timeout 30")
        print("\n3. Send commands:")
        print("   python tools/flutter_agent.py cmd s    # screenshot")
        print("   python tools/flutter_agent.py cmd r    # hot reload")
        print("   python tools/flutter_agent.py stop")
        print("=" * 70)


if __name__ == "__main__":
    main()
