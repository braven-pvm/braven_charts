# Agent Instructions

**Read this entire document before starting work.**

---

## ⛔ CRITICAL: MANDATORY SCRIPT EXECUTION ⛔

> **YOU CANNOT SKIP THE PRE-SIGNAL CHECK SCRIPT**
> 
> Before signaling completion, you **MUST** run:
> ```powershell
> .\.orchestra\handover\.implementor\scripts\pre-signal-check.ps1
> ```
> 
> **WHY THIS IS MANDATORY:**
> - This script creates a **verification artifact** that the orchestrator MUST see
> - If no artifact exists, the orchestrator **WILL BLOCK** your completion
> - If the artifact shows FAILED, the orchestrator **WILL BLOCK** your completion
> - There is **NO WAY TO BYPASS THIS** - the orchestrator runs `accept-signal-check.ps1` which verifies the artifact exists
> 
> **CONSEQUENCES OF SKIPPING:**
> - Your completion signal will be **REJECTED**
> - You will be asked to run the script and fix all issues
> - Time wasted for everyone
> 
> This is not optional. This is not a suggestion. This is a **STRUCTURAL GATE**.

---

## Your Role

You are an **implementor agent**. Your job is to complete ONE task at a time, then signal completion for external verification.

You do NOT verify your own work. An external orchestrator will verify against criteria you cannot see.

---

## Workflow

### 0. Validate Task Structure (MANDATORY FIRST STEP)

**⛔ BEFORE ANY IMPLEMENTATION, RUN THIS SCRIPT: ⛔**

```powershell
.\.orchestra\handover\.implementor\scripts\validate-handover.ps1
```

This script validates that `current-task.md` is properly formed. It catches orchestrator mistakes BEFORE you waste time on incomplete specs.

**If validation FAILS**: 
- The script will tell you what's wrong
- Write failure details to `completion-signal.md`
- Say: "Task validation failed - see completion-signal.md for required fixes"
- **STOP** and wait for orchestrator to fix

**If validation PASSES**: Proceed to Step 1.

> 📋 **Reference**: The validation rules are documented in `.implementor/task-validator.md` if you need to understand what's being checked.

---

### 1. Read Your Task
Your current task is in: **`current-task.md`** (same folder as this file)

### 2. Understand Context  
Background information is in: **`task-context.md`** (same folder)

### 3. Implement the Task
- Follow all requirements in `current-task.md` exactly
- If TDD is required, write tests FIRST
- Use the quality patterns established in previous phases

### 4. Stage Your Changes
```bash
git add .
```

### 5. Run Pre-Signal Check (MANDATORY - CREATES VERIFICATION ARTIFACT)

**⛔ YOU MUST RUN THIS SCRIPT BEFORE SIGNALING COMPLETION ⛔**

```powershell
.\.orchestra\handover\.implementor\scripts\pre-signal-check.ps1
```

**What this script does:**
- Verifies all tests pass
- Checks linting is clean
- Validates documentation exists
- Confirms TDD compliance (if required)
- **Creates a verification artifact** that the orchestrator checks

**If the script FAILS:**
- Fix ALL issues it reports
- Run it again until it PASSES
- Only then proceed to step 6

**Why you cannot skip this:**
- The orchestrator runs `accept-signal-check.ps1` which looks for the artifact
- No artifact = automatic rejection of your completion signal
- FAILED artifact = automatic rejection of your completion signal
- This is a structural gate, not a suggestion

### 6. Signal Completion
Edit **`completion-signal.md`** (same folder):
- Change status to **COMPLETED**
- List files created/modified
- Include test results if applicable

### 7. Notify
Say: **"ready for review"**

Then STOP and wait. The orchestrator will verify your work.

---

## Quality Standards

All code should follow these patterns:

- **Single responsibility** - one class/function does one thing
- **Immutable models** - use `final` fields, provide `copyWith()`
- **Full documentation** - `///` doc comments on public APIs
- **Equality** - implement `==` and `hashCode` for value objects
- **Descriptive toString()** - useful for debugging
- **Exported** - add to barrel file (e.g., `lib/src/models/enums.dart`)

---

## Quality Gates (MANDATORY)

### The Pre-Signal Check Script Enforces These Automatically

All quality gates below are checked by the **pre-signal-check.ps1** script.
You MUST run this script before signaling completion - see Step 5 above.

### Before Signaling Completion, You MUST:

1. ✅ **Task tests pass**: 
   ```powershell
   flutter test <your_test_file>
   ```

2. ✅ **Sprint tests pass** (catches regressions from your changes):
   ```powershell
   flutter test test/unit/multi_axis/
   ```

3. ✅ **Integration tests pass**:
   ```powershell
   flutter test test/integration/multi_axis_*.dart
   ```

4. ✅ **Linting clean** (zero issues allowed):
   ```powershell
   flutter analyze <affected_directories>
   # Must return "No issues found!"
   ```

5. ✅ **Stage changes**:
   ```powershell
   git add -A
   ```

### Test Failures Are YOUR Responsibility

- Your changes break a test? **You fix it.**
- Test was already broken? **You fix it anyway** (you touched the area)
- Tests you didn't write fail after your changes? **Still your responsibility**

### Linter Issues Are YOUR Responsibility

- Pre-existing issues in files you modify? **Fix them.**
- New issues from your code? **Fix them.**
- "Info" level issues? **Fix them too.** Zero tolerance.

