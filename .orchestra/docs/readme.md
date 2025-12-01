# Orchestra System Documentation

⚠️ **THIS FOLDER IS FOR ORCHESTRATOR/VERIFIER ONLY** ⚠️

The implementor agent should NEVER be directed to read files outside of the `handover/` folder.

## New Folder Structure (Restructured)

```
.orchestra/
├── orchestrator/                    # Orchestrator role
│   ├── .orchestrator-only/          # HIDDEN from implementor
│   │   ├── manifest.yaml            # Sprint task definitions
│   │   ├── progress.yaml            # Sprint progress tracking
│   │   ├── verification/            # Task verification criteria (YAML files)
│   │   ├── preflight/               # Pre-task orchestrator checklists
│   │   └── templates/               # Orchestrator-only templates
│   ├── scripts/                     # Orchestrator automation scripts
│   │   ├── task-closeout-check.ps1
│   │   ├── handover-validate.ps1
│   │   ├── accept-signal-check.ps1
│   │   ├── task-coverage.ps1
│   │   └── verification-audit.ps1
│   ├── results/                     # Verification results & screenshots
│   │   ├── task-NNN-results.md
│   │   └── screenshots/
│   └── readme.md                    # Orchestrator role guide
│
├── implementor/                     # Implementor role
│   ├── .implementor-only/           # HIDDEN from orchestrator
│   │   ├── scripts/                 # Implementor validation scripts
│   │   │   ├── pre-signal-check.ps1
│   │   │   └── validate-handover.ps1
│   │   ├── completion-signal.md     # Active completion signal
│   │   └── task-validator.md        # Self-validation checklist
│   ├── artifacts/                   # Persistent implementor artifacts
│   │   └── pre-signal/              # Pre-signal check logs
│   └── readme.md                    # Implementor role guide
│
├── common/                          # Shared resources
│   ├── scripts/                     # Shared utilities
│   │   ├── set-env.ps1              # Environment setup
│   │   ├── check-utils.ps1          # Check utilities
│   │   └── README.md                # Script documentation
│   └── templates/                   # Shared templates
│       ├── completion-signal.md.template
│       ├── current-task-template.md
│       ├── orchestrator-preflight-template.md
│       └── task-results-template.md
│
├── handover/                        # TRANSIENT exchange zone
│   ├── agent_readme.md              # Implementor starts here
│   ├── current-task.md              # Current task (replaced each task)
│   └── task-context.md              # Sprint background
│
└── docs/                            # Persistent documentation
    ├── readme.md                    # This file
    └── research_log.md              # Issue/learning log
```

## Key Principles

### Role-Based Separation

- **Orchestrator** owns: `.orchestrator-only/`, `scripts/`, `results/`
- **Implementor** owns: `.implementor-only/`, `artifacts/`
- **Common** shared by both: `common/scripts/`, `common/templates/`
- **Handover** is the exchange zone: cleared between tasks

### Hidden Files

- `.orchestrator-only/` - Implementor MUST NOT read (verification criteria, manifest)
- `.implementor-only/` - Orchestrator MUST NOT read during handover (validation scripts)

---

## 🚨 CRITICAL: Orchestrator Pre-Flight Protocol 🚨

**BEFORE preparing ANY task, the orchestrator MUST:**

### Step 0: Initialize Environment & Run Task Closeout Check (MANDATORY)

```powershell
# Source the environment (ALWAYS DO THIS FIRST)
. .\.orchestra\common\scripts\set-env.ps1

# Run the task closeout check script
.\.orchestra\orchestrator\scripts\task-closeout-check.ps1
```

This script verifies:
- ✅ No uncommitted changes
- ✅ Previous task marked COMPLETED in progress.yaml
- ✅ Previous task has commit hash
- ✅ SpecKit tasks.md updated with checkmarks
- ✅ Verification results recorded
- ✅ Screenshot exists and has content (if visual task)
- ✅ Sprint tests still pass
- ✅ completion-signal.md deleted (not just empty)
- ✅ task-context.md reflects current phase

**IF ANY CHECK FAILS**: Fix the issues BEFORE proceeding. Do NOT skip this step.

Use `-Fix` flag to auto-fix some issues:
```powershell
.\.orchestra\orchestrator\scripts\task-closeout-check.ps1 -Fix
```

---

## Orchestrator Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `set-env.ps1` | `common/scripts/` | Load environment variables |
| `task-closeout-check.ps1` | `orchestrator/scripts/` | Verify previous task closed out |
| `handover-validate.ps1` | `orchestrator/scripts/` | Validate current-task.md |
| `accept-signal-check.ps1` | `orchestrator/scripts/` | Verify implementor ran pre-signal |
| `task-coverage.ps1` | `orchestrator/scripts/` | SpecKit ↔ Orchestrator sync |
| `verification-audit.ps1` | `orchestrator/scripts/` | Audit verification records |

## Implementor Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `validate-handover.ps1` | `implementor/.implementor-only/scripts/` | Validate task is actionable |
| `pre-signal-check.ps1` | `implementor/.implementor-only/scripts/` | Check before signaling done |

---

## Workflow

### 1. Prepare Task (Orchestrator)
```powershell
# Source environment
. .\.orchestra\common\scripts\set-env.ps1

# Verify previous task is closed out
.\.orchestra\orchestrator\scripts\task-closeout-check.ps1

# Read manifest for next task
# Prepare handover/current-task.md from template
# Create verification YAML
# Validate handover
.\.orchestra\orchestrator\scripts\handover-validate.ps1
```

### 2. Implementor Works
```powershell
# Validate handover is actionable
.\.orchestra\implementor\.implementor-only\scripts\validate-handover.ps1

# Do the work...

# Before signaling done
.\.orchestra\implementor\.implementor-only\scripts\pre-signal-check.ps1

# Write completion signal and say "ready for review"
```

### 3. Verify & Accept (Orchestrator)
```powershell
# Verify implementor ran pre-signal
.\.orchestra\orchestrator\scripts\accept-signal-check.ps1

# Run verification against hidden criteria
# Record results in orchestrator/results/
# Commit and close out
```

---

## 🖼️ Visual Verification

### Roles

| Phase | Actor | Tool | Purpose |
|-------|-------|------|---------|
| CAPTURE | Implementor | `flutter_agent.py` | Run app, take screenshot |
| VIEW | Orchestrator | Chrome DevTools MCP | View existing PNG, verify content |

### Implementor: Screenshot Capture

```powershell
# Start Flutter in SEPARATE window
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'path\to\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_NNN_demo.dart -d chrome"

# Wait for ready
python tools/flutter_agent/flutter_agent.py wait --timeout 60

# Take screenshot
python tools/flutter_agent/flutter_agent.py screenshot --output screenshots/task_NNN_verification.png

# Stop app
python tools/flutter_agent/flutter_agent.py stop
```

### Orchestrator: Screenshot Viewing

```
# Open screenshot in browser
mcp_chrome-devtoo_new_page(url: "file:///path/to/screenshot.png")

# Take screenshot (returns image to agent for analysis)
mcp_chrome-devtoo_take_screenshot()

# Analyze content against verification criteria

# Close when done
mcp_chrome-devtoo_close_page(pageIdx: 1)
```

---

## See Also

- `orchestrator/readme.md` - Orchestrator role details
- `implementor/readme.md` - Implementor role details
- `research_log.md` - Issue/learning log
