# Terminal Management - Quick Reference Card

## 🎯 One-Page Cheat Sheet

### **The Golden Rule**
> **ALWAYS use `terminal-tools_sendCommand` with named terminals. NEVER use `run_in_terminal`.**

---

## 📤 Output Capture Pattern

**For long-running processes (Flutter, servers, watch tasks):**

```powershell
(Remove-Item 'output.log' -ErrorAction SilentlyContinue) ; <command> 2>&1 | Tee-Object -FilePath 'output.log'
```

**Then read output anytime:**
```typescript
read_file(filePath: "path/to/output.log")
```

**Example: Flutter with Output**
```typescript
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "(Remove-Item 'flutter_output.log' -ErrorAction SilentlyContinue) ; flutter run -d chrome -t lib/main.dart 2>&1 | Tee-Object -FilePath 'flutter_output.log'",
  workingDirectory: "E:\\path\\to\\example"
)

// Read debug output anytime
read_file(filePath: "E:\\path\\to\\example\\flutter_output.log")
```

---

## 📋 Terminal Name Quick Lookup

| What you're doing | Terminal Name | Can reuse? |
|-------------------|---------------|------------|
| 🚀 Running Flutter app | `flutter-run` | ❌ LOCKED |
| 🔧 Git operations | `git` | ✅ Yes |
| 📦 Installing packages | `package-manager` | ✅ Yes |
| 🏗️ Building app | `build` | ✅ Yes |
| 🧪 Running tests | `test` | ✅ Yes |
| 📁 File operations | `general` | ✅ Yes |
| 🐳 Docker containers | `docker-compose` | ❌ LOCKED |
| 🌐 Dev server | `dev-server` | ❌ LOCKED |

---

## 🔥 Critical Don'ts

```typescript
// ❌ NEVER DO THIS - Kills running app
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "git status"
)

// ❌ NEVER DO THIS - Kills running app
run_in_terminal("git status")

// ❌ NEVER DO THIS - Kills running app  
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "r\n"  // Multi-character hot reload
)
```

---

## ✅ Common Patterns (Copy & Paste)

### Start Flutter App
```typescript
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "(Remove-Item 'flutter_output.log' -ErrorAction SilentlyContinue) ; flutter run -d chrome -t lib/main.dart 2>&1 | Tee-Object -FilePath 'flutter_output.log'",
  workingDirectory: "E:\\path\\to\\project\\example"
)
// ⚠️ Terminal now LOCKED for shell commands
// ✅ BUT interactive commands work! (r, R, c, h, q)
// 📄 Output saved to flutter_output.log (readable with read_file)
```

### Hot Reload / Interactive Commands
```typescript
// ✅ Hot reload - apply code changes instantly!
terminal-tools_sendCommand(terminalName: "flutter-run", command: "r")

// ✅ Hot restart - full app restart
terminal-tools_sendCommand(terminalName: "flutter-run", command: "R")

// ✅ Clear terminal screen
terminal-tools_sendCommand(terminalName: "flutter-run", command: "c")

// ✅ Show help menu
terminal-tools_sendCommand(terminalName: "flutter-run", command: "h")

// ⚠️ CRITICAL: Single chars ONLY! No \n, no multi-char strings!
```

### Git While App Running
```typescript
// ✅ App keeps running
terminal-tools_sendCommand(
  terminalName: "git",
  command: "git add ."
)

terminal-tools_sendCommand(
  terminalName: "git",
  command: 'git commit -m "Fix: Update logic"'
)
```

### Hot Reload (Safest Method)
```typescript
// 1. Stop app
terminal-tools_cancelCommand(terminalName: "flutter-run")

// 2. Wait 2 seconds
// (pause for graceful shutdown)

// 3. Restart
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "flutter run -d chrome -t lib/main.dart",
  workingDirectory: "E:\\path\\to\\project\\example"
)
```

### Run Tests While App Running
```typescript
// ✅ App keeps running, tests in separate terminal
terminal-tools_sendCommand(
  terminalName: "test",
  command: "flutter test test/unit/my_test.dart",
  workingDirectory: "E:\\path\\to\\project"
)
```

### Install Package While App Running
```typescript
// ✅ App keeps running
terminal-tools_sendCommand(
  terminalName: "package-manager",
  command: "flutter pub get",
  workingDirectory: "E:\\path\\to\\project"
)
// ⚠️ Must restart app to use new package
```

### Build While App Running
```typescript
// ✅ App keeps running, build in separate terminal
terminal-tools_sendCommand(
  terminalName: "build",
  command: "flutter build web --release",
  workingDirectory: "E:\\path\\to\\project"
)
```

### Check Terminal State
```typescript
// See what's running
terminal-tools_listTerminals()

// Output shows:
// - flutter-run: ACTIVE (running app)
// - git: IDLE
// - test: IDLE
```

### Stop App
```typescript
// Send Ctrl+C
terminal-tools_cancelCommand(terminalName: "flutter-run")

// Or send quit command
terminal-tools_sendCommand(terminalName: "flutter-run", command: "q")

// Clean up terminal
terminal-tools_deleteTerminal(name: "flutter-run")
```

---

## 🚨 If You Accidentally Kill the App

```typescript
// Restart in same terminal
terminal-tools_sendCommand(
  terminalName: "flutter-run",
  command: "flutter run -d chrome -t lib/main.dart",
  workingDirectory: "E:\\path\\to\\project\\example"
)
```

---

## 💡 Pro Tips

1. **Check terminals first**: Run `terminal-tools_listTerminals()` before major operations
2. **One app per terminal**: Never run multiple Flutter apps in same terminal
3. **Reuse short terminals**: Git, test, build terminals can be reused after command completes
4. **File-save hot reload**: Save files in editor - Flutter auto-reloads if watch enabled
5. **Explicit paths**: Always provide `workingDirectory` parameter for clarity

---

## 📊 Decision in 3 Seconds

```
Is it Flutter app/server/watch mode?
  YES → Use flutter-run/dev-server/test-watch (LOCKED)
  NO  → Use git/test/build/package-manager/general (REUSABLE)
```

---

**Print this page and keep it visible while coding!** 📌
