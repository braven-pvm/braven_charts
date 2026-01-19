# Terminal Workflow Guidelines for AI Coding Agents

## 🎯 Core Principle: **Dedicated Named Terminals for Isolated Execution**

This document defines the **MANDATORY** terminal management workflow to prevent process conflicts, interruptions, and chaos when executing shell commands.

---

## 📋 Terminal Categories & Naming Convention

### **1. LONG-RUNNING PROCESS TERMINALS** (Never reuse for other commands)

| Terminal Name | Purpose | Typical Commands | Lifecycle |
|--------------|---------|------------------|-----------|
| `flutter-run` | Running Flutter app (debug/profile/release) | `flutter run`, `flutter run -d chrome`, `flutter run -d windows` | Remains open until app explicitly stopped |
| `dev-server` | Development servers (any language) | `npm run dev`, `python manage.py runserver`, `cargo run --bin server` | Remains open until server explicitly stopped |
| `test-watch` | Test runners in watch mode | `npm test --watch`, `pytest --watch`, `cargo test --watch` | Remains open until watch mode exited |
| `docker-compose` | Docker containers/services | `docker-compose up`, `docker run -it` | Remains open until containers stopped |
| `database` | Database servers/clients | `mongod`, `redis-server`, `psql` interactive | Remains open until database stopped |

**CRITICAL RULE**: Once a long-running process starts in these terminals, they are **LOCKED** for that process. Any subsequent commands (git, file operations, etc.) MUST use different terminals.

---

### **2. SHORT-LIVED COMMAND TERMINALS** (Reusable within category)

| Terminal Name | Purpose | Typical Commands | Lifecycle |
|--------------|---------|------------------|-----------|
| `git` | Version control operations | `git status`, `git commit`, `git push`, `git checkout` | Command completes, terminal available for next git command |
| `package-manager` | Dependency management | `flutter pub get`, `npm install`, `pip install`, `cargo add` | Command completes, terminal available |
| `build` | Build operations (non-watch) | `flutter build web`, `npm run build`, `cargo build --release` | Command completes, terminal available |
| `test` | One-shot test execution | `flutter test`, `npm test`, `pytest`, `cargo test` | Command completes, terminal available |
| `general` | File operations, utilities | `ls`, `cat`, `grep`, `find`, `Remove-Item`, `Move-Item` | Command completes, terminal available |
| `scripts` | Custom scripts/automation | `python script.py`, `bash deploy.sh`, PowerShell scripts | Command completes, terminal available |
| `cloud` | Cloud CLI commands | `aws`, `gcloud`, `az`, `terraform` | Command completes, terminal available |

**REUSE RULE**: These terminals can be reused for commands within the same category after the previous command completes.

---

### **3. INTERACTIVE COMMUNICATION TERMINALS** (Special handling required)

| Terminal Name | Purpose | Communication Method | Critical Rules |
|--------------|---------|---------------------|----------------|
| `flutter-run` | Send hotkeys to running Flutter app | Send single character commands: `r` (hot reload), `R` (hot restart), `q` (quit) | ⚠️ **NEVER send multi-character commands** - will kill the app. Only send `r`, `R`, `q` after confirming app is running |
| `dev-server` | Send signals to servers | Send `Ctrl+C` to stop gracefully | Check server is running before sending signals |

---

## 🔥 CRITICAL RULES - ABSOLUTE ENFORCEMENT

### **Rule 1: Always Use Named Terminals**
```typescript
// ❌ WRONG - Uses last active terminal, causes chaos
run_in_terminal("git status")

// ✅ CORRECT - Uses dedicated named terminal
terminal-tools_sendCommand(terminalName: "git", command: "git status")
```

### **Rule 2: Check Terminal State Before Sending Commands**
```typescript
// ✅ CORRECT - List terminals first to see what's running
terminal-tools_listTerminals()

// Then make informed decision about which terminal to use
```

### **Rule 3: Never Reuse Long-Running Process Terminals**
```typescript
// ❌ WRONG - Kills the running Flutter app
terminal-tools_sendCommand(terminalName: "flutter-run", command: "git status")

// ✅ CORRECT - Use dedicated git terminal
terminal-tools_sendCommand(terminalName: "git", command: "git status")

// ✅ BUT INTERACTIVE COMMANDS WORK!
terminal-tools_sendCommand(terminalName: "flutter-run", command: "r") // Hot reload!
```

