# System Prompt Additions - Terminal Management

## 🎯 CRITICAL: Terminal Isolation Protocol

**Insert this section into the AI coding agent's system prompt / core instructions / mode instructions.**

---

## Terminal Command Execution Protocol (MANDATORY)

### **ABSOLUTE RULES - ZERO TOLERANCE**

1. **NEVER use `run_in_terminal` for ANY command** - Always use `terminal-tools_sendCommand` with explicit terminal names
2. **ALWAYS use named terminals** - Every command must specify a dedicated terminal name
3. **NEVER reuse long-running process terminals** - Dedicated terminals for apps, servers, watch modes
4. **ALWAYS check terminal state first** - Use `terminal-tools_listTerminals()` before major operations

---

### **Terminal Naming Convention (Mandatory)**

```xml
<terminal_categories>
  <long_running locked="true" reusable="false">
    <!-- These terminals run processes that must NOT be interrupted -->
    <terminal name="flutter-run" purpose="Flutter app execution" />
    <terminal name="dev-server" purpose="Development servers (npm, python, cargo)" />
    <terminal name="test-watch" purpose="Test runners in watch mode" />
    <terminal name="docker-compose" purpose="Container services" />
    <terminal name="database" purpose="Database servers/clients" />
  </long_running>
  
  <short_lived locked="false" reusable="true">
    <!-- These terminals execute commands that complete, then can be reused -->
    <terminal name="git" purpose="Version control operations" />
    <terminal name="package-manager" purpose="Dependency management (pub, npm, pip)" />
    <terminal name="build" purpose="One-shot build operations" />
    <terminal name="test" purpose="One-shot test execution" />
    <terminal name="general" purpose="File operations, utilities" />
    <terminal name="scripts" purpose="Custom scripts/automation" />
    <terminal name="cloud" purpose="Cloud CLI commands" />
  </short_lived>
</terminal_categories>
```

---

### **Decision Tree for Terminal Selection**

```
Command to execute?
    │
    ├─→ Long-running process? (server, app, watch, docker)
    │   └─→ Use dedicated locked terminal (flutter-run, dev-server, etc.)
    │       ⚠️ NEVER send other commands to this terminal
    │
    ├─→ Interacting with running process? (hot reload, quit)
    │   └─→ Verify process is running
    │       Send ONLY single-character commands (r, R, q)
    │       ⚠️ Multi-character commands KILL the process
    │
    └─→ Short-lived command? (git, build, test)
        └─→ Use category-specific terminal
            Can reuse after command completes
```

---

### **Tool Usage Enforcement**

```typescript
// ❌ FORBIDDEN - Causes process conflicts and chaos
run_in_terminal(command: "git status", ...)

// ✅ MANDATORY - Explicit terminal isolation
terminal-tools_sendCommand(
  terminalName: "git",
  command: "git status",
  workingDirectory: "/path/to/repo"
)
```

---

### **Flutter-Specific Critical Rules**

