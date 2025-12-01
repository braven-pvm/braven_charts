# Orchestra System Documentation

⚠️ **THIS FOLDER IS FOR ORCHESTRATOR/VERIFIER ONLY** ⚠️

The implementor agent should NEVER be directed to read files outside of the `handover/` folder.

🚫 **ORCHESTRATOR: DO NOT READ `.orchestra/implementor/.implementor-only/`** 🚫

The `.implementor-only/` folder contains the implementor's self-verification rules.
Reading it would defeat the purpose of mutual verification. The implementor
uses these rules to validate YOUR work - if you know what they check, you
might (consciously or not) optimize for passing checks rather than quality.

## Folder Structure

```
.orchestra/
├── orchestrator/                    # Orchestrator role
│   ├── .orchestrator-only/          # HIDDEN from implementor
│   │   ├── manifest.yaml            # Sprint task definitions
│   │   ├── progress.yaml            # Sprint progress tracking
│   │   ├── verification/            # Task verification criteria (YAML files)
│   │   │   ├── task-001.yaml
│   │   │   └── task-016.yaml
│   │   ├── preflight/               # Pre-task orchestrator checklists
│   │   │   └── orchestrator-preflight-016.md
│   │   └── templates/               # Orchestrator-only templates
│   ├── scripts/                     # Orchestrator automation scripts
│   │   ├── task-closeout-check.ps1  # ⭐ Verify previous task closed out
│   │   ├── accept-signal-check.ps1  # ⭐ Verify implementor ran pre-signal
│   │   ├── handover-validate.ps1    # Validate current-task.md
│   │   ├── task-coverage.ps1        # SpecKit ↔ Orchestrator sync
│   │   └── verification-audit.ps1   # Audit verification records
│   ├── results/                     # Verification results & screenshots
│   │   ├── task-NNN-results.md
│   │   └── screenshots/
│   │       └── task-016-showcase.png
│   └── readme.md                    # Orchestrator role guide
│
├── implementor/                     # Implementor role
│   ├── .implementor-only/           # 🚫 ORCHESTRATOR DO NOT READ 🚫
│   │   ├── scripts/                 # Implementor validation scripts
│   │   │   ├── pre-signal-check.ps1
│   │   │   └── validate-handover.ps1
│   │   └── task-validator.md        # Implementor's validation rules
│   ├── artifacts/                   # Persistent implementor artifacts
│   │   └── pre-signal/              # Pre-signal check logs (CHECKED BY accept-signal-check.ps1)
│   └── readme.md                    # Implementor role guide
│
├── common/                          # Shared resources
│   ├── scripts/                     # Shared utilities
│   │   ├── set-env.ps1              # ⭐ Source first: . .\.orchestra\common\scripts\set-env.ps1
│   │   ├── check-utils.ps1          # Check utilities
│   │   └── README.md                # Script documentation
│   └── templates/                   # Shared templates
│       ├── completion-signal.md.template
│       ├── current-task-template.md      # ⭐ MUST use for every task
│       ├── orchestrator-preflight-template.md
│       └── task-results-template.md      # ⭐ MUST use for verification results
│
├── handover/                        # TRANSIENT exchange zone (VISIBLE to implementor)
│   ├── agent_readme.md              # ⭐ Implementor starts here
│   ├── current-task.md              # Current task (REPLACED each task)
│   ├── task-context.md              # Sprint background (SEMI-STABLE)
│   └── completion-signal.md         # Implementor signals done (CLEARED after verification)
│
└── docs/                            # Persistent documentation
    ├── readme.md                    # This file
    ├── research_log.md              # Issue/learning log
    └── solution-options.md          # Extension design discussions
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

**WHY THIS EXISTS**: Orchestrators can drift from documented process, operating from memory
instead of following instructions. This protocol FORCES structural compliance.

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
- ✅ completion-signal.md is clear
- ✅ task-context.md reflects current phase

**IF ANY CHECK FAILS**: Fix the issues BEFORE proceeding. Do NOT skip this step.

Use `-Fix` flag to auto-fix some issues:
```powershell
.\.orchestra\orchestrator\scripts\task-closeout-check.ps1 -Fix
```

### Step 1: Read This File
```
READ `.orchestra/docs/readme.md` ← You are here. Do NOT rely on memory!
```

### Step 2: Delete Old Task
```
DELETE `.orchestra/handover/current-task.md`
```
This prevents contamination from previous task content.

### Step 3: Copy Template
```
COPY `.orchestra/common/templates/current-task-template.md`
  TO `.orchestra/handover/current-task.md`
