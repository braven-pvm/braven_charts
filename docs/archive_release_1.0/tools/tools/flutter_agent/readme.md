# 🚀 Flutter Agent Controller

**A bulletproof solution for AI agents to run and interact with Flutter apps.**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)]()
[![Python](https://img.shields.io/badge/python-3.8+-green.svg)]()
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)]()

## The Problem

AI coding agents (like GitHub Copilot, Claude, etc.) struggle with Flutter integration testing because:

1. They run `flutter run` in a terminal
2. When they send subsequent commands, `run_in_terminal` goes to the **same terminal**
3. This **kills the Flutter process**

## The Solution

Use `Start-Process` to launch Flutter in a **completely separate PowerShell window**, then communicate via **file-based IPC** (inter-process communication).

```
┌─────────────────────────┐      ┌─────────────────────────┐
│    AGENT'S TERMINAL     │      │   SEPARATE WINDOW       │
│                         │      │                         │
│  python ... cmd s  ─────┼──────►  flutter_agent.py run   │
│                         │ IPC  │        │                │
│  ◄──────────────────────┼──────┤        ▼                │
│  "Screenshot taken!"    │      │   flutter run ...       │
└─────────────────────────┘      └─────────────────────────┘
```

## Quick Start

### 1. Start Flutter (in separate window)

```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd '<project_dir>'; python tools/flutter_agent/flutter_agent.py run lib/main.dart -d chrome"
```

### 2. Wait for Ready

```powershell
python tools/flutter_agent/flutter_agent.py wait --timeout 30
```

### 3. Interact

```powershell
python tools/flutter_agent/flutter_agent.py screenshot  # Take screenshot
python tools/flutter_agent/flutter_agent.py reload      # Hot reload
python tools/flutter_agent/flutter_agent.py restart     # Hot restart
python tools/flutter_agent/flutter_agent.py cmd h       # Any Flutter command
```

### 4. Check Status & Output

```powershell
python tools/flutter_agent/flutter_agent.py status
python tools/flutter_agent/flutter_agent.py output --tail 20
```

### 5. Stop

```powershell
python tools/flutter_agent/flutter_agent.py stop
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `run <target> -d <device>` | Start Flutter app (use with Start-Process) |
| `wait [--timeout N]` | Wait for Flutter to be ready (default: 30s) |
| `status` | Show current Flutter status as JSON |
| `cmd <key>` | Send any single-key command to Flutter |
| `screenshot` | Take a screenshot (alias for `cmd s`) |
| `reload` | Hot reload (alias for `cmd r`) |
| `restart` | Hot restart (alias for `cmd R`) |
| `stop` | Stop Flutter gracefully (sends `q`) |
| `output [--tail N]` | Show Flutter output log |
| `clean` | Clean all control files |
| `generate <target>` | Generate Start-Process command to copy |

## Flutter Interactive Keys

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `s` | Screenshot |
| `q` | Quit |
| `h` | Help |
| `c` | Clear terminal |
| `d` | Detach |
| `p` | Performance overlay |
| `I` | Widget inspector |
| `t` | Dump widget tree |

## File Structure

```
tools/flutter_agent/
├── readme.md                 # This file
├── flutter_agent_guide.md    # Detailed usage guide
├── flutter_agent.py          # Main controller script
└── .flutter_control/         # IPC directory (auto-created)
    ├── status.json           # Current status
    ├── command.json          # Pending command
    ├── response.json         # Command response
    ├── output.log            # Flutter stdout
    └── ready.flag            # Ready indicator
```

## Example: Integration Test Workflow

```powershell
# 1. Start app
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'E:\my-project\example'; python ../tools/flutter_agent/flutter_agent.py run lib/main.dart -d chrome"

# 2. Wait for ready
python tools/flutter_agent/flutter_agent.py wait --timeout 30

# 3. Take screenshot for visual verification
python tools/flutter_agent/flutter_agent.py screenshot

# 4. Verify screenshot exists
Test-Path "example/flutter_01.png"

# 5. Make code changes, then hot reload
python tools/flutter_agent/flutter_agent.py reload

# 6. Take another screenshot
python tools/flutter_agent/flutter_agent.py screenshot

# 7. Done - stop the app
python tools/flutter_agent/flutter_agent.py stop
```

## For Copilot Instructions

Add this to your project's `.github/copilot-instructions.md`:

```markdown
## Flutter Agent Controller

Use the Flutter Agent Controller for running and interacting with Flutter apps:

### Starting Flutter (MUST use Start-Process!)
\`\`\`powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd '<working_dir>'; python tools/flutter_agent/flutter_agent.py run <target> -d chrome"
\`\`\`

### Waiting & Interacting
\`\`\`powershell
python tools/flutter_agent/flutter_agent.py wait --timeout 30
python tools/flutter_agent/flutter_agent.py screenshot
python tools/flutter_agent/flutter_agent.py reload
python tools/flutter_agent/flutter_agent.py stop
\`\`\`

### NEVER use run_in_terminal to send commands to a running Flutter process!
```

## Troubleshooting

### "Flutter is not running"

```powershell
python tools/flutter_agent/flutter_agent.py status  # Check status
python tools/flutter_agent/flutter_agent.py clean   # Clean and retry
```

### Orphaned processes

```powershell
Get-Process -Name "flutter*", "dart*" -ErrorAction SilentlyContinue | Stop-Process -Force
python tools/flutter_agent/flutter_agent.py clean
```

### Timeout waiting

- Increase timeout: `--timeout 60`
- Check output: `python tools/flutter_agent/flutter_agent.py output`
- Ensure target file exists

## Requirements

- Python 3.8+
- Windows PowerShell
- Flutter SDK in PATH

## License

MIT - Part of the braven_charts project.

## Version History

- **1.0.0** (2025-11-28): Initial release - solved the terminal interaction problem!
