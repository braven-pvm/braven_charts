#!/usr/bin/env python3
"""
Send keystrokes to the active window.
Usage: python send_keystroke.py <key>
Example: python send_keystroke.py s
"""

import subprocess
import sys


def send_key_windows(key: str):
    """Send a keystroke using PowerShell SendKeys on Windows."""
    # PowerShell script to send keys to the active window
    ps_script = f"""
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("{key}")
"""
    result = subprocess.run(
        ["powershell", "-Command", ps_script], capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Error: {result.stderr}", file=sys.stderr)
        return False
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python send_keystroke.py <key>")
        print("Example: python send_keystroke.py s")
        sys.exit(1)

    key = sys.argv[1]
    print(f"Sending keystroke: {key}")

    if send_key_windows(key):
        print("Keystroke sent successfully")
    else:
        print("Failed to send keystroke")
        sys.exit(1)


if __name__ == "__main__":
    main()
