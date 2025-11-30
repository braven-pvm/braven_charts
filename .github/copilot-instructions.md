# braven_charts_v2.0 Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-04

## Active Technologies

- Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216 + Standard Dart libraries only (dart:core, dart:math, dart:ui) - NO external packages (011-multi-axis-normalization)

- Dart 3.0+ (3.10.0-227.0.dev), Flutter SDK 3.37.0-1.0.pre-216 + Standard Dart libraries only (dart:core, dart:math, dart:collection) - NO external packages (001-foundation)
- [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION] + [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION] (001-foundation)
- [if applicable, e.g., PostgreSQL, CoreData, files or N/A] (001-foundation)
- Dart 3.10.0-227.0.dev + Flutter SDK 3.37.0-1.0.pre-216, Standard Dart libraries (dart:ui, dart:math for bezier/interpolation) (005-chart-types)
- N/A (stateless rendering, data provided by caller) (005-chart-types)
- Dart 3.10.0-227.0.dev + Flutter SDK 3.37.0-1.0.pre-216, Standard Dart libraries (dart:ui for widgets, dart:async for streams) (006-chart-widgets)
- N/A (stateless widget with external data sources) (006-chart-widgets)
- Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216 + Standard Dart libraries only (dart:core, dart:async for Timer, dart:ui for rendering) (009-dual-mode-streaming)

## Project Structure

```
src/
tests/
```

## Commands

# Add commands for Dart 3.0+ (3.10.0-227.0.dev), Flutter SDK 3.37.0-1.0.pre-216

## Code Style

Dart 3.0+ (3.10.0-227.0.dev), Flutter SDK 3.37.0-1.0.pre-216: Follow standard conventions

## Recent Changes

- 011-multi-axis-normalization: Added Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216 + Standard Dart libraries only (dart:core, dart:math, dart:ui) - NO external packages

- 009-dual-mode-streaming: Added Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216 + Standard Dart libraries only (dart:core, dart:async for Timer, dart:ui for rendering)
- 006-chart-widgets: Added Dart 3.10.0-227.0.dev + Flutter SDK 3.37.0-1.0.pre-216, Standard Dart libraries (dart:ui for widgets, dart:async for streams)

<!-- MANUAL ADDITIONS START -->

## 🚨 ORCHESTRATOR SCRIPT-FIRST PROTOCOL (ABSOLUTE PRIORITY) 🚨

### ⛔ BEFORE ANY TASK PREPARATION - MANDATORY FIRST ACTION

When user says "prepare next task", "task handover", or similar:

**DO NOT:**
- ❌ Read manifest.yaml
- ❌ Read templates
- ❌ Read SpecKit tasks.md
- ❌ Start planning or analysis
- ❌ Create todo lists

**MUST DO FIRST:**
```powershell
# Step 1: Source environment
. .\.orchestra\scripts\set-env.ps1

# Step 2: Run closeout check (BLOCKING)
.\.orchestra\scripts\orchestrator\task-closeout-check.ps1
```

**ONLY AFTER SCRIPT PASSES** can you proceed to:
1. Read readme.md
2. Read manifest.yaml for next task
3. Create handover document

**WHY THIS EXISTS**: Agents repeatedly skip to reading files instead of running validation scripts. This causes missed verification steps and process drift. The script MUST be the entry point.

---

## Terminal Management Protocol (CRITICAL - MANDATORY ENFORCEMENT)

### 🎯 ABSOLUTE RULES - ZERO TOLERANCE

**NEVER use `run_in_terminal` - ALWAYS use `terminal-tools_sendCommand` with named terminals**

### Terminal Naming Convention

**LONG-RUNNING TERMINALS** (LOCKED - Never reuse for other commands):

- `flutter-run` - Flutter app execution (DO NOT send other commands here!)
- `dev-server` - Development servers (npm, python, cargo)
- `test-watch` - Test runners in watch mode
- `docker-compose` - Container services
- `database` - Database servers/clients

**SHORT-LIVED TERMINALS** (Reusable after command completes):