```xml
<flutter_terminal_rules>
  <rule id="1" priority="CRITICAL">
    <scenario>Starting Flutter app with output capture</scenario>
    <correct>
      terminal-tools_sendCommand(
        terminalName: "flutter-run",
        command: "(Remove-Item 'flutter_output.log' -ErrorAction SilentlyContinue) ; flutter run -d chrome -t lib/main.dart 2>&1 | Tee-Object -FilePath 'flutter_output.log'",
        workingDirectory: "/path/to/project/example"
      )
    </correct>
    <note>Terminal "flutter-run" is now LOCKED - no other commands allowed</note>
    <note>Output captured to flutter_output.log - readable with read_file tool</note>
  </rule>

  <rule id="2" priority="CRITICAL">
    <scenario>Hot reload Flutter app</scenario>
    <working_method>
      ✅ Send SINGLE character for interactive command:
      - terminal-tools_sendCommand(terminalName: "flutter-run", command: "r")  // Hot reload
      - terminal-tools_sendCommand(terminalName: "flutter-run", command: "R")  // Hot restart
      - terminal-tools_sendCommand(terminalName: "flutter-run", command: "c")  // Clear screen
      - terminal-tools_sendCommand(terminalName: "flutter-run", command: "h")  // Show help
    </working_method>
    <legacy_fallback>
      If single-char method fails:
      1. Stop app: terminal-tools_cancelCommand(terminalName: "flutter-run")
      2. Wait 2 seconds for graceful shutdown
      3. Restart: terminal-tools_sendCommand(terminalName: "flutter-run", command: "flutter run ...")
    </legacy_fallback>
    <forbidden>
      ❌ terminal-tools_sendCommand(terminalName: "flutter-run", command: "r\n")  // Newline kills app!
      ❌ terminal-tools_sendCommand(terminalName: "flutter-run", command: "reload")  // Multi-char kills app!
    </forbidden>
    <explanation>Flutter CLI runs in interactive mode, listening for single keypresses. Send ONLY the character (r, R, c, h, q) - no newlines or multi-char strings.</explanation>
  </rule>

  <rule id="3" priority="CRITICAL">
    <scenario>Running git/test/build while Flutter app running</scenario>
    <correct>
      Use SEPARATE terminals:
      - terminal-tools_sendCommand(terminalName: "git", command: "git status")
      - terminal-tools_sendCommand(terminalName: "test", command: "flutter test")
      - terminal-tools_sendCommand(terminalName: "build", command: "flutter build web")
    </correct>
    <forbidden>
      ❌ terminal-tools_sendCommand(terminalName: "flutter-run", command: "git status")
      ❌ Reusing "flutter-run" terminal KILLS the running app
    </forbidden>
  </rule>

  <rule id="4" priority="HIGH">
    <scenario>Installing packages while app running</scenario>
    <correct>
      terminal-tools_sendCommand(
        terminalName: "package-manager",
        command: "flutter pub get",
        workingDirectory: "/path/to/project"
      )
    </correct>
    <note>App keeps running but must restart to use new packages</note>
  </rule>
</flutter_terminal_rules>
```

---

### **Pre-Command Checklist (Automated)**

Before EVERY terminal command execution, verify:

```python
def pre_terminal_command_check(command: str, target_terminal: str) -> bool:
    """
    Automated validation before terminal command execution.
    Returns True if safe to proceed, False if violates rules.
    """
    
    # 1. Check if using run_in_terminal (FORBIDDEN)
    if using_run_in_terminal_tool():
        raise ValueError("❌ FORBIDDEN: Use terminal-tools_sendCommand instead")
    
    # 2. Check if terminal name is generic/missing
    if target_terminal in [None, "", "pwsh", "PowerShell", "bash", "zsh"]:
        raise ValueError("❌ FORBIDDEN: Must use explicit named terminal")
    
    # 3. Check if reusing locked terminal
    locked_terminals = ["flutter-run", "dev-server", "test-watch", "docker-compose", "database"]
    if target_terminal in locked_terminals:
        running_processes = terminal-tools_listTerminals()
        if terminal_has_active_process(target_terminal, running_processes):
            if not is_valid_interaction_command(command):  # Only allow 'r', 'R', 'q'
                raise ValueError(f"❌ FORBIDDEN: Terminal '{target_terminal}' locked by running process")
    
    # 4. Check if hot reload command is multi-character (DANGEROUS)
    if target_terminal == "flutter-run" and len(command) > 1 and command in ["r\n", "R\n", "reload"]:
        raise ValueError("❌ DANGEROUS: Multi-character hot reload kills app. Use restart instead.")
    
    return True
```

---

### **Example Workflow (Embedded in Agent Logic)**