```

### Step 4: Fill Template
Fill EVERY section with either:
- **Actual content**, OR
- **`[N/A - Reason: explanation]`**

No `[TODO]` markers may remain in the final version.

### Step 5: Complete Pre-Flight Checklist
The template contains a checklist. Complete it honestly.

### Step 6: Save Audit Trail
```
COPY the completed checklist section
  TO `.orchestra/orchestrator/.orchestrator-only/preflight/orchestrator-preflight-NNN.md`
```
Then DELETE the checklist from current-task.md before implementor sees it.

### Step 7: Invoke Implementor
Tell implementor: **"Read `.orchestra/handover/agent_readme.md` and complete your task"**

---

## Orchestrator Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `set-env.ps1` | `common/scripts/` | Load environment variables |
| `task-closeout-check.ps1` | `orchestrator/scripts/` | Verify previous task closed out |
| `accept-signal-check.ps1` | `orchestrator/scripts/` | Verify implementor ran pre-signal |
| `handover-validate.ps1` | `orchestrator/scripts/` | Validate current-task.md |
| `task-coverage.ps1` | `orchestrator/scripts/` | SpecKit ↔ Orchestrator sync |
| `verification-audit.ps1` | `orchestrator/scripts/` | Audit verification records |

## Implementor Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `validate-handover.ps1` | `implementor/.implementor-only/scripts/` | Validate task is actionable |
| `pre-signal-check.ps1` | `implementor/.implementor-only/scripts/` | Check before signaling done (WRITES ARTIFACT) |

---

## Complete Workflow

### 1. Feed Task (Human/Orchestrator)
- Copy task details from `manifest.yaml` to `handover/current-task.md`
- Update `progress.yaml` with start time
- Tell implementor: **"Read `.orchestra/handover/agent_readme.md` and complete your task"**

> **IMPORTANT**: Always direct implementor to `agent_readme.md` first, not `current-task.md`.
> This ensures consistent onboarding whether it's the same agent or a new agent after handover.

### 2. Implementor Works
- Reads `agent_readme.md` (workflow instructions)
- Reads `current-task.md` (specific task)
- Reads `task-context.md` (background)
- Implements the task
- Stages changes
- **Runs `pre-signal-check.ps1`** (creates verification artifact)
- Writes to `completion-signal.md`
- Says "ready for review"

### 3. Accept Signal (MANDATORY FIRST STEP)

**⛔ BEFORE reading verification/task-XXX.yaml, run:**

```powershell
.\.orchestra\orchestrator\scripts\accept-signal-check.ps1
```

This script verifies the implementor actually ran the pre-signal check:
- ✅ Artifact exists at `.orchestra/implementor/artifacts/pre-signal/task-{N}-*.txt`
- ✅ Artifact shows PASSED status
- ⚠️ Artifact is not stale (>24 hours old)

**IF THIS FAILS:**
- Do NOT proceed with verification
- Do NOT commit anything
- Tell implementor: "Run `.orchestra/implementor/.implementor-only/scripts/pre-signal-check.ps1` and fix all issues"
- Wait for them to actually run it and signal again

**This prevents implementors from skipping validation scripts entirely.**

### 4. Verify Task

```
1. Read `.orchestra/orchestrator/.orchestrator-only/verification/task-XXX.yaml`
2. Execute each verification command from the yaml
3. Check all adversarial conditions
4. Capture screenshots if required (VISUAL/INTEGRATION tasks)
5. Record results (PASS/FAIL for each check)
```

### 5. Decision

**If ALL checks PASS:**
```
1. Stage and commit all changes:
   git add -A
   git commit -m "feat(multi-axis): <descriptive message> (Task N)"

2. Push to remote:
   git push

3. Update `.orchestra/orchestrator/.orchestrator-only/progress.yaml`:
   - Set task status to 'completed'
   - Record commit hash
   - Record completion timestamp
   - Add verification notes

4. Proceed to Step 5a (Post-Verification Closeout)
```

**If ANY check FAILS:**
```
1. Clear `.orchestra/handover/completion-signal.md`

2. Create failure report in `completion-signal.md`:
   ## Verification Failed

   **Failed Checks:**
   - [Check name]: [Reason]

   **Attempt:** N of 3

   **Required Actions:**
   - [Specific fix needed]

3. Update `.orchestra/orchestrator/.orchestrator-only/progress.yaml`:
   - Increment fail_count
   - Record failure timestamp
   - Add failure notes

4. Tell implementor: "Verification failed. Read completion-signal.md for feedback."

5. If fail_count >= 3:
   - Escalate to human
   - Do NOT proceed with task
```

### 5a. Post-Verification Closeout (MANDATORY)

**After task PASSES verification, you MUST complete ALL of these steps:**

```
✅ 1. Create verification results file
   CREATE `.orchestra/orchestrator/results/task-XXX-results.md`
   USE template: `.orchestra/common/templates/task-results-template.md`

