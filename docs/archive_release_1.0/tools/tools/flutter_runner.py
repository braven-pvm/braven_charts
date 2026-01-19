#!/usr/bin/env python3
"""
Flutter Runner with Interactive Control

This script runs a Flutter app and allows sending interactive commands
(like 's' for screenshot, 'r' for hot reload) via stdin control.

Usage:
    python flutter_runner.py <target_file> [--device <device>] [--screenshot-delay <seconds>]

Example:
    python flutter_runner.py lib/multi_axis_test_app.dart -d chrome --screenshot-delay 5

Commands (while running):
    s - Take screenshot
    r - Hot reload
    R - Hot restart
    q - Quit
"""

import argparse
import os
import subprocess
import sys
import threading
import time
from pathlib import Path


class FlutterRunner:
    def __init__(
        self, target_file: str, device: str = "chrome", working_dir: str = None
    ):
        self.target_file = target_file
        self.device = device
        self.working_dir = working_dir or os.getcwd()
        self.process = None
        self.running = False
        self._output_thread = None

    def start(self) -> bool:
        """Start the Flutter process."""
        cmd = ["flutter", "run", "-t", self.target_file, "-d", self.device]

        print(f"Starting Flutter: {' '.join(cmd)}")
        print(f"Working directory: {self.working_dir}")

        try:
            self.process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                cwd=self.working_dir,
                text=True,
                bufsize=1,  # Line buffered
            )
            self.running = True

            # Start output reader thread
            self._output_thread = threading.Thread(
                target=self._read_output, daemon=True
            )
            self._output_thread.start()

            return True
        except Exception as e:
            print(f"Error starting Flutter: {e}")
            return False

    def _read_output(self):
        """Read and print Flutter output in real-time."""
        try:
            while self.running and self.process:
                line = self.process.stdout.readline()
                if line:
                    print(line, end="", flush=True)
                elif self.process.poll() is not None:
                    break
        except Exception as e:
            print(f"Output reader error: {e}")
        finally:
            self.running = False

    def send_command(self, cmd: str) -> bool:
        """Send a single character command to Flutter."""
        if not self.process or not self.running:
            print("Flutter is not running!")
            return False

        try:
            self.process.stdin.write(cmd)
            self.process.stdin.flush()
            print(f"\n>>> Sent command: '{cmd}'")
            return True
        except Exception as e:
            print(f"Error sending command: {e}")
            return False

    def screenshot(self) -> bool:
        """Take a screenshot."""
        return self.send_command("s")

    def hot_reload(self) -> bool:
        """Perform hot reload."""
        return self.send_command("r")

    def hot_restart(self) -> bool:
        """Perform hot restart."""
        return self.send_command("R")

    def quit(self) -> bool:
        """Quit the Flutter app."""
        result = self.send_command("q")
        self.running = False
        return result

    def wait_for_ready(self, timeout: float = 60) -> bool:
        """Wait for Flutter to be ready (connected to debug service)."""
        print("Waiting for Flutter to be ready...")
        # Just wait a reasonable time for the app to start
        # In a more sophisticated version, we'd parse output for specific markers
        time.sleep(timeout if timeout < 15 else 15)
        return self.running

    def is_running(self) -> bool:
        """Check if Flutter is still running."""
        if self.process:
            return self.process.poll() is None
        return False


def run_with_auto_screenshot(target: str, device: str, delay: float, working_dir: str):
    """Run Flutter and take a screenshot after a delay."""
    runner = FlutterRunner(target, device, working_dir)

    if not runner.start():
        print("Failed to start Flutter!")
        sys.exit(1)

    print(f"\nWaiting {delay} seconds before taking screenshot...")
    time.sleep(delay)

    if runner.is_running():
        print("\nTaking screenshot...")
        runner.screenshot()

        # Wait a bit for screenshot to complete
        time.sleep(2)

        print("\nScreenshot complete. Flutter is still running.")
        print("Press Ctrl+C to quit, or enter commands (s/r/R/q):")

        try:
            while runner.is_running():
                cmd = input()
                if cmd in ["s", "r", "R", "q", "h", "c", "d"]:
                    runner.send_command(cmd)
                    if cmd == "q":
                        break
                else:
                    print(f"Unknown command: {cmd}")
        except KeyboardInterrupt:
            print("\nStopping Flutter...")
            runner.quit()
    else:
        print("Flutter stopped unexpectedly!")
        sys.exit(1)


def run_interactive(target: str, device: str, working_dir: str):
    """Run Flutter in fully interactive mode."""
    runner = FlutterRunner(target, device, working_dir)

    if not runner.start():
        print("Failed to start Flutter!")
        sys.exit(1)

    print("\nFlutter started. Enter commands (s/r/R/q/h/c/d) or Ctrl+C to quit:")

    try:
        while runner.is_running():
            cmd = input()
            if cmd in ["s", "r", "R", "q", "h", "c", "d"]:
                runner.send_command(cmd)
                if cmd == "q":
                    break
            elif cmd:
                print(f"Unknown command: {cmd}. Use s/r/R/q/h/c/d")
    except KeyboardInterrupt:
        print("\nStopping Flutter...")
        runner.quit()


def main():
    parser = argparse.ArgumentParser(
        description="Run Flutter with interactive command control",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Commands:
  s - Take screenshot
  r - Hot reload
  R - Hot restart
  h - Show help
  c - Clear screen
  d - Detach (leave app running)
  q - Quit

Examples:
  # Run and take screenshot after 10 seconds
  python flutter_runner.py lib/main.dart -d chrome --screenshot-delay 10
  
  # Run in interactive mode
  python flutter_runner.py lib/main.dart -d chrome
        """,
    )

    parser.add_argument("target", help="Dart file to run (e.g., lib/main.dart)")
    parser.add_argument(
        "-d", "--device", default="chrome", help="Device to run on (default: chrome)"
    )
    parser.add_argument(
        "--screenshot-delay",
        type=float,
        default=0,
        help="Take screenshot after N seconds (0 = interactive mode)",
    )
    parser.add_argument(
        "--working-dir",
        "-w",
        default=None,
        help="Working directory (default: current directory)",
    )

    args = parser.parse_args()

    working_dir = args.working_dir or os.getcwd()

    if args.screenshot_delay > 0:
        run_with_auto_screenshot(
            args.target, args.device, args.screenshot_delay, working_dir
        )
    else:
        run_interactive(args.target, args.device, working_dir)


if __name__ == "__main__":
    main()