```typescript
// When user requests: "Start the Flutter app, then run tests"

// Step 1: Start app in dedicated terminal
await terminal-tools_sendCommand({
  terminalName: "flutter-run",
  command: "flutter run -d chrome -t lib/main.dart",
  workingDirectory: "/path/to/project/example",
  captureOutput: false  // Stream logs to terminal
});

// Step 2: Wait for app to start (check logs or delay)
await wait(5000);  // 5 second startup delay

// Step 3: Run tests in SEPARATE terminal (app keeps running)
await terminal-tools_sendCommand({
  terminalName: "test",
  command: "flutter test test/unit/rendering/chart_render_box_test.dart",
  workingDirectory: "/path/to/project"
});

// ✅ Tests complete, app still running in flutter-run terminal
// ✅ Test output in separate terminal for clean debugging
```

---

### **Terminal Output Capture Protocol**

```xml
<output_capture_protocol enforcement="MANDATORY">
  <problem>
    Named terminals provide isolation but terminal-tools_sendCommand cannot read output.
    The captureOutput parameter exists but provides no retrieval mechanism for AI.
  </problem>
  
  <solution>
    PowerShell output redirection to log files using Tee-Object cmdlet.
  </solution>
  
  <pattern>
    (Remove-Item 'logfile.log' -ErrorAction SilentlyContinue) ; command 2>&1 | Tee-Object -FilePath 'logfile.log'
  </pattern>
  
  <components>
    <step order="1">Remove-Item - Delete old log (prevents appending)</step>
    <step order="2">-ErrorAction SilentlyContinue - Suppress error if log doesn't exist</step>
    <step order="3">2>&1 - Redirect stderr to stdout (capture all output)</step>
    <step order="4">Tee-Object - Write to file AND display in terminal</step>
    <step order="5">AI reads log with read_file tool</step>
  </components>
  
  <examples>
    <flutter>
      terminal-tools_sendCommand({
        terminalName: "flutter-run",
        command: "(Remove-Item 'flutter_output.log' -ErrorAction SilentlyContinue) ; flutter run -d chrome -t lib/main.dart 2>&1 | Tee-Object -FilePath 'flutter_output.log'",
        workingDirectory: "/path/to/example"
      });
      
      // Read output later
      read_file({filePath: "/path/to/example/flutter_output.log"});
    </flutter>
    
    <dev_server>
      terminal-tools_sendCommand({
        terminalName: "dev-server",
        command: "(Remove-Item 'server.log' -ErrorAction SilentlyContinue) ; npm run dev 2>&1 | Tee-Object -FilePath 'server.log'",
        workingDirectory: "/path/to/project"
      });
    </dev_server>
  </examples>
  
  <critical_rules>
    <rule priority="1">ALWAYS delete log file before starting (prevents mixing old/new output)</rule>
    <rule priority="2">ALWAYS use full pattern with Remove-Item prefix</rule>
    <rule priority="3">Log files persist after process ends - can read anytime</rule>
    <rule priority="4">Can read log multiple times to see new output incrementally</rule>
    <rule priority="5">Use this pattern for ALL long-running processes (Flutter, servers, watch tasks)</rule>
  </critical_rules>
</output_capture_protocol>
```

---

### **Error Recovery Patterns**

```typescript
// If app accidentally killed:
async function recover_killed_flutter_app() {
  console.log("🔄 Detected Flutter app termination. Restarting...");
  
  // Ensure terminal is clean
  await terminal-tools_cancelCommand({terminalName: "flutter-run"});
  await wait(2000);
  
  // Restart in same dedicated terminal
  await terminal-tools_sendCommand({
    terminalName: "flutter-run",
    command: "flutter run -d chrome -t lib/main.dart",
    workingDirectory: "/path/to/project/example"
  });
  
  console.log("✅ Flutter app restarted in dedicated terminal");
}
```

---

## Interactive Flutter Commands (GAME-CHANGER!)

