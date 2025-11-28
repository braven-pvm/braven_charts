# Orchestrator README

⚠️ **THIS FOLDER IS FOR ORCHESTRATOR/VERIFIER ONLY** ⚠️

The implementor agent should NEVER be directed to read files in `.orchestra/` 
except for the `handover/` subfolder.

## Folder Structure

```
.orchestra/
├── manifest.yaml           # Full task list (HIDDEN)
├── progress.yaml           # Progress tracking (HIDDEN)
├── verification/           # Per-task verification criteria (HIDDEN)
│   ├── task-001.yaml
│   ├── task-002.yaml
│   └── ...
├── handover/               # Communication channel (VISIBLE to implementor)
│   ├── AGENT_README.md     # ⭐ Implementor starts here (workflow instructions)
│   ├── current-task.md     # Current task for implementor
│   ├── task-context.md     # Background context
│   └── completion-signal.md # Implementor signals done here
└── artifacts/              # Outputs from verification
    └── screenshots/
```

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
- Writes to `completion-signal.md`
- Says "ready for review"

### 3. Verify (Human or Verifier Agent)
- Read `verification/task-XXX.yaml` for this task
- Run verification commands
- Check adversarial conditions
- Capture screenshots if required

### 4. Decision
- **PASS**: Commit changes, update `progress.yaml`, feed next task
- **FAIL**: Clear `completion-signal.md`, provide feedback, implementor retries

### 5. Retrospective (After Each Task)
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

---

## SpecKit Traceability

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
```
1. Read `.orchestra/manifest.yaml` for next task details
2. Analyze codebase for relevant context
3. Create `.orchestra/verification/task-XXX.yaml` with hidden criteria
4. Update `.orchestra/handover/current-task.md` with:
   - Task requirements (translated from spec)
   - Technical context (discovered from codebase)
   - TDD requirements (test file location, what to test)
   - Acceptance criteria (what "done" looks like)
5. Clear `.orchestra/handover/completion-signal.md`
6. Invoke implementor: "Read `.orchestra/handover/AGENT_README.md` and complete your task"
```

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

## Anti-Patterns to Watch For

- [ ] Tests that only check `findsOneWidget`
- [ ] New files only (no modifications) for integration tasks
- [ ] Config classes that aren't used anywhere
- [ ] "Verification passed" without running commands
- [ ] Same commit message as task title (lazy completion)

---

## Visual/Integration Tasks

For tasks requiring screenshots or running Flutter app interaction:

### Flutter Agent Controller

Located at `tools/flutter_agent/flutter_agent.py` - enables running Flutter in a separate process with file-based IPC.

**When to include in task instructions**:
- Task requires screenshot verification
- Task requires visual confirmation of rendering
- Task requires hot reload testing
- Task involves integration testing with running app

**Orchestrator must add to `current-task.md`** for visual tasks:

```markdown
## Screenshot Required

Use the Flutter Agent Controller to capture screenshots:

1. Start Flutter in separate window:
   ```powershell
   Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
     "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/main.dart -d chrome"
   ```

2. Wait for app ready:
   ```powershell
   cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'
   python ..\tools\flutter_agent\flutter_agent.py wait --timeout 60
   ```

3. Take screenshot:
   ```powershell
   python ..\tools\flutter_agent\flutter_agent.py screenshot --output ../screenshots/task-XXX.png
   ```

4. Stop when done:
   ```powershell
   python ..\tools\flutter_agent\flutter_agent.py stop
   ```
```

**Full documentation**: `tools/flutter_agent/README.md` and `tools/flutter_agent/FLUTTER_AGENT_GUIDE.md`

---

## Design Decisions & Lessons Learned

This section captures iterative discoveries while developing the orchestrator pattern.

### Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-01-08 | `current-task.md` is completely replaced each task | Clean slate for implementor - no confusion from previous task remnants |
| 2025-01-08 | Implementor starts at `AGENT_README.md`, not `current-task.md` | Ensures consistent onboarding whether same agent or handover to new agent |
| 2025-01-08 | Translation Layer approach (ADR-001) | Orchestrator translates specs to explicit instructions; implementor doesn't interpret specs |
| 2025-01-08 | Hidden verification with fail_count | Prevents gaming; max 3 attempts before escalation |

### Open Questions

- Should `task-context.md` persist across tasks or be reset too?
- How to handle visual task verification when Flutter Agent isn't available?
- What metadata should be captured in verification artifacts?

### Process Improvements to Consider

- [ ] Automated verification script that reads task-XXX.yaml
- [ ] Template generation for common task types (enum, model, widget)
- [ ] Integration with git hooks for pre-commit verification