✅ 2. Capture screenshot (if visual/integration task)
   SAVE to `.orchestra/orchestrator/results/screenshots/task-XXX-description.png`

✅ 3. Update progress.yaml
   - Add task to history with commit hash
   - Update stats (completed count)
   - Set note to reflect completion

✅ 4. Update SpecKit tasks.md
   - Mark associated SpecKit tasks with [x]

✅ 5. Update manifest.yaml
   - Add commit hash to completed task
   - Update status to "completed"

✅ 6. Clear completion-signal.md
   DELETE the file (not just empty content)

✅ 7. Commit closeout
   git add -A && git commit -m "verify(Task XXX): VERIFIED - description"

✅ 8. Run task-closeout-check.ps1
   .\.orchestra\orchestrator\scripts\task-closeout-check.ps1
   MUST PASS before preparing next task
```

**⛔ DO NOT prepare the next task until `task-closeout-check.ps1` PASSES.**

### 6. Prepare Next Task

⚠️ **CRITICAL: Follow the Pre-Flight Protocol at the top of this file!**

```
1. READ this file (`.orchestra/docs/readme.md`) - NOT from memory!
2. DELETE old `.orchestra/handover/current-task.md`
3. COPY template from `.orchestra/common/templates/current-task-template.md`
4. READ `.orchestra/orchestrator/.orchestrator-only/manifest.yaml` for next task details
5. READ SpecKit `tasks.md` for detailed requirements
6. FILL every section in template (content or N/A with reason)
7. CREATE `.orchestra/orchestrator/.orchestrator-only/verification/task-XXX.yaml` with hidden criteria
8. COMPLETE pre-flight checklist in template
9. SAVE checklist to `.orchestra/orchestrator/.orchestrator-only/preflight/orchestrator-preflight-XXX.md`
10. DELETE checklist section from current-task.md
11. CLEAR `.orchestra/handover/completion-signal.md`
12. Invoke implementor: "Read `.orchestra/handover/agent_readme.md` and complete your task"
```

---

## Verification Severity Levels

Every check in verification files MUST have a severity. Orchestrator CANNOT change severity during verification.

| Severity | Meaning | If Failed |
|----------|---------|-----------|
| **BLOCKING** | Fundamental requirement | Task FAILED - must fix |
| **MAJOR** | Significant quality issue | Task FAILED - must fix |
| **MINOR** | Small issue, functional | Task PASSED with note (log tech debt) |
| **INFO** | Observation only | Task PASSED (logged for reference) |

### Decision Rules

```
ANY BLOCKING fail  → Task FAILED (return for rework)
ANY MAJOR fail     → Task FAILED (return for rework)
MINOR fails only   → Task PASSED with notes
INFO only          → Task PASSED
```

### Why Severity is Immutable

If orchestrator can downgrade severity during verification:
- "This MAJOR is really just a MINOR..."
- "It works, so let's call it INFO..."
- → Sprint 011 failure mode (56 tasks of accumulated "minor" issues)

Severity is set when the verification yaml is **created**, not when it's **executed**.

---

## Quality Gates (MANDATORY)

Every task verification includes these **blocking** checks:

| Check | Command | Blocks Verification? |
|-------|---------|---------------------|
| Task tests pass | `flutter test <task_test>` | ✅ YES |
| Sprint unit tests pass | `flutter test test/unit/multi_axis/` | ✅ YES |
| Sprint widget tests pass | `flutter test test/widget/multi_axis/` | ✅ YES |
| Static analysis (impl) | `flutter analyze <impl_path>` | ✅ YES |
| Static analysis (test) | `flutter analyze <test_path>` | ✅ YES |

**If ANY check fails, task is returned for rework.**

---

## 🖼️ Visual Verification (MANDATORY for INTEGRATION/VISUAL Tasks)

### Task Categories

| Category | Description | Screenshot Required |
|----------|-------------|---------------------|
| **INFRASTRUCTURE** | Creates classes/logic NOT yet integrated | ❌ No (premature) |
| **INTEGRATION** | Wires components INTO BravenChartPlus | ✅ BLOCKING |
| **VISUAL** | Modifies existing rendering output | ✅ BLOCKING |

### ⛔ PROHIBITED TOOLS - DO NOT USE ⛔

| Tool | Why It's Wrong |
|------|----------------|
| `flutter run` directly | Kills app when terminal is reused |
| `run_in_terminal` with Flutter | Same problem - stdin interference |
| `tools/flutter_runner.py` | Deprecated - use flutter_agent.py instead |

### ✅ REQUIRED TOOLS

| Phase | Actor | Tool | Purpose |
|-------|-------|------|---------|
| CAPTURE | Implementor | `flutter_agent.py` | Run app, take screenshot |
| VIEW | Orchestrator | Chrome DevTools MCP | View existing PNG, verify content |

### Implementor: Screenshot Capture

```powershell
# Start Flutter in SEPARATE window
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\path\to\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_NNN_demo.dart -d chrome"

