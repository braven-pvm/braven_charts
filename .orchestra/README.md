# Orchestrator README

⚠️ **THIS FOLDER IS FOR ORCHESTRATOR/VERIFIER ONLY** ⚠️

The implementor agent should NEVER be directed to read files in `.orchestra/` 
except for the `handover/` subfolder.

🚫 **ORCHESTRATOR: DO NOT READ `.orchestra/handover/.implementor/`** 🚫

The `.implementor/` folder contains the implementor's self-verification rules.
Reading it would defeat the purpose of mutual verification. The implementor
uses these rules to validate YOUR work - if you know what they check, you
might (consciously or not) optimize for passing checks rather than quality.

## Folder Structure

```
.orchestra/
├── manifest.yaml           # Full task list (HIDDEN)
├── progress.yaml           # Progress tracking (HIDDEN)
├── verification/           # Per-task verification criteria (HIDDEN)
│   ├── task-001.yaml
│   ├── task-002.yaml
│   ├── task-010-results.md        # Verification results record
│   ├── orchestrator-preflight-010.md  # Orchestrator audit trail
│   ├── screenshots/               # Visual verification artifacts
│   │   └── task-010-color-coded-axes.png
│   └── ...
├── templates/              # Templates for orchestrator use (HIDDEN)
│   ├── current-task-template.md       # ⭐ MUST use for every task
│   └── orchestrator-preflight-template.md
├── scripts/                # Automation scripts (HIDDEN)
│   ├── set-env.ps1         # ⭐ Source first: . .\.orchestra\scripts\set-env.ps1
│   ├── README.md           # Script documentation
│   ├── common/
│   │   └── check-utils.ps1 # Shared utilities
│   └── orchestrator/
│       ├── task-closeout-check.ps1 # ⭐ Verify previous task is closed out
│       ├── accept-signal-check.ps1 # ⭐ Verify implementor ran pre-signal check
│       ├── task-coverage.ps1      # SpecKit ↔ Orchestrator sync check
│       ├── verification-audit.ps1 # Audit verification records for completeness
│       └── handover-validate.ps1  # Validate current-task.md
├── handover/               # Communication channel (VISIBLE to implementor)
│   ├── AGENT_README.md     # ⭐ Implementor starts here (workflow instructions)
│   ├── current-task.md     # Current task (REPLACED each task)
│   ├── task-context.md     # Sprint background (SEMI-STABLE - update on phase change)
│   ├── completion-signal.md # Implementor signals done (CLEARED after verification)
│   └── .implementor/       # 🚫 ORCHESTRATOR DO NOT READ 🚫
│       ├── task-validator.md  # Implementor's validation rules
│       └── scripts/           # Implementor automation scripts
│           ├── validate-handover.ps1  # Validate task is actionable
│           └── pre-signal-check.ps1   # Check before signaling done (WRITES ARTIFACT)
└── artifacts/              # Outputs from verification and validation
    ├── screenshots/        # Visual verification captures
    └── pre-signal-checks/  # Verification artifacts from implementor (CHECKED BY accept-signal-check.ps1)
```

---

## 🚨 CRITICAL: Orchestrator Pre-Flight Protocol 🚨

**WHY THIS EXISTS**: Orchestrators can drift from documented process, operating from memory 
instead of following instructions. This protocol FORCES structural compliance.

**BEFORE preparing ANY task, the orchestrator MUST:**

### Step 0: Initialize Environment & Run Task Closeout Check (MANDATORY)

```powershell
# Source the environment (ALWAYS DO THIS FIRST)
. .\.orchestra\scripts\set-env.ps1

# Run the task closeout check script
.\.orchestra\scripts\orchestrator\task-closeout-check.ps1
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
.\.orchestra\scripts\orchestrator\task-closeout-check.ps1 -Fix
```

### Additional Orchestrator Scripts

| Script | When to Run | Purpose |
|--------|-------------|---------|
| `task-coverage.ps1` | Sprint planning, task prep | Verify SpecKit ↔ Orchestrator bidirectional sync |
| `verification-audit.ps1` | After verification | Audit verification records for completeness |
| `handover-validate.ps1` | Before handoff | Validate current-task.md is complete |