- `git` - Version control operations
- `package-manager` - Dependency management (pub get, npm install, pip install)
- `build` - One-shot build operations
- `test` - One-shot test execution
- `general` - File operations, utilities
- `scripts` - Custom scripts/automation
- `cloud` - Cloud CLI commands

### Critical Flutter Rules

1. **Starting Flutter app (with output capture):**

   ```typescript
   terminal-tools_sendCommand(
     terminalName: "flutter-run",
     command: "(Remove-Item 'flutter_output.log' -ErrorAction SilentlyContinue) ; flutter run -d chrome -t lib/main.dart 2>&1 | Tee-Object -FilePath 'flutter_output.log'",
     workingDirectory: "E:\\path\\to\\project\\example"
   )
   // Terminal is now LOCKED - use other terminals for git/test/etc
   // Output captured to flutter_output.log (readable with read_file tool)
   ```

2. **Hot reload (WORKING - USE THIS!):**

   ```typescript
   // Send single character 'r' for hot reload
   terminal-tools_sendCommand(terminalName: "flutter-run", command: "r")

   // OR 'R' for hot restart
   terminal-tools_sendCommand(terminalName: "flutter-run", command: "R")
   ```

   **CRITICAL:** Send ONLY single characters ("r", "R", "q", "c") - NO newlines (\n) or multi-character strings!
   **✅ WORKS:** `command: "r"` (single char)
   **❌ KILLS APP:** `command: "r\n"` (with newline) or `command: "reload"` (multi-char)

3. **Git/Test/Build while app running:**

   ```typescript
   // Use SEPARATE terminals - app keeps running
   terminal-tools_sendCommand(terminalName: "git", command: "git status")
   terminal-tools_sendCommand(terminalName: "test", command: "flutter test ...")
   terminal-tools_sendCommand(terminalName: "build", command: "flutter build ...")
   ```

4. **Reading terminal output from long-running processes:**

   ```typescript
   // Start process with output redirection to log file
   terminal-tools_sendCommand(
     terminalName: "flutter-run",
     command: "(Remove-Item 'flutter_output.log' -ErrorAction SilentlyContinue) ; flutter run ... 2>&1 | Tee-Object -FilePath 'flutter_output.log'"
   )

   // Later, read the output anytime
   read_file(filePath: "path/to/flutter_output.log")

   // Log file persists and grows - delete before restart to clear old output
   ```

5. **Installing packages while app running:**

   ```typescript
   terminal-tools_sendCommand(
     terminalName: "package-manager",
     command: "flutter pub get"
   )
   // App keeps running but must restart to use new packages
   ```

6. **Interactive Flutter commands (hot reload, clear screen, etc.):**

   ```typescript
   // Hot reload after code changes
   terminal-tools_sendCommand(terminalName: "flutter-run", command: "r")

   // Hot restart (full app restart)
   terminal-tools_sendCommand(terminalName: "flutter-run", command: "R")

   // Clear terminal screen
   terminal-tools_sendCommand(terminalName: "flutter-run", command: "c")

   // Show help menu
   terminal-tools_sendCommand(terminalName: "flutter-run", command: "h")

   // CRITICAL: Single characters ONLY - no newlines or multi-char strings!
   ```

### **Pre-Command Checklist**

Before EVERY terminal command:

1. ✅ Am I using `terminal-tools_sendCommand` (NOT `run_in_terminal`)?
2. ✅ Is the terminal name explicit and category-appropriate?
3. ✅ If targeting locked terminal (flutter-run), is it an interactive single-char command (r, R, c, h, q)?
4. ✅ For hot reload, am I sending single character "r" (NOT "r\n" or multi-char strings)?
5. ✅ For long-running processes, am I capturing output with `Tee-Object` so I can read it later?

### Common Mistakes to AVOID

❌ `run_in_terminal("git status")` - Uses last terminal, kills app
❌ `terminal-tools_sendCommand(terminalName: "flutter-run", command: "git status")` - Kills app
❌ `terminal-tools_sendCommand(terminalName: "flutter-run", command: "r\n")` - Kills app (newline)
❌ `terminal-tools_sendCommand(terminalName: "flutter-run", command: "reload")` - Kills app (multi-char)
✅ `terminal-tools_sendCommand(terminalName: "flutter-run", command: "r")` - Hot reload works!
✅ `terminal-tools_sendCommand(terminalName: "git", command: "git status")` - CORRECT

