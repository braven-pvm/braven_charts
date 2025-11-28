# 🚀 Flutter Agent Integration Guide

## The Breakthrough: Agents Can Now Control Flutter!

This guide explains how AI agents can run Flutter apps, interact with them, and take screenshots - all without killing the process.

## The Problem We Solved

**Previously**: Agents would run `flutter run` in a terminal, but any subsequent command (`run_in_terminal`) would go to the SAME terminal and kill the Flutter process.

**Now**: We use `Start-Process` to launch Flutter in a **completely separate PowerShell window**, then communicate via file-based IPC (inter-process communication).

---

## Quick Start for Agents

### 1. Start Flutter (SEPARATE WINDOW)

```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd '<working_dir>'; python tools/flutter_agent/flutter_agent.py run <target.dart> -d chrome"
```

**Example**:
```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd 'E:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ../tools/flutter_agent/flutter_agent.py run lib/main.dart -d chrome"
```

### 2. Wait for Flutter to be Ready

```powershell
python tools/flutter_agent/flutter_agent.py wait --timeout 30
```

### 3. Send Commands

```powershell
# Take screenshot
python tools/flutter_agent/flutter_agent.py screenshot

# Or use cmd for any command
python tools/flutter_agent/flutter_agent.py cmd s    # screenshot
python tools/flutter_agent/flutter_agent.py cmd r    # hot reload
python tools/flutter_agent/flutter_agent.py cmd R    # hot restart
```

### 4. Check Status

```powershell
python tools/flutter_agent/flutter_agent.py status
```

### 5. Read Output

```powershell
python tools/flutter_agent/flutter_agent.py output           # all output
python tools/flutter_agent/flutter_agent.py output --tail 50  # last 50 lines
```

### 6. Stop Flutter

```powershell
python tools/flutter_agent/flutter_agent.py stop
```

---

## Complete Command Reference

| Command | Description |
|---------|-------------|
| `run <target> -d <device>` | Start Flutter (use with Start-Process) |
| `wait --timeout <sec>` | Wait for Flutter to be ready |
| `status` | Check if Flutter is running |
| `cmd <char>` | Send any Flutter command |
| `screenshot` | Take a screenshot (alias for `cmd s`) |
| `reload` | Hot reload (alias for `cmd r`) |
| `restart` | Hot restart (alias for `cmd R`) |
| `stop` | Stop Flutter gracefully |
| `output [--tail N]` | Show Flutter output |
| `clean` | Clean control files |
| `generate <target>` | Generate Start-Process command |

---

## Flutter Interactive Commands

These can be sent via `python tools/flutter_agent/flutter_agent.py cmd <key>`:

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart (full restart) |
| `s` | Screenshot (saves to build/screenshots/) |
| `q` | Quit |
| `h` | Help |
| `c` | Clear terminal |
| `d` | Detach (keep app running) |
| `p` | Toggle performance overlay |
| `P` | Toggle performance overlay with FPS |
| `a` | Toggle accessibility |
| `I` | Toggle widget inspector |
| `o` | Toggle OS simulation |
| `b` | Toggle brightness |
| `t` | Dump widget tree |
| `L` | Dump layer tree |
| `S` | Dump accessibility tree |
| `w` | Toggle WebSocket debugging |

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AGENT'S TERMINAL                          │
│  python flutter_agent.py cmd s                               │
│           │                                                  │
│           ▼                                                  │
│  ┌─────────────────────────────────────────┐                │
│  │  .flutter_control/                       │                │
│  │    ├── status.json     (read by agent)   │                │
│  │    ├── command.json    (written by agent)│◄──────────────┤
│  │    ├── response.json   (read by agent)   │               │
│  │    ├── output.log      (Flutter output)  │               │
│  │    └── ready.flag      (ready indicator) │               │
│  └─────────────────────────────────────────┘                │
│                       ▲                                      │
└───────────────────────┼──────────────────────────────────────┘
                        │
