# Command: `orchestra complete`

> **Navigation**: [Phase 1 Index](../readme.md) | **Prev**: [verify](verify.md) | **Next**: [status](status.md)

---

## Purpose

Complete the current task after successful verification. Archives task artifacts, updates progress, optionally commits changes, and prepares for the next task.

## Synopsis

```bash
orchestra complete [OPTIONS] [MESSAGE]
```

## Arguments

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `MESSAGE` | STR | No | Commit message (if --commit) |

## Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--task` | INT | No | current | Task ID to complete |
| `--commit` | FLAG | No | config | Commit changes to git |
| `--no-commit` | FLAG | No | false | Skip git commit |
| `--push` | FLAG | No | false | Push after commit |
| `--next` | FLAG | No | true | Prepare next task automatically |
| `--no-next` | FLAG | No | false | Don't prepare next task |
| `--force` | FLAG | No | false | Complete without verification |
| `--json` | FLAG | No | false | Output JSON format |

## Preconditions

1. **Task in progress**: Task must have status "in_progress"
2. **Verification passed**: Latest verification must be PASSED (unless --force)
3. **Clean git state**: No merge conflicts (if --commit)

## Behavior

### Step 1: Validate Completion

```typescript
async function validateComplete(taskId: string, force: boolean): Promise<void> {
  /**
   * Validate task can be completed.
   * 
   * Throws:
   *   TaskNotInProgressError: Task not in in_progress state
   *   VerificationNotPassedError: Latest verification failed (without force)
   *   GitConflictError: Merge conflicts exist
   */
  const reportPath = path.join(
    '.orchestra', 'orchestrator', 'results', 
    `task-${taskId}-verification.yaml`
  );
  
  if (!force) {
    const report = readYaml(reportPath, VerificationReportSchema);
    if (report.overall !== 'PASSED') {
      throw new VerificationNotPassedError(report.failedChecks);
    }
  }
}
```

### Step 2: Archive Task

Create archive folder with all artifacts:

```
.orchestra/orchestrator/results/task-003/
├── metadata.json           # Completion metadata
├── current-task.md         # Original task handover
├── completion-signal.md    # Filled signal from implementor
├── verification-report.yaml # Verification results
└── verification/           # Task artifacts
    ├── y_axis_config.dart  # Copy of created file
    └── y_axis_config_test.dart
```

#### metadata.json

```json
{
  "task_id": 3,
  "title": "Create YAxisConfig Model",
  "category": "INTEGRATION",
  "completed_at": "2025-12-01T15:00:00Z",
  "attempts": 1,
  "duration_minutes": 45,
  "commit": "abc1234",
  "verification": {
    "overall": "PASSED",
    "blocking_passed": 3,
    "major_passed": 2,
    "minor_passed": 1
  },
  "files_created": [
    "lib/src/models/y_axis_config.dart",
    "test/unit/y_axis_config_test.dart"
  ],
  "speckit_tasks_completed": [
    "SPEC-011-3.1",
    "SPEC-011-3.2"
  ]
}
```

### Step 3: Update Progress

```yaml
# .orchestra/orchestrator/.orchestrator-only/progress.yaml
current_task: null  # Will be set by prepare
current_phase: 1

summary:
  total: 12
  completed: 3      # Incremented
  in_progress: 0    # Decremented
  pending: 9
  failed: 0

tasks:
  3:
    status: "completed"
    attempts: 1
    started_at: "2025-12-01T14:15:00Z"
    completed_at: "2025-12-01T15:00:00Z"
    commit: "abc1234"
```

### Step 4: Update Manifest

```yaml
# .orchestra/orchestrator/.orchestrator-only/manifest.yaml
tasks:
  - id: 3
    status: "completed"     # Changed from "in-progress"
    commit: "abc1234"
```

### Step 5: Update SpecKit Traceability

If task has `speckit_tasks`, mark them complete in `specs/*/tasks.md`:

```typescript
async function updateSpeckitTasks(speckitTasks: string[]): Promise<void> {
  for (const taskRef of speckitTasks) {
    // Parse SPEC-011-3.1 → specs/011-*/tasks.md, item 3.1
    const { specId, itemId } = parseSpeckitRef(taskRef);
    const tasksFile = await findTasksFile(specId);
    await markComplete(tasksFile, itemId);
  }
}
```