### **Rule 4: Hot Reload Works with Single Characters!**
```typescript
// ✅ WORKS - Send single character for hot reload
terminal-tools_sendCommand(terminalName: "flutter-run", command: "r")

// ✅ WORKS - Send single character for hot restart  
terminal-tools_sendCommand(terminalName: "flutter-run", command: "R")

// ❌ KILLS APP - Adding newline
terminal-tools_sendCommand(terminalName: "flutter-run", command: "r\n")

// ❌ KILLS APP - Multi-character string
terminal-tools_sendCommand(terminalName: "flutter-run", command: "reload")
```

**Available Interactive Commands:**
- `"r"` - Hot reload (apply code changes)
- `"R"` - Hot restart (full restart)
- `"c"` - Clear terminal screen
- `"h"` - Show help menu
- `"q"` - Quit application

---

## 🔥 Interactive Flutter Commands

**BREAKTHROUGH:** Single-character commands work perfectly for Flutter's interactive mode!

**How It Works:**
- Flutter CLI runs in interactive mode, listening for single keypresses
- `terminal-tools_sendCommand` can send these single characters to stdin
- Characters are interpreted as keypresses, triggering Flutter's interactive handlers
- This enables hot reload without restarting the app!

**Usage Pattern:**
```typescript
// 1. Start Flutter app with output capture
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "(Remove-Item 'flutter_output.log' -ErrorAction SilentlyContinue) ; flutter run -d chrome -t lib/main.dart 2>&1 | Tee-Object -FilePath 'flutter_output.log'",
  workingDirectory: "path/to/example"
)

// 2. Make code changes in your editor

// 3. Hot reload to see changes instantly!
terminal-tools_sendCommand(terminalName: "flutter-run", command: "r")

// 4. Check output to verify reload
read_file(filePath: "path/to/flutter_output.log")
```

**Why This Is Game-Changing:**
- ✅ No need to stop and restart app
- ✅ Preserves app state during reload
- ✅ Faster development workflow
- ✅ Matches developer expectations from manual terminal use
- ✅ Works within the named terminal protocol

**Critical Success Factors:**
- Must send ONLY single character
- NO newlines (`\n`)
- NO multi-character strings
- Terminal must have running Flutter process in interactive mode

### **Rule 5: Hot Reload Legacy Pattern (Deprecated)**
```typescript
// ❌ WRONG - Sending multi-character commands kills the app
terminal-tools_sendCommand(terminalName: "flutter-run", command: "r\n")

// ✅ CORRECT - Send ONLY single character 'r' without newline (if tool supports)
// OR use Flutter DevTools hot reload API
// OR stop app, make changes, restart app in same terminal

// SAFEST APPROACH - Explicit restart:
terminal-tools_sendCommand(terminalName: "flutter-run", command: "q") // quit
// Wait for process to exit
terminal-tools_sendCommand(terminalName: "flutter-run", command: "flutter run -d chrome")
```

### **Rule 5: Create Terminal If Doesn't Exist**
```typescript
// ✅ CORRECT - terminal-tools_sendCommand auto-creates if missing
terminal-tools_sendCommand(
  terminalName: "git",
  command: "git status",
  workingDirectory: "/path/to/repo"
)
```

---

## 📊 Decision Flow Chart

```
New command to execute?
    │
    ├─→ Is it long-running (server, app, watch mode)?
    │   ├─→ YES: Use/create dedicated terminal (flutter-run, dev-server, etc.)
    │   │         Mark terminal as LOCKED
    │   └─→ NO: Continue ↓
    │
    ├─→ Is it interacting with existing process (hot reload, quit)?
    │   ├─→ YES: Verify process is running in target terminal
    │   │         Send ONLY single-character command (r, R, q)
    │   └─→ NO: Continue ↓
    │
    └─→ Is it short-lived command?
        └─→ Use category-specific terminal (git, package-manager, build, test, general)
            Reuse terminal within category after command completes
```

---

## 🛠️ Tool Usage Patterns

### **Starting Flutter App (Long-Running)**
```typescript
// Create dedicated terminal and start app
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "flutter run -d chrome -t lib/main.dart",
  workingDirectory: "E:\\path\\to\\project\\example",
  captureOutput: false  // Let output stream to terminal for debugging
)

// Terminal "flutter-run" is now LOCKED - don't send other commands to it
```