┌───────────────────────┼──────────────────────────────────────┐
│                       │     SEPARATE POWERSHELL WINDOW       │
│                       ▼                                      │
│  ┌─────────────────────────────────────────┐                │
│  │  flutter_agent.py run lib/main.dart     │                │
│  │           │                              │                │
│  │           ▼                              │                │
│  │  ┌───────────────────┐                  │                │
│  │  │  flutter run ...  │                  │                │
│  │  │     (subprocess)  │                  │                │
│  │  └───────────────────┘                  │                │
│  └─────────────────────────────────────────┘                │
│                                                              │
│  Monitors command.json and writes to Flutter's stdin        │
└──────────────────────────────────────────────────────────────┘
```

### File-Based IPC

1. **status.json**: Current state (starting, running, ready, stopped, error)
2. **command.json**: Commands from agent (written by agent, read by runner)
3. **response.json**: Acknowledgments (written by runner, read by agent)
4. **output.log**: Complete Flutter output (for debugging)
5. **ready.flag**: Simple file existence check for "is ready?"

---

## Example Workflow

### Complete Integration Test Workflow

```powershell
# 1. Navigate to project
cd "E:\my-flutter-project"

# 2. Start Flutter in separate window
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd 'E:\my-flutter-project'; python tools/flutter_agent/flutter_agent.py run lib/main.dart -d chrome"

# 3. Wait for app to be ready
python tools/flutter_agent/flutter_agent.py wait --timeout 30

# 4. App is running! Now interact:
python tools/flutter_agent/flutter_agent.py screenshot
python tools/flutter_agent/flutter_agent.py reload

# 5. Check status anytime
python tools/flutter_agent/flutter_agent.py status

# 6. Read output if needed
python tools/flutter_agent/flutter_agent.py output --tail 20

# 7. When done
python tools/flutter_agent/flutter_agent.py stop
```

### Visual Verification Workflow

```powershell
# Start app
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd '<path>'; python tools/flutter_agent/flutter_agent.py run lib/test_app.dart -d chrome"

# Wait and take screenshot
python tools/flutter_agent/flutter_agent.py wait --timeout 30
python tools/flutter_agent/flutter_agent.py screenshot

# Screenshot saved to: build/screenshots/flutter_01.png
# Agent can verify file exists:
Test-Path "build/screenshots/flutter_01.png"

# Or use Chrome DevTools MCP to view:
# 1. Open file:///path/to/screenshot.png
# 2. Take snapshot for analysis
```

---

## Troubleshooting

### "Flutter is not running"

```powershell
# Check status
python tools/flutter_agent/flutter_agent.py status

# Clean and restart
python tools/flutter_agent/flutter_agent.py clean
# Then start again with Start-Process
```

### "Timeout waiting for Flutter"

- Increase timeout: `python tools/flutter_agent/flutter_agent.py wait --timeout 60`
- Check output: `python tools/flutter_agent/flutter_agent.py output`
- Make sure the target file exists

### Process still running from previous session

```powershell
# Check for orphaned processes
Get-Process -Name "flutter*" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "dart*" -ErrorAction SilentlyContinue | Stop-Process -Force

# Clean control files
python tools/flutter_agent/flutter_agent.py clean
```

---

## Why This Works

1. **Start-Process** launches a completely independent PowerShell window
2. The Flutter process runs in THAT window, not the agent's terminal
3. Communication happens via **files**, not terminal input
4. Agent can read/write files without affecting the running process
5. No terminal conflicts, no process killing!

---

## For Copilot Instructions

Add this to your `.github/copilot-instructions.md`:

```markdown
## Flutter Integration Testing

**CRITICAL**: Use the Flutter Agent Controller for running and interacting with Flutter apps.

### Starting Flutter
```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd '<working_dir>'; python tools/flutter_agent/flutter_agent.py run <target> -d chrome"
```

### Waiting for Ready
```powershell
python tools/flutter_agent/flutter_agent.py wait --timeout 30
```

### Commands
```powershell
python tools/flutter_agent/flutter_agent.py screenshot  # take screenshot
python tools/flutter_agent/flutter_agent.py reload      # hot reload
python tools/flutter_agent/flutter_agent.py stop        # quit
```

### NEVER use `run_in_terminal` to send commands to a running Flutter process!
```

---

## Version History

- **v1.0.0** (2025-11-28): Initial release - solved the terminal interaction problem!