### Step 6: Clear Handover

```bash
# Remove handover files (archived already)
rm .orchestra/handover/current-task.md
rm .orchestra/handover/completion-signal.md
rm -rf .orchestra/handover/verification/*

# Keep templates
# Keep task-context.md (will be updated by prepare)
```

### Step 7: Git Commit (if enabled)

```bash
# Stage all changes
git add .

# Commit with message
git commit -m "feat(orchestra): Task 3 - Create YAxisConfig Model

- Created lib/src/models/y_axis_config.dart
- Created test/unit/y_axis_config_test.dart
- All verification checks passed

Orchestra: Task 3/12 complete"

# Push if requested
git push origin HEAD
```

### Step 8: Prepare Next Task (if enabled)

```typescript
if (prepareNext) {
  const nextTaskId = findNextPendingTask(manifest);
  if (nextTaskId) {
    await prepareTask(nextTaskId);
  } else {
    // Check if sprint complete
    if (allTasksComplete(manifest)) {
      await handleSprintComplete(manifest);
    }
  }
}
```

## Output

### Success (Human)

```
Task Completed
─────────────────────────────────────────
Task: 3 - Create YAxisConfig Model
Status: ✓ COMPLETED

Archived:
  ✓ .orchestra/orchestrator/results/task-003/
  ✓ metadata.json
  ✓ verification-report.yaml
  ✓ Artifacts copied

Progress:
  ✓ progress.yaml updated (3/12 complete)
  ✓ manifest.yaml updated

SpecKit:
  ✓ SPEC-011-3.1 marked complete
  ✓ SPEC-011-3.2 marked complete

Git:
  ✓ Committed: abc1234
  ✓ Message: "feat(orchestra): Task 3 - Create YAxisConfig Model"

Next Task: 4 - Create YAxisConfigCollection
  → Run 'orchestra prepare' or handover is ready
```

### Sprint Complete (Human)

```
Sprint Completed!
─────────────────────────────────────────
Sprint: 011-multi-axis-normalization
Tasks: 16/16 complete

Summary:
  First-attempt passes: 12
  Second-attempt passes: 3
  Third-attempt passes: 1
  Escalations: 0

Duration: 5 days
Commits: 16

All verification checks passed.
Consider running retrospective review.
```

### JSON Output

```json
{
  "success": true,
  "task": {
    "id": 3,
    "title": "Create YAxisConfig Model",
    "status": "completed",
    "attempts": 1,
    "commit": "abc1234"
  },
  "archive_path": ".orchestra/orchestrator/results/task-003/",
  "progress": {
    "completed": 3,
    "total": 12,
    "remaining": 9
  },
  "speckit_tasks_completed": ["SPEC-011-3.1", "SPEC-011-3.2"],
  "git": {
    "committed": true,
    "commit_hash": "abc1234",
    "pushed": false
  },
  "next_task": {
    "id": 4,
    "title": "Create YAxisConfigCollection",
    "prepared": true
  }
}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Task not in progress |
| 2 | Verification not passed |
| 3 | Archive failed |
| 4 | Git commit failed |
| 5 | SpecKit update failed |

## Examples

```bash
# Complete current task (uses config for commit behavior)
orchestra complete

# Complete with commit message
orchestra complete "feat: add YAxisConfig model"

# Complete and push
orchestra complete --push "feat: add YAxisConfig model"

# Complete without preparing next task
orchestra complete --no-next

# Force complete without verification
orchestra complete --force

# Skip git commit
orchestra complete --no-commit

# Complete specific task
orchestra complete --task 3

# JSON output
orchestra complete --json
```

## Commit Message Format

Default format (configurable in config.yaml):

```
{{type}}({{scope}}): Task {{task_id}} - {{title}}

{{body}}

Orchestra: Task {{task_id}}/{{total}} complete
```

Configuration:

```yaml
# .orchestra/config.yaml
git:
  commit:
    type: "feat"
    scope: "orchestra"
    include_files: true
    include_footer: true
```

## Implementation Notes

1. **Atomicity**: All updates succeed or all rollback
2. **Archive immutability**: Once archived, task folder is read-only
3. **Idempotency**: Completing already-complete task is no-op
4. **Backup**: Keep backup before clearing handover
5. **Metrics**: Track duration, attempts for sprint retrospective
