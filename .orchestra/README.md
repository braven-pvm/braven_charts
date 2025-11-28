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
- Tell implementor: "Read `.orchestra/handover/current-task.md` and complete it"

### 2. Implementor Works
- Reads `current-task.md` and `task-context.md`
- Implements the task
- Stages changes
- Writes to `completion-signal.md`
- Says "Task complete - ready for review"

### 3. Verify (Human or Verifier Agent)
- Read `verification/task-XXX.yaml` for this task
- Run verification commands
- Check adversarial conditions
- Capture screenshots if required

### 4. Decision
- **PASS**: Commit changes, update `progress.yaml`, feed next task
- **FAIL**: Clear `completion-signal.md`, provide feedback, implementor retries

## Key Principles

1. **Implementor never sees task count** - No "task 3 of 16"
2. **Implementor never sees verification criteria** - Prevents gaming
3. **Each task verified before next** - No bulk completion
4. **Integration tasks get extra scrutiny** - Must modify existing files
5. **Visual tasks require screenshots** - Can't fake images

## Anti-Patterns to Watch For

- [ ] Tests that only check `findsOneWidget`
- [ ] New files only (no modifications) for integration tasks
- [ ] Config classes that aren't used anywhere
- [ ] "Verification passed" without running commands
- [ ] Same commit message as task title (lazy completion)