### **Running Git Commands (While App Running)**
```typescript
// Use separate git terminal - app keeps running
terminal-tools_sendCommand(
  terminalName: "git",
  command: "git status",
  workingDirectory: "E:\\path\\to\\project"
)

terminal-tools_sendCommand(
  terminalName: "git",
  command: "git add .",
  workingDirectory: "E:\\path\\to\\project"
)
```

### **Installing Packages (While App Running)**
```typescript
// Use separate package-manager terminal
terminal-tools_sendCommand(
  terminalName: "package-manager",
  command: "flutter pub get",
  workingDirectory: "E:\\path\\to\\project"
)
```

### **Building App (Separate from Running App)**
```typescript
// Use dedicated build terminal
terminal-tools_sendCommand(
  terminalName: "build",
  command: "flutter build web --release",
  workingDirectory: "E:\\path\\to\\project"
)
```

### **Hot Reload Flutter App (SAFEST METHOD)**
```typescript
// Option 1: Restart app (safest, always works)
terminal-tools_cancelCommand(terminalName: "flutter-run")  // Send Ctrl+C
// Wait 2 seconds for graceful shutdown
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "flutter run -d chrome -t lib/main.dart",
  workingDirectory: "E:\\path\\to\\project\\example"
)

// Option 2: Use Flutter save-triggered hot reload (if IDE supports)
// Just save the file - Flutter watches file changes and auto-reloads

// Option 3: Single character 'r' (RISKY - may not work with sendCommand)
// NOT RECOMMENDED - tool may append newline which kills app
```

### **Stopping Long-Running Process**
```typescript
// Send cancel signal (Ctrl+C)
terminal-tools_cancelCommand(terminalName: "flutter-run")

// Or send quit command if supported
terminal-tools_sendCommand(terminalName: "flutter-run", command: "q")

// Then delete terminal if no longer needed
terminal-tools_deleteTerminal(name: "flutter-run")
```

---

## 🎯 Example Workflow: Flutter Development Session

```typescript
// 1. Start Flutter app in dedicated terminal
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "flutter run -d chrome -t lib/braven_chart_plus_feature_showcase.dart | Tee-Object -FilePath 'flutter_run.log'",
  workingDirectory: "E:\\cloud services\\Dropbox\\Repositories\\Flutter\\braven_charts_v2.0\\example",
  captureOutput: false
)
// ✅ App running, terminal LOCKED

// 2. Make code changes in editor (via edit tools)
replace_string_in_file(...)

// 3. Hot reload - SAFEST: Just save file, Flutter auto-reloads
// Or if manual reload needed:
terminal-tools_cancelCommand(terminalName: "flutter-run")
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "flutter run -d chrome -t lib/braven_chart_plus_feature_showcase.dart",
  workingDirectory: "E:\\cloud services\\Dropbox\\Repositories\\Flutter\\braven_charts_v2.0\\example"
)

// 4. Run tests in separate terminal (app still running)
terminal-tools_sendCommand(
  terminalName: "test",
  command: "flutter test test/unit/rendering/chart_render_box_test.dart",
  workingDirectory: "E:\\cloud services\\Dropbox\\Repositories\\Flutter\\braven_charts_v2.0"
)
// ✅ Tests run, app unaffected

// 5. Commit changes (app still running)
terminal-tools_sendCommand(
  terminalName: "git",
  command: "git add lib/src_plus/rendering/chart_render_box.dart"
)

terminal-tools_sendCommand(
  terminalName: "git",
  command: 'git commit -m "Fix: Implement scrollbar interaction throttling"'
)
// ✅ Git operations complete, app still running

// 6. Install new package (app still running)
terminal-tools_sendCommand(
  terminalName: "package-manager",
  command: "flutter pub add intl",
  workingDirectory: "E:\\cloud services\\Dropbox\\Repositories\\Flutter\\braven_charts_v2.0"
)
// ✅ Package installed, must restart app to use it

// 7. Stop app when done
terminal-tools_cancelCommand(terminalName: "flutter-run")
terminal-tools_deleteTerminal(name: "flutter-run")
```

---

## 📤 Terminal Output Capture

### The Challenge

Named terminals provide perfect process isolation, but the `terminal-tools_sendCommand` tool cannot directly read terminal output. The `captureOutput` parameter exists but provides no retrieval mechanism for AI agents.

### The Solution: PowerShell Output Redirection