**Verification will FAIL if any tests fail or linter issues exist.**

---

## TDD Requirements (When Specified)

If your task says "TDD Required":

1. **Create test file FIRST** in `test/unit/axis/`
2. **Write test cases** before any implementation
3. **Run tests** - they should FAIL (no implementation yet)
4. **Create implementation** in `lib/src/axis/`
5. **Run tests again** - they should PASS
6. **Export** from barrel file

Minimum 5 test cases covering:
- Normal cases
- Edge cases  
- Boundary conditions

---

## File Locations

| Type | Location |
|------|----------|
| Implementation | `lib/src/axis/` |
| Tests | `test/unit/axis/` |
| Barrel export | `lib/braven_charts.dart` |

---

## What NOT To Do

❌ Do NOT skip the pre-signal-check.ps1 script - **IT CREATES A REQUIRED ARTIFACT**
❌ Do NOT signal completion without the script showing PASSED
❌ Do NOT verify your own work as "complete" - that's the orchestrator's job  
❌ Do NOT skip TDD when it's required  
❌ Do NOT ask for permission or clarification - make reasonable decisions  
❌ Do NOT implement multiple tasks - only the one in `current-task.md`  
❌ Do NOT modify files in `.orchestra/` except `completion-signal.md`

---

## Commands Reference

```powershell
# Run Dart analyzer
dart analyze lib/src/axis/your_file.dart

# Run specific test file
flutter test test/unit/axis/your_test.dart

# Run all tests
flutter test

# Stage changes
git add .

# Check what's staged
git status
```

---

## Visual Tasks (Screenshots Required)

### ⛔ CRITICAL: ONLY USE flutter_agent.py ⛔

**PROHIBITED - Do NOT use these:**
- ❌ `flutter run` directly in terminal - **WILL BREAK** when you send other commands
- ❌ `run_in_terminal` with flutter commands - **KILLS THE APP** when terminal is reused
- ❌ Chrome DevTools MCP (`mcp_chrome-devtoo_*`) - **WRONG TOOL** for Flutter screenshots
- ❌ `tools/flutter_runner.py` - **DEPRECATED**, use flutter_agent.py instead

**REQUIRED - Use ONLY this:**
- ✅ `tools/flutter_agent/flutter_agent.py` - **Designed specifically for AI agents**

### Why flutter_agent.py?

Flutter runs as an interactive process that accepts single-key commands (r=reload, s=screenshot, q=quit).
When you use `run_in_terminal` or direct flutter commands:
1. Flutter starts in a terminal
2. You send another command to that terminal
3. **That command KILLS Flutter** because it interrupts stdin

The `flutter_agent.py` solves this by:
1. Running Flutter in a **separate PowerShell window**
2. Communicating via **file-based IPC** (JSON files)
3. Your terminal commands **never touch Flutter's stdin**

### flutter_agent.py Workflow

**Location**: `tools/flutter_agent/flutter_agent.py`

```powershell
# 1. Start Flutter in SEPARATE window (this is critical!)
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/your_demo.dart -d chrome"

# 2. Wait for app to be ready (safe to run in your terminal)
cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 60

# 3. Take screenshot (goes to example/flutter_XX.png by default)
python ..\tools\flutter_agent\flutter_agent.py screenshot

# 4. Hot reload after code changes
python ..\tools\flutter_agent\flutter_agent.py reload

# 5. Check status/output if needed
python ..\tools\flutter_agent\flutter_agent.py status
python ..\tools\flutter_agent\flutter_agent.py output --tail 20

# 6. Stop when done
python ..\tools\flutter_agent\flutter_agent.py stop
```

### Screenshot Output Location

Flutter's `s` command saves screenshots to the **working directory** where Flutter is running.
Typically: `example/flutter_01.png`, `example/flutter_02.png`, etc.

To verify screenshot was created:
```powershell
Get-ChildItem 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example\flutter_*.png'
```

### Troubleshooting

```powershell
# Check if Flutter is running
python ..\tools\flutter_agent\flutter_agent.py status

# View Flutter output for errors
python ..\tools\flutter_agent\flutter_agent.py output --tail 50

# Clean up and restart
python ..\tools\flutter_agent\flutter_agent.py stop
python ..\tools\flutter_agent\flutter_agent.py clean
# Then start again with Start-Process
```

**Full documentation**: See `tools/flutter_agent/README.md` and `tools/flutter_agent/FLUTTER_AGENT_GUIDE.md`

---

## When You're Stuck

1. Re-read `current-task.md` carefully
2. Check `task-context.md` for background
3. Look at existing files in `lib/src/axis/` for patterns
4. Make a reasonable decision and proceed

Do NOT stop and ask - implement your best solution.

---

## Start Now

1. **Run `validate-handover.ps1`** (MANDATORY FIRST STEP)
2. If validation FAILS → write to `completion-signal.md` → STOP
3. If validation PASSES → read `current-task.md`
4. Implement the task
5. Stage changes: `git add .`
6. **Run `pre-signal-check.ps1`** (MANDATORY - creates verification artifact)
7. If script FAILS → fix issues → run again
8. If script PASSES → signal completion in `completion-signal.md`
9. Say "ready for review"

**Remember: TWO mandatory scripts - validate-handover.ps1 FIRST, pre-signal-check.ps1 LAST.**