### Reference Documentation

See comprehensive guides:

- `.github/TERMINAL_WORKFLOW_GUIDELINES.md` - Full workflow documentation
- `.github/TERMINAL_QUICK_REFERENCE.md` - Quick reference card
- `.github/SYSTEM_PROMPT_TERMINAL_MANAGEMENT.md` - System prompt additions

---

## ⛔ VISUAL VERIFICATION: flutter_agent.py ONLY (CRITICAL)

### 🚫 ABSOLUTE PROHIBITIONS FOR VISUAL/SCREENSHOT VERIFICATION

**NEVER use these for visual verification:**

- ❌ `flutter run` directly in any terminal
- ❌ `terminal-tools_sendCommand` with `flutter run`
- ❌ `run_in_terminal` with `flutter run`
- ❌ Chrome DevTools MCP tools for screenshots
- ❌ Background processes (`isBackground: true`)

**WHY THESE FAIL:**

- AI agents CANNOT see terminal visual output
- AI agents CANNOT interact with Chrome windows spawned by `flutter run`
- Chrome DevTools MCP requires a running Chrome instance we can connect to
- Background processes orphan the Flutter app with no way to stop it

### ✅ MANDATORY: Use flutter_agent.py for ALL Visual Verification

The ONLY approved method for running Flutter apps and taking screenshots:

```powershell
# Location: tools/flutter_agent/flutter_agent.py

# 1. START app in SEPARATE PowerShell window (CRITICAL!)
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'E:\path\to\project\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_NNN_demo.dart -d chrome"

# 2. WAIT for app ready (in agent terminal)
python tools/flutter_agent/flutter_agent.py wait --timeout 60

# 3. TAKE SCREENSHOT
python tools/flutter_agent/flutter_agent.py screenshot --output screenshots/task_NNN_verification.png

# 4. VERIFY screenshot exists
Test-Path screenshots/task_NNN_verification.png

# 5. STOP app when done
python tools/flutter_agent/flutter_agent.py stop
```

### flutter_agent.py Command Reference

| Command                      | Description        |
| ---------------------------- | ------------------ |
| `run <target> -d <device>`   | Start Flutter app  |
| `wait --timeout <secs>`      | Wait for app ready |
| `screenshot --output <path>` | Capture screenshot |
| `reload`                     | Hot reload         |
| `restart`                    | Hot restart        |
| `stop`                       | Stop the app       |
| `status`                     | Check app status   |

### Key Differences: Terminal vs flutter_agent.py

| Aspect              | Terminal Commands       | flutter_agent.py                 |
| ------------------- | ----------------------- | -------------------------------- |
| **Use For**         | Tests, builds, git, pub | Visual verification, screenshots |
| **Can See Output?** | No (text only)          | Yes (via screenshot)             |
| **Screenshot?**     | ❌ Impossible           | ✅ Built-in                      |
| **Stop App?**       | Unreliable              | ✅ `stop` command                |
| **Hot Reload?**     | Problematic             | ✅ `reload` command              |

### Pre-Visual-Verification Checklist

Before ANY visual verification:

1. ✅ Am I using `flutter_agent.py`? (NOT terminal commands)
2. ✅ Am I starting in a SEPARATE window via `Start-Process`?
3. ✅ Did I wait for the app to be ready?
4. ✅ Did I take a screenshot?
5. ✅ Did I verify the screenshot file exists?
6. ✅ Did I stop the app when done?

### Common Mistakes to AVOID for Visual Verification

❌ `flutter run -d chrome` in terminal - Agent cannot see output
❌ `isBackground: true` with flutter run - Orphans the process
❌ Chrome DevTools MCP screenshot - Cannot connect to our Chrome
❌ Skipping screenshot and claiming "it works" - UNVERIFIABLE
✅ `Start-Process ... flutter_agent.py run ...` - CORRECT

<!-- MANUAL ADDITIONS END -->