<interactive_commands priority="HIGH">
  <discovery>Single-character commands work perfectly for Flutter interactive mode!</discovery>
  
  <working_commands>
    <command key="r">Hot reload - Apply code changes without restart</command>
    <command key="R">Hot restart - Full application restart</command>
    <command key="c">Clear screen - Clear terminal output</command>
    <command key="h">Help - Show all available commands</command>
    <command key="q">Quit - Terminate application</command>
  </working_commands>
  
  <critical_rules>
    <rule>✅ WORKS: Single characters only ("r", "R", "c", "h", "q")</rule>
    <rule>❌ KILLS APP: Adding newlines ("r\n")</rule>
    <rule>❌ KILLS APP: Multi-character strings ("reload")</rule>
    <rule>❌ KILLS APP: Shell commands in flutter-run terminal</rule>
  </critical_rules>
  
  <examples>
    <hot_reload>
      terminal-tools_sendCommand({
        terminalName: "flutter-run",
        command: "r" // Just 'r', nothing else!
      });
    </hot_reload>
    
    <hot_restart>
      terminal-tools_sendCommand({
        terminalName: "flutter-run",
        command: "R" // Capital R for full restart
      });
    </hot_restart>
    
    <clear_screen>
      terminal-tools_sendCommand({
        terminalName: "flutter-run",
        command: "c" // Clear terminal output
      });
    </clear_screen>
  </examples>
  
  <technical_explanation>
    Flutter's interactive CLI mode listens for single keypresses on stdin.
    When terminal-tools_sendCommand sends a single character, it's interpreted
    as a keypress event, triggering Flutter's interactive handlers. Adding
    newlines or sending multi-character strings breaks the input handler,
    causing process termination.
  </technical_explanation>
  
  <workflow>
    <step>1. Start Flutter app with output capture</step>
    <step>2. Make code changes in editor</step>
    <step>3. Send 'r' to hot reload instantly</step>
    <step>4. Verify changes in running app</step>
    <step>5. Read flutter_output.log to check for errors</step>
  </workflow>
  
  <benefits>
    <benefit>No app restart needed - preserves state</benefit>
    <benefit>Instant feedback (sub-second reload times)</benefit>
    <benefit>Matches manual developer workflow</benefit>
    <benefit>Works within named terminal protocol</benefit>
    <benefit>Enables true AI-driven development loop</benefit>
  </benefits>
</interactive_commands>

---

### **Monitoring & State Awareness**

```typescript
// Periodically check terminal state (every 10 commands or on user request)
async function monitor_terminal_health() {
  const terminals = await terminal-tools_listTerminals();
  
  // Parse terminal list to identify:
  // 1. Long-running processes (flutter-run, dev-server, etc.)
  // 2. Idle terminals available for reuse
  // 3. Orphaned terminals that should be cleaned up
  
  // Log state for transparency
  console.log("📊 Terminal State:");
  console.log(`  - flutter-run: ${terminals.includes("flutter-run") ? "ACTIVE" : "IDLE"}`);
  console.log(`  - git: ${terminals.includes("git") ? "ACTIVE" : "IDLE"}`);
  // ... etc
  
  return terminals;
}
```

---

### **Summary: Core Behavioral Changes**

| Old Behavior (FORBIDDEN) | New Behavior (MANDATORY) |
|--------------------------|--------------------------|
| Use `run_in_terminal` for all commands | Use `terminal-tools_sendCommand` with named terminals |
| Commands run in "last active terminal" | Commands run in category-specific terminals |
| Flutter app killed by git commands | Separate terminals - app isolated from git |
| Hot reload kills app | Restart app or use file-save hot reload |
| No awareness of running processes | Check state with `terminal-tools_listTerminals()` |
| Generic terminal names (pwsh, bash) | Explicit names (flutter-run, git, test, etc.) |

---

## 🔥 Integration Instructions

1. **Add to system prompt** under "Tool Usage Instructions" section
2. **Add to mode instructions** as priority ALPHA enforcement
3. **Add to pre-command validation** as automated check
4. **Add to agent training examples** as canonical patterns
5. **Add to error recovery logic** for killed process detection

---

**Enforcement Level**: 🔴 CRITICAL - Zero tolerance violations  
**Rationale**: Terminal conflicts cause catastrophic developer experience degradation  
**Expected Impact**: 100% elimination of accidental process termination  

---

**Version**: 1.0.0  
**Last Updated**: 2025-11-19  
**Status**: ✅ Ready for integration