See `.orchestra/scripts/README.md` for full documentation.

### Step 1: Read This File
```
READ `.orchestra/readme.md` ← You are here. Do NOT rely on memory!
```

### Step 1: Delete Old Task
```
DELETE `.orchestra/handover/current-task.md`
```
This prevents contamination from previous task content.

### Step 2: Copy Template
```
COPY `.orchestra/templates/current-task-template.md` 
  TO `.orchestra/handover/current-task.md`
```

### Step 3: Fill Template
Fill EVERY section with either:
- **Actual content**, OR
- **`[N/A - Reason: explanation]`**

No `[TODO]` markers may remain in the final version.

### Step 4: Complete Pre-Flight Checklist
The template contains a checklist. Complete it honestly.

### Step 5: Save Audit Trail
```
COPY the completed checklist section
  TO `.orchestra/verification/orchestrator-preflight-NNN.md`
```
Then DELETE the checklist from current-task.md before implementor sees it.

### Step 6: Invoke Implementor
Tell implementor: **"Read `.orchestra/handover/AGENT_README.md` and complete your task"**

---

## Workflow

### 1. Feed Task (Human/Orchestrator)
- Copy task details from `manifest.yaml` to `handover/current-task.md`
- Update `progress.yaml` with start time
- Tell implementor: **"Read `.orchestra/handover/AGENT_README.md` and complete your task"**

> **IMPORTANT**: Always direct implementor to `AGENT_README.md` first, not `current-task.md`.
> This ensures consistent onboarding whether it's the same agent continuing or a new agent after handover.