Use PowerShell's `Tee-Object` cmdlet to redirect output to a log file while maintaining terminal display:

```powershell
(Remove-Item 'logfile.log' -ErrorAction SilentlyContinue) ; command 2>&1 | Tee-Object -FilePath 'logfile.log'
```

**How it works:**
- `Remove-Item` deletes old log file (prevents appending to previous runs)
- `-ErrorAction SilentlyContinue` suppresses error if log doesn't exist
- `2>&1` redirects stderr to stdout (captures all output)
- `Tee-Object` writes to file AND displays in terminal
- AI can read log file anytime with `read_file` tool

### Flutter App Example

```typescript
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "(Remove-Item 'flutter_output.log' -ErrorAction SilentlyContinue) ; flutter run -d chrome -t lib/main.dart 2>&1 | Tee-Object -FilePath 'flutter_output.log'",
  workingDirectory: "E:\\path\\to\\example"
)

// Later, read the output anytime
read_file(filePath: "E:\\path\\to\\example\\flutter_output.log")
```

### Dev Server Example

```typescript
terminal-tools_sendCommand(
  terminalName: "dev-server",
  command: "(Remove-Item 'server.log' -ErrorAction SilentlyContinue) ; npm run dev 2>&1 | Tee-Object -FilePath 'server.log'",
  workingDirectory: "E:\\path\\to\\project"
)
```

### Test Watch Example

```typescript
terminal-tools_sendCommand(
  terminalName: "test-watch",
  command: "(Remove-Item 'test.log' -ErrorAction SilentlyContinue) ; pytest --watch 2>&1 | Tee-Object -FilePath 'test.log'",
  workingDirectory: "E:\\path\\to\\project"
)
```

### Important Notes

1. **Log File Persistence**: Log files persist after process ends and will append on next run if not deleted first
2. **Always Delete First**: Use `Remove-Item` prefix before starting to clear old output
3. **Error Handling**: `-ErrorAction SilentlyContinue` prevents errors if log doesn't exist yet
4. **Real-Time Reading**: Read log file anytime while process is running to see latest output
5. **Multiple Reads**: Can read log file repeatedly to monitor new output as it arrives
6. **Path Considerations**: Use relative paths for log files or specify full absolute paths

### Pattern Template

```powershell
(Remove-Item '<logfile>' -ErrorAction SilentlyContinue) ; <command> 2>&1 | Tee-Object -FilePath '<logfile>'
```

**This solves both requirements:**
- ✅ Process isolation (named terminals prevent killing)
- ✅ Output visibility (log files readable by AI)

---

## ⚠️ Common Mistakes to Avoid

| ❌ WRONG | ✅ CORRECT | Why |
|----------|-----------|-----|
| `run_in_terminal("git status")` | `terminal-tools_sendCommand(terminalName: "git", command: "git status")` | run_in_terminal uses last active terminal, may kill running app |
| `terminal-tools_sendCommand(terminalName: "flutter-run", command: "git status")` | Use separate `git` terminal | Kills the running Flutter app |
| `terminal-tools_sendCommand(terminalName: "flutter-run", command: "r\n")` | Restart app or use file-save hot reload | Sending multi-char commands kills app |
| Reusing terminal names randomly | Consistent category-based naming | Prevents accidental process conflicts |
| Not checking terminal state before sending commands | `terminal-tools_listTerminals()` first | Ensures awareness of what's running |

---

## 🚀 Performance Benefits

1. **Zero Process Conflicts**: Long-running processes isolated from short commands
2. **Debugging Visibility**: Each terminal shows relevant output (Flutter logs, git output, etc.)
3. **Developer Sanity**: Predictable, consistent behavior across all operations
4. **Parallel Execution**: Multiple terminals can run simultaneously without conflicts

---

## 📝 Summary Checklist

Before executing ANY terminal command:

- [ ] ✅ Determine command category (long-running vs short-lived)
- [ ] ✅ Choose appropriate named terminal from convention table
- [ ] ✅ Use `terminal-tools_sendCommand` (NOT `run_in_terminal`)
- [ ] ✅ Verify terminal is not locked by long-running process
- [ ] ✅ For hot reload, use safest method (restart or file-save)
- [ ] ✅ List terminals periodically to track running processes

---

**Last Updated**: 2025-11-19  
**Version**: 1.0.0  
**Status**: ✅ MANDATORY ENFORCEMENT
