# Command: `orchestra status`

> **Navigation**: [Phase 1 Index](../readme.md) | **Prev**: [complete](complete.md)

---

## Purpose

Display the current state of the Orchestra sprint. Shows progress, current task, phase information, and recent activity.

## Synopsis

```bash
orchestra status [OPTIONS]
```

## Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--task` | INT | No | - | Show details for specific task |
| `--phase` | INT | No | - | Show details for specific phase |
| `--history` | FLAG | No | false | Include task history |
| `--metrics` | FLAG | No | false | Include sprint metrics |
| `--json` | FLAG | No | false | Output JSON format |
| `--brief` | FLAG | No | false | One-line summary only |

## Behavior

### Default View

Shows:
1. Sprint information
2. Current task and phase
3. Progress summary
4. Recent activity (last 3 tasks)

### Task Detail View (`--task N`)

Shows:
1. Task details (title, category, description)
2. Dependencies and their status
3. Deliverables
4. Attempt history
5. Verification results (if run)

### Phase Detail View (`--phase N`)

Shows:
1. Phase information
2. All tasks in phase with status
3. Phase progress

### Metrics View (`--metrics`)

Shows:
1. First-attempt pass rate
2. Average attempts per task
3. Common failure patterns
4. Duration statistics

## Output

### Default (Human)

```
Orchestra Status
════════════════════════════════════════════════════════════

Sprint: 011-multi-axis-normalization
Branch: 011-multi-axis-normalization
Started: 2025-11-25

Progress
────────────────────────────────────────
Tasks:    ████████████░░░░░░░░ 12/16 (75%)
Phase:    Phase 3: Integration (8-12)

Current Task
────────────────────────────────────────
Task 13: Multi-axis renderer integration
Category: INTEGRATION
Status: in_progress
Attempt: 1 of 3
Started: 2025-12-01 10:30

Dependencies:
  ✓ Task 12: Axis layout calculator

Deliverables:
  • lib/src/renderers/multi_axis_renderer.dart
  • test/unit/multi_axis_renderer_test.dart

Recent Activity
────────────────────────────────────────
Task 12: Axis layout calculator     ✓ completed  (1 attempt)
Task 11: Normalization pipeline     ✓ completed  (2 attempts)
Task 10: Scale transformer          ✓ completed  (1 attempt)

Next: Implementor working on Task 13
```

### Brief (`--brief`)

```
Orchestra: 011-multi-axis-normalization | Task 13/16 | Phase 3/4 | 75% complete
```

### Task Detail (`--task 11`)

```
Task Details
════════════════════════════════════════════════════════════

Task 11: Normalization pipeline
Category: INTEGRATION
Phase: 3 (Integration)
Status: completed

Description:
  Create the normalization pipeline that processes data points
  through each axis's normalizer and produces normalized coordinates.

Dependencies:
  ✓ Task 9: Multi-axis normalizer
  ✓ Task 10: Scale transformer

Deliverables:
  ✓ lib/src/pipeline/normalization_pipeline.dart
  ✓ test/unit/normalization_pipeline_test.dart

Attempt History:
  Attempt 1: FAILED (2025-11-30 14:00)
    - V11.4 FAILED: Tests don't cover edge case for empty data
    
  Attempt 2: PASSED (2025-11-30 16:30)
    - All 12 checks passed

Verification Summary:
  BLOCKING: 4/4 passed
  MAJOR: 3/3 passed
  MINOR: 2/2 passed

Commit: def5678
Completed: 2025-11-30 16:30
Duration: 2.5 hours
```

### Phase Detail (`--phase 3`)

```
Phase Details
════════════════════════════════════════════════════════════

Phase 3: Integration
Tasks: 9, 10, 11, 12, 13

Status:
  ✓ Task 9:  Multi-axis normalizer      completed
  ✓ Task 10: Scale transformer          completed
  ✓ Task 11: Normalization pipeline     completed
  ✓ Task 12: Axis layout calculator     completed
  → Task 13: Multi-axis renderer        in_progress

Progress: ████████████████░░░░ 4/5 (80%)
```

### Metrics (`--metrics`)

```
Sprint Metrics
════════════════════════════════════════════════════════════

Pass Rates:
  First attempt:  10/12 (83%)
  Second attempt: 2/12 (17%)
  Third attempt:  0/12 (0%)
  Escalated:      0/12 (0%)

Average Attempts: 1.17

Duration:
  Total time: 5 days
  Average per task: 3.2 hours
  Fastest: Task 1 (0.5 hours)
  Slowest: Task 8 (6 hours)

Common Failures:
  "Tests don't cover edge case": 3 occurrences
  "Analyzer warning": 2 occurrences
  "Missing documentation": 1 occurrence

Verification Check Stats:
  Total checks run: 144
  Passed: 138 (96%)
  Failed: 6 (4%)
```

### JSON Output

```json
{
  "sprint": {
    "id": "011",
    "name": "multi-axis-normalization",
    "branch": "011-multi-axis-normalization",
    "started_at": "2025-11-25T00:00:00Z",
    "status": "in_progress"
  },
  "progress": {
    "total": 16,
    "completed": 12,
    "in_progress": 1,
    "pending": 3,
    "failed": 0,
    "percentage": 75
  },
  "current_phase": {
    "id": 3,
    "name": "Integration",
    "tasks": [9, 10, 11, 12, 13],
    "completed": 4,
    "total": 5
  },
  "current_task": {
    "id": 13,
    "title": "Multi-axis renderer integration",
    "category": "INTEGRATION",
    "status": "in_progress",
    "attempt": 1,
    "started_at": "2025-12-01T10:30:00Z"
  },
  "recent_tasks": [
    {"id": 12, "title": "Axis layout calculator", "status": "completed", "attempts": 1},
    {"id": 11, "title": "Normalization pipeline", "status": "completed", "attempts": 2},
    {"id": 10, "title": "Scale transformer", "status": "completed", "attempts": 1}
  ]
}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | No orchestra initialized |
| 2 | Task not found |
| 3 | Phase not found |

## Examples

```bash
# Default status
orchestra status

# Brief one-liner
orchestra status --brief

# Specific task details
orchestra status --task 11

# Specific phase details
orchestra status --phase 3

# Include full history
orchestra status --history

# Include metrics
orchestra status --metrics

# All details
orchestra status --history --metrics

# JSON output
orchestra status --json

# Combine options
orchestra status --task 11 --json
```

## Visual Elements

The CLI uses Rich library for:
- Progress bars for completion percentage
- Colored status indicators (✓ green, ✗ red, → yellow)
- Tables for structured data
- Panels for sections

Disable with `--no-color` or `NO_COLOR` environment variable.

## Implementation Notes

1. **Fast**: Status should return in <100ms
2. **Cached**: Can cache derived data (percentages, etc.)
3. **Offline**: Works without network access
4. **Safe**: Read-only, never modifies state