# Wait for ready
python tools/flutter_agent/flutter_agent.py wait --timeout 60

# Take screenshot
python tools/flutter_agent/flutter_agent.py screenshot --output screenshots/task_NNN_verification.png

# Stop app
python tools/flutter_agent/flutter_agent.py stop
```

### Orchestrator: Screenshot Viewing

```
# Open screenshot in browser via file:// URL
mcp_chrome-devtoo_new_page(url: "file:///E:/full/path/to/screenshot.png")

# Take screenshot (returns image to agent for analysis)
mcp_chrome-devtoo_take_screenshot()

# Analyze content against verification criteria

# Close when done
mcp_chrome-devtoo_close_page(pageIdx: 1)
```

### ⚠️ CRITICAL: "Screenshot exists" ≠ "Screenshot is correct"

An implementor could create an empty/wrong image file that passes existence checks.
You MUST view the actual content via Chrome DevTools MCP to verify correctness.

---

## SpecKit Traceability

### SpecKit Artifacts (Authority Level)

| Artifact | Authority | Orchestrator Must |
|----------|-----------|-------------------|
| `spec.md` | **BINDING** | Follow all FR-xxx requirements |
| `data-model.md` | **BINDING** | Match entity definitions exactly |
| `contracts/*.dart` | **BINDING** | Implementor must match code structure |
| `tasks.md` | **BINDING** | Cover all tasks (can consolidate) |
| `plan.md` | Guidance | Reference for approach |
| `research.md` | Guidance | Reference for decisions |

### The Flow

```
SpecKit Process (DO NOT MODIFY)
├── spec.md → plan.md → research.md → contracts/
│                              ↓
│                         tasks.md (granular tasks)
│                              ↓
└── Orchestrator Consolidation Layer
         ├── manifest.yaml (consolidated tasks)
         │     └── speckit_tasks: [T001, T002, ...]  ← TRACEABILITY
         │
         └── After each task completion:
               1. Update manifest.yaml (status, commit)
               2. Update tasks.md checkboxes
               3. Update progress.yaml
```

---

## Anti-Patterns to Watch For

- [ ] Tests that only check `findsOneWidget`
- [ ] New files only (no modifications) for integration tasks
- [ ] Config classes that aren't used anywhere
- [ ] "Verification passed" without running commands
- [ ] Same commit message as task title (lazy completion)
- [ ] **Using `flutter run` directly instead of flutter_agent.py**
- [ ] **Screenshot "verified" without actually viewing the image content**
- [ ] **Skipping accept-signal-check before verification**

---

## 📋 Handover Completeness Checklist

**CRITICAL**: Before invoking implementor, verify the handover is complete for a **NEW agent** (one with zero prior context).

### Completeness Verification

Ask yourself: "Could a fresh agent complete this task without asking ANY questions?"

| Check | Question |
|-------|----------|
| **File paths unambiguous** | Are ALL file paths relative to repo root? No ambiguity? |
| **CREATE files clear** | For each new file: path, purpose, AND export location specified? |
| **UPDATE files specific** | For each modified file: exact methods/changes listed? Code scaffold? |
| **TDD has sample data** | Are concrete test objects provided (not just test names)? |
| **INTEGRATION/VISUAL has demo** | Is runnable demo scaffold code included (not just file path)? |
| **MUST USE clear** | Are anti-patterns explicit (what to do AND what NOT to do)? |
| **Test location consistent** | Does test path match our structure? |

### The 100% Rule

**85% complete is NOT complete.** A handover must enable 100% autonomous completion.

If the implementor might need to ask "where does this go?" or "what should this look like?" → the handover is incomplete.

---

## Design Decisions & Lessons Learned

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-11-29 | Three-category visual verification | INFRASTRUCTURE/INTEGRATION/VISUAL categories |
| 2025-11-29 | Standalone demo files for visual tasks | Isolates testing, avoids polluting main app |
| 2025-11-29 | Mutual verification with hidden implementor validator | Catches orchestrator mistakes |
| 2025-11-29 | Delete-first protocol for current-task.md | Prevents contamination |
| 2025-11-30 | YOU TOUCH IT, YOU OWN IT policy | No "pre-existing" excuses for lint issues |
| 2025-12-01 | Chrome DevTools MCP for screenshot viewing | file:// URL works for local PNGs |

---

## See Also

- `.orchestra/orchestrator/readme.md` - Orchestrator role guide
- `.orchestra/implementor/readme.md` - Implementor role guide  
- `.orchestra/docs/research_log.md` - Issue/learning log
- `.orchestra/docs/solution-options.md` - Extension design discussions