### 2. Implementor Works
- Reads `AGENT_README.md` (workflow instructions)
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
.\.orchestra\scripts\orchestrator\accept-signal-check.ps1
```

This script verifies the implementor actually ran the pre-signal check:
- ✅ Artifact exists at `.orchestra/artifacts/pre-signal-checks/pre-signal-check-{task}.txt`
- ✅ Artifact shows PASSED status
- ⚠️ Artifact is not stale (>24 hours old)

**IF THIS FAILS:**
- Do NOT proceed with verification
- Do NOT commit anything
- Tell implementor: "Run `.orchestra/handover/.implementor/scripts/pre-signal-check.ps1` and fix all issues"
- Wait for them to actually run it and signal again

**This prevents implementors from skipping validation scripts entirely.**

### 4. Verify Task
- Read `verification/task-XXX.yaml` for this task
- Run verification commands
- Check adversarial conditions
- Capture screenshots if required

### 5. Decision
- **PASS**: Commit changes, update `progress.yaml`, feed next task
- **FAIL**: Clear `completion-signal.md`, provide feedback, implementor retries

### 6. Retrospective (After Each Task)
After each task completion:
1. Analyze what worked well and what could be improved
2. Document findings in `RESEARCH_LOG.md` → "Per-Task Retrospectives"
3. Add action items for process improvements
4. Track patterns emerging across tasks

## Key Principles

1. **Implementor never sees task count** - No "task 3 of 16"
2. **Implementor never sees verification criteria** - Prevents gaming
3. **Each task verified before next** - No bulk completion
4. **Integration tasks get extra scrutiny** - Must modify existing files
5. **Visual tasks require screenshots** - Can't fake images
6. **SpecKit tasks are source of truth** - Orchestrator consolidates but traces back
7. **Zero linter issues** - Static analysis must pass (BLOCKING)
8. **All tests must pass** - Sprint tests + task tests (BLOCKING)
9. **Severity is immutable** - Set when verification file created, NOT during execution

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
| Sprint integration tests pass | `flutter test test/integration/multi_axis_*.dart` | ✅ YES |
| Static analysis (impl) | `flutter analyze <impl_path>` | ✅ YES |
| Static analysis (test) | `flutter analyze <test_path>` | ✅ YES |

**If ANY check fails, task is returned for rework.**

See `verification/VERIFICATION_TEMPLATE.yaml` for standard checks.

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
| `checklists/` | Optional | Use for quality gates |

### Critical: Contracts Are Pre-Reviewed Code

The `specs/*/contracts/` folder contains **reviewed Dart code templates**:
- Class structures and field names
- Enum values (exact spelling!)
- Validation assertions
- Method signatures

**Handover MUST reference the contract** so implementor follows it exactly.

### The Flow

```
SpecKit Process (DO NOT MODIFY)
├── spec.md → plan.md → research.md → contracts/
│                              ↓
│                         tasks.md (56 granular tasks)
│                              ↓
└── Orchestrator Consolidation Layer
         ├── manifest.yaml (16 consolidated tasks)
         │     └── speckit_tasks: [T001, T002, ...]  ← TRACEABILITY
         │
         └── After each task completion:
               1. Update manifest.yaml (status, commit)
               2. Update tasks.md checkboxes
               3. Update progress.yaml
```

### Consolidation Guidelines

| Scenario | Consolidate? | Rationale |
|----------|--------------|-----------|
| Same file/module | ✅ Yes | Single logical unit |
| Enum + its tests | ✅ Yes | Trivial, always together |
| Model + copyWith + equality + tests | ✅ Yes | Standard pattern |
| Create + export to barrel | ✅ Yes | Always done together |
| Different concerns/files | ❌ No | Keep separate |
| Integration tasks | ❌ NEVER | High risk |

### After Each Task Completion

1. **manifest.yaml**: Update status, commit hash, verify speckit_tasks list
2. **tasks.md**: Check off completed SpecKit tasks with:
   - `[x]` checkbox
   - Orchestrator task reference
   - Commit hash
   - Any path/name deviations noted
3. **progress.yaml**: Update verification notes with SpecKit coverage

---

## Orchestrator Verification Flow (Detailed)

When the implementor signals completion, the orchestrator follows this exact flow:

### Step 1: Verify Task
```
1. Read `.orchestra/verification/task-XXX.yaml`
2. Execute each verification command from the yaml
3. Check all adversarial conditions
4. Capture screenshots if required
5. Record results (PASS/FAIL for each check)
```

### Step 2: Handle Result

**If ALL checks PASS:**
```
1. Stage and commit all changes:
   git add -A
   git commit -m "feat(multi-axis): <descriptive message> (Task N)"
   
2. Push to remote:
   git push

3. Update `.orchestra/progress.yaml`:
   - Set task status to 'completed'
   - Record commit hash
   - Record completion timestamp
   - Add verification notes

4. Proceed to Step 3 (Prepare Next Task)
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

3. Update `.orchestra/progress.yaml`:
   - Increment fail_count
   - Record failure timestamp
   - Add failure notes

4. Tell implementor: "Verification failed. Read completion-signal.md for feedback."

5. If fail_count >= 3:
   - Escalate to human
   - Do NOT proceed with task
```

### Step 3: Prepare Next Task

⚠️ **CRITICAL: Follow the Pre-Flight Protocol at the top of this file!**

```
1. READ this file (`.orchestra/readme.md`) - NOT from memory!
2. DELETE old `.orchestra/handover/current-task.md`
3. COPY template from `.orchestra/templates/current-task-template.md`
4. READ `.orchestra/manifest.yaml` for next task details
5. READ SpecKit `tasks.md` for detailed requirements
6. FILL every section in template (content or N/A with reason)
7. CREATE `.orchestra/verification/task-XXX.yaml` with hidden criteria
8. COMPLETE pre-flight checklist in template
9. SAVE checklist to `.orchestra/verification/orchestrator-preflight-XXX.md`
10. DELETE checklist section from current-task.md
11. CLEAR `.orchestra/handover/completion-signal.md`
12. Invoke implementor: "Read `.orchestra/handover/AGENT_README.md` and complete your task"
```

**Template sections that MUST be addressed:**
- [ ] Task Overview
- [ ] SpecKit Traceability  
- [ ] Deliverables (files to create AND modify)
- [ ] Technical Context
- [ ] TDD Requirements
- [ ] Code Scaffolds
- [ ] Visual Verification (REQUIRED if rendering task)
- [ ] Quality Gates
- [ ] Completion Protocol

### Flow Diagram
```
┌─────────────────┐
│  Implementor    │
│  Signals Done   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Run Hidden     │
│  Verification   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────┐  ┌───────┐
│ PASS  │  │ FAIL  │
└───┬───┘  └───┬───┘
    │          │
    ▼          ▼
┌─────────┐ ┌─────────────┐
│ Commit  │ │ Fail Report │
│ & Push  │ │ fail_count++│
└────┬────┘ └──────┬──────┘
     │             │
     ▼             │
┌──────────┐       │
│ Update   │       │
│ Progress │       │
└────┬─────┘       │
     │             │
     ▼             │
┌──────────┐       │
│ Prepare  │       ▼
│ Next     │  ┌─────────────┐
│ Task     │  │ Retry or    │
└────┬─────┘  │ Escalate    │
     │        └─────────────┘
     ▼
┌──────────────┐
│ Retrospective│
│ (Document    │
│  learnings)  │
└──────┬───────┘
       │
       ▼
┌──────────┐
│ Invoke   │
│Implementor│
└──────────┘
```

---

## 🖼️ Screenshot & Visual Verification (MANDATORY)

**CRITICAL**: Visual verification requires the correct tooling.

### ⛔ PROHIBITED TOOLS - DO NOT USE ⛔

| Tool | Why It's Wrong |
|------|----------------|
| `flutter run` directly | Kills app when terminal is reused |
| `run_in_terminal` with Flutter | Same problem - stdin interference |
| Chrome DevTools MCP (`mcp_chrome-devtoo_*`) | Wrong tool - designed for browser automation, not Flutter |
| `tools/flutter_runner.py` | Deprecated - use flutter_agent.py instead |
| `open_simple_browser` with file:// | Fails - only HTTP/HTTPS supported |

### ✅ REQUIRED TOOL: flutter_agent.py

**Location**: `tools/flutter_agent/flutter_agent.py`

This tool was specifically designed for AI agents to:
- Run Flutter in a **separate PowerShell window**
- Communicate via **file-based IPC** (not stdin)
- Take screenshots without killing the app
- Support hot reload during development

### Visual Verification Workflow

#### Step 1: Implementor Creates Screenshot

The implementor runs the Flutter demo using `flutter_agent.py` and captures a screenshot.
Screenshots are saved to the working directory (typically `example/flutter_01.png`).

#### Step 2: Orchestrator Verifies Screenshot EXISTS

```powershell
# Check screenshot was created
Get-ChildItem 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example\flutter_*.png' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

#### Step 3: Orchestrator Verifies Screenshot CONTENT

**Option A: Human-in-the-loop verification**
- Orchestrator asks human to view the screenshot file
- Human confirms visual elements match requirements
- Human provides pass/fail decision

**Option B: Describe requirements for future automation**
- Document exactly what should be visible
- Create checklist for visual elements
- Mark as "pending automated visual verification tooling"

### Current Limitation (Acknowledged)

We do not currently have a reliable way for the AI agent to "see" screenshot content.
- Chrome DevTools MCP is for browser automation, not viewing local files
- PNG files cannot be read as text
- `open_simple_browser` doesn't support file:// URLs

**For now**: Visual verification requires either:
1. Human confirmation of screenshot content, OR
2. Trust that the implementor's screenshot + passing tests = correct visual output

### Example Verification Entry

```yaml
visual:
  - check: "Screenshot captured via flutter_agent.py"
    severity: MAJOR
    command: 'Get-ChildItem "example/flutter_*.png" | Sort-Object LastWriteTime -Descending | Select-Object -First 1'
    expected: "File exists with recent timestamp"
    
  - check: "Visual elements verified"
    severity: MAJOR
    manual_check: true  # Requires human verification
    procedure: |
      1. Open screenshot file in image viewer
      2. Verify: Left axis is BLUE, Right axis is RED
      3. Verify: Two data series visible with correct colors
    expected: "Visual elements match spec requirements"
```

### Future Improvement

Consider adding:
- Image comparison tooling (golden tests)
- LLM vision API integration for automated screenshot analysis
- Structured screenshot metadata logging

---

## Anti-Patterns to Watch For

- [ ] Tests that only check `findsOneWidget`
- [ ] New files only (no modifications) for integration tasks
- [ ] Config classes that aren't used anywhere
- [ ] "Verification passed" without running commands
- [ ] Same commit message as task title (lazy completion)
- [ ] **Using `flutter run` directly instead of flutter_agent.py**
- [ ] **Using Chrome DevTools MCP for Flutter screenshots**
- [ ] **Screenshot "verified" without actually viewing the image content**

---

## Visual/Integration Task Categories

Tasks fall into three categories that determine visual verification requirements:

| Category       | Description                              | Visual Verification | Screenshot Required |
|----------------|------------------------------------------|---------------------|---------------------|
| **INFRASTRUCTURE** | Creates classes/logic NOT yet integrated | ❌ N/A (premature)  | ❌ No               |
| **INTEGRATION**    | Wires components INTO BravenChartPlus    | ✅ Required         | ✅ BLOCKING         |
| **VISUAL**         | Modifies existing rendering output       | ✅ Required         | ✅ BLOCKING         |

### ⚠️ CRITICAL: Category MUST Be Set in manifest.yaml

Every task in `manifest.yaml` MUST have a `category:` field:

```yaml
- id: 13
  title: "Update Crosshair to Use Per-Axis Bounds"
  status: "pending"
  speckit_tasks: ["T043", "T044", "T041"]
  category: "integration"  # REQUIRED: infrastructure | integration | visual
```

**handover-validate.ps1** enforces:
- manifest.yaml has category for task
- INTEGRATION/VISUAL tasks have Section 7 in handover
- Verification YAML exists before handover

**task-closeout-check.ps1** enforces:
- INFRASTRUCTURE tasks: screenshot optional
- INTEGRATION/VISUAL tasks: screenshot BLOCKING (task fails without it)

### INFRASTRUCTURE Tasks

These create building blocks (painters, layout managers, data models) but do NOT 
wire them into the main widget. Visual verification is **premature** because 
there's nothing to see yet.

**In Section 7 of current-task.md, use:**
```markdown
**[N/A - Reason: Infrastructure task]**

This task creates [component] but does NOT integrate it into BravenChartPlus.
Visual verification will occur in [future integration task].
```

### INTEGRATION / VISUAL Tasks

These wire components into BravenChartPlus or modify rendering. Require a 
**standalone demo file** (NOT modifications to main.dart).

**Demo location:** `example/lib/demos/task_NNN_name_demo.dart`

**Why standalone demos?**
- Self-contained (no navigation required)
- Can be run directly with flutter_agent
- Doesn't pollute main example app
- Clear what's being tested

### Flutter Agent Controller (MANDATORY for Visual Tasks)

**Location**: `tools/flutter_agent/flutter_agent.py`

### ⛔ CRITICAL: Only Use flutter_agent.py ⛔

**PROHIBITED - Never use these for Flutter:**
| Prohibited Tool | Why It Fails |
|-----------------|-------------|
| `flutter run` directly | Killed when terminal is reused |
| `run_in_terminal` with Flutter | Same stdin interference problem |
| Chrome DevTools MCP | Wrong tool - for browser, not Flutter |
| `tools/flutter_runner.py` | Deprecated - replaced by flutter_agent |

**REQUIRED**: Always use `flutter_agent.py` for running Flutter apps and taking screenshots.

### Why flutter_agent.py?

Flutter runs as an interactive process. When an AI agent uses `run_in_terminal`:
1. Flutter starts in Terminal A
2. Agent sends another command → goes to Terminal A
3. **Command kills Flutter** (stdin interference)

`flutter_agent.py` solves this:
1. Flutter runs in **separate PowerShell window** via `Start-Process`
2. Commands go via **file-based IPC** (JSON files)
3. Agent's terminal **never touches Flutter's stdin**

### Orchestrator: Add to `current-task.md` for Visual Tasks

```markdown
## Visual Verification (INTEGRATION/VISUAL Task)

### Step 1: Create Standalone Demo
Path: `example/lib/demos/task_NNN_demo.dart`

[Provide minimal self-contained demo code]

### Step 2: Flutter Agent Workflow

⛔ DO NOT use `flutter run` directly or Chrome DevTools MCP!
✅ ONLY use flutter_agent.py as shown below:

1. Start Flutter in SEPARATE window:
   ```powershell
   Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
     "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_NNN_demo.dart -d chrome"
   ```

2. Wait for app ready (in your terminal - this is safe):
   ```powershell
   cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'
   python ..\tools\flutter_agent\flutter_agent.py wait --timeout 60
   ```

3. Take screenshot:
   ```powershell
   python ..\tools\flutter_agent\flutter_agent.py screenshot
   # Screenshot saved to example/flutter_XX.png
   ```

4. Verify screenshot exists:
   ```powershell
   Get-ChildItem flutter_*.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1
   ```

5. Stop when done:
   ```powershell
   python ..\tools\flutter_agent\flutter_agent.py stop
   ```

### Expected Visual Output:
[Describe EXACTLY what should be visible]
```

**Full documentation**: `tools/flutter_agent/README.md` and `tools/flutter_agent/FLUTTER_AGENT_GUIDE.md`

---

## Design Decisions & Lessons Learned

This section captures iterative discoveries while developing the orchestrator pattern.

### Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-11-29 | **Three-category visual verification** | INFRASTRUCTURE/INTEGRATION/VISUAL categories. Infrastructure tasks (new classes not yet wired in) don't need screenshots - that's premature. Only INTEGRATION/VISUAL tasks require visual proof. |
| 2025-11-29 | **Standalone demo files for visual tasks** | Visual verification uses `example/lib/demos/task_NNN_demo.dart` not modifications to main.dart. Isolates testing, avoids polluting main app. |
| 2025-11-29 | **Mutual verification with hidden implementor validator** | Implementor validates orchestrator's task structure using `.implementor/task-validator.md` which orchestrator cannot read. Catches orchestrator mistakes BEFORE implementation starts. |
| 2025-11-29 | **Template-enforced handover with pre-flight checklist** | Orchestrator drifted from process (operated from memory). Templates FORCE structural compliance. See RESEARCH_LOG.md "Who Watches the Orchestrator?" |
| 2025-11-29 | Delete-first protocol for current-task.md | Prevents contamination from previous task; forces fresh template copy |
| 2025-11-29 | Orchestrator audit trail (preflight records) | Creates accountability; human can verify orchestrator followed process |
| 2025-01-08 | `current-task.md` is completely replaced each task | Clean slate for implementor - no confusion from previous task remnants |
| 2025-01-08 | Implementor starts at `AGENT_README.md`, not `current-task.md` | Ensures consistent onboarding whether same agent or handover to new agent |
| 2025-01-08 | Translation Layer approach (ADR-001) | Orchestrator translates specs to explicit instructions; implementor doesn't interpret specs |
| 2025-01-08 | Hidden verification with fail_count | Prevents gaming; max 3 attempts before escalation |

### Open Questions

- ~~Should `task-context.md` persist across tasks or be reset too?~~ **RESOLVED**: Semi-stable. Persists across tasks, but MUST be updated when phase changes.
- How to handle visual task verification when Flutter Agent isn't available?
- What metadata should be captured in verification artifacts?

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
| **Test location consistent** | Does test path match our structure (`test/unit/multi_axis/` for this sprint)? |

### Common Gaps to Watch For

| Gap | Symptom | Fix |
|-----|---------|-----|
| "UPDATE: Use X" | Vague, no specifics | Add integration scaffold showing exact changes |
| Test path mismatch | AGENT_README says one place, task says another | Use sprint-specific path |
| No demo code | Just says "create demo" | Add full runnable demo scaffold |
| No sample test data | TDD section lists test names only | Add concrete objects to copy-paste |
| Missing export | New class created but barrel file not specified | Add "Export To" column |

### The 100% Rule

**85% complete is NOT complete.** A handover must enable 100% autonomous completion.

If the implementor might need to ask "where does this go?" or "what should this look like?" → the handover is incomplete.

---

### Process Improvements to Consider

- [ ] Automated verification script that reads task-XXX.yaml
- [ ] Template generation for common task types (enum, model, widget)
- [ ] Integration with git hooks for pre-commit verification
