# Command: `orchestra prepare`

> **Navigation**: [Phase 1 Index](../readme.md) | **Prev**: [init](init.md) | **Next**: [verify](verify.md)

---

## Purpose

Prepare the handover folder for a specific task. Generates `current-task.md` from templates, updates `task-context.md`, and prepares the handover for the implementor.

## Synopsis

```bash
orchestra prepare [OPTIONS]
```

## Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--task` | INT | No | next | Task ID to prepare (default: next pending) |
| `--force` | FLAG | No | false | Prepare even if previous task incomplete |
| `--dry-run` | FLAG | No | false | Show what would be generated |
| `--json` | FLAG | No | false | Output JSON format |

## Preconditions

Before preparing a task:

1. **Previous task complete**: Unless `--force`, previous task must be completed
2. **Dependencies met**: All dependency tasks must be complete
3. **Task exists**: Task ID must exist in manifest
4. **Task pending**: Task status must be "pending"

## Behavior

### Step 1: Validate Preconditions

```typescript
async function validatePrepare(taskId: string, force: boolean): Promise<void> {
  /**
   * Validate that task can be prepared.
   * 
   * Throws:
   *   PreviousTaskIncompleteError: Previous task not done (without force)
   *   DependencyNotMetError: Dependency task not complete  
   *   TaskNotFoundError: Task ID not in manifest
   *   TaskNotPendingError: Task already started or complete
   */
}
```

### Step 2: Load Task Details

From manifest:
- Task title, description, category
- Deliverables list
- Dependencies
- SpecKit task links

### Step 3: Load Template

Select template based on category:
- `INFRASTRUCTURE` → `infrastructure.md.j2`
- `INTEGRATION` → `integration.md.j2`
- `VISUAL` → `visual.md.j2`

### Step 4: Render current-task.md

```markdown
# Task {{task_id}}: {{title}}

## Objective

{{description}}

## Category

{{category}}

## Deliverables

{% for d in deliverables %}
- [ ] {{d}}
{% endfor %}

## Dependencies

{% if dependencies %}
{% for dep in dependencies %}
- Task {{dep.id}}: {{dep.title}} ✓
{% endfor %}
{% else %}
No dependencies.
{% endif %}

## Technical Notes

{{technical_notes}}

## Files to Create/Modify

| File | Action |
|------|--------|
{% for f in files %}
| `{{f.path}}` | {{f.action}} |
{% endfor %}

## Verification Hints

This task will be verified for:
- File existence and structure
- Test coverage and passing
- Code quality (analyzer clean)
{% if category == 'VISUAL' %}
- Visual correctness (screenshot required)
{% endif %}
```

### Step 5: Update task-context.md

```markdown
# Sprint Context

## Sprint Info
- **Sprint**: {{sprint_id}} - {{sprint_name}}
- **Branch**: {{branch}}
- **Status**: In Progress

## Current Phase
- **Phase**: {{phase_id}} - {{phase_name}}
- **Tasks in Phase**: {{phase_tasks|join(', ')}}
- **Current Task**: {{task_id}}

## Completed Work

{% for phase in completed_phases %}
### Phase {{phase.id}}: {{phase.name}} (Complete)
{% for task in phase.tasks %}
- Task {{task.id}}: {{task.title}} ✓
{% endfor %}
{% endfor %}

## Current Phase Progress

### Phase {{current_phase.id}}: {{current_phase.name}} (In Progress)
{% for task in current_phase.tasks %}
- Task {{task.id}}: {{task.title}} {% if task.complete %}✓{% elif task.current %}← CURRENT{% else %}○{% endif %}
{% endfor %}
```

### Step 6: Prepare completion-signal.md Template

```markdown
# Completion Signal

## Task
{{task_id}}: {{title}}

## Summary
<!-- Implementor: Describe what you implemented -->

## Artifacts Created
{% for d in deliverables %}
- [ ] {{d}}
{% endfor %}

## Tests
- [ ] All tests passing
- [ ] Test file: <!-- path to test file -->

## Notes
<!-- Any implementation notes, decisions, or issues encountered -->
```

### Step 7: Clear verification folder

```bash
rm -rf .orchestra/handover/verification/*
mkdir -p .orchestra/handover/verification
```

### Step 8: Update Progress

```yaml
# Update progress.yaml
current_task: {{task_id}}
current_phase: {{phase_id}}

tasks:
  {{task_id}}:
    status: "in_progress"
    attempts: 1
    started_at: "{{timestamp}}"
```

### Step 9: Update Manifest

```yaml
# Update manifest.yaml
tasks:
  - id: {{task_id}}
    status: "in-progress"  # Changed from "pending"
```

## Output

### Success (Human)

```
Task Prepared
─────────────────────────────────────────
Task: 3 - Create YAxisConfig Model
Category: INTEGRATION
Phase: 1 (Foundation)

Handover Files:
  ✓ handover/current-task.md
  ✓ handover/task-context.md
  ✓ handover/completion-signal.md (template)
  ✓ handover/verification/ (cleared)

Dependencies:
  ✓ Task 1: Create YAxisPosition Enum
  ✓ Task 2: Create YAxisScaleType Enum

Deliverables:
  • lib/src/models/y_axis_config.dart
  • test/unit/y_axis_config_test.dart

Next: Implementor can begin work
```

### Success (JSON)

```json
{
  "success": true,
  "task": {
    "id": 3,
    "title": "Create YAxisConfig Model",
    "category": "INTEGRATION",
    "phase": 1
  },
  "handover_files": [
    "handover/current-task.md",
    "handover/task-context.md",
    "handover/completion-signal.md"
  ],
  "dependencies_met": [1, 2],
  "deliverables": [
    "lib/src/models/y_axis_config.dart",
    "test/unit/y_axis_config_test.dart"
  ]
}
```

### Error

```
Error: Cannot prepare Task 3
  Previous task (Task 2) is not complete.
  Use --force to prepare anyway.
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Previous task incomplete |
| 2 | Dependency not met |
| 3 | Task not found |
| 4 | Task not pending |
| 5 | Template error |

## Examples

```bash
# Prepare next pending task
orchestra prepare

# Prepare specific task
orchestra prepare --task 3

# Force prepare (skip previous task check)
orchestra prepare --task 5 --force

# Preview what would be generated
orchestra prepare --task 3 --dry-run

# JSON output
orchestra prepare --task 3 --json
```

## Template Customization

Templates are Jinja2 files in `.orchestra/common/templates/`:

```
templates/
├── infrastructure.md.j2    # For INFRASTRUCTURE tasks
├── integration.md.j2       # For INTEGRATION tasks
├── visual.md.j2            # For VISUAL tasks
├── task-context.md.j2      # Sprint context template
└── completion-signal.md.j2 # Signal template
```

### Template Variables

| Variable | Type | Description |
|----------|------|-------------|
| `task_id` | int | Task ID |
| `title` | str | Task title |
| `description` | str | Task description |
| `category` | str | INFRASTRUCTURE/INTEGRATION/VISUAL |
| `deliverables` | list | List of deliverable paths |
| `dependencies` | list | List of dependency tasks |
| `files` | list | Files to create/modify |
| `sprint_id` | str | Sprint ID |
| `sprint_name` | str | Sprint name |
| `phase_id` | int | Current phase ID |
| `phase_name` | str | Current phase name |
| `technical_notes` | str | Technical notes from spec |

## Implementation Notes

1. **Atomicity**: Update all files or none
2. **Backup**: Keep previous handover in `.orchestra/handover/.backup/`
3. **Validation**: Verify template renders before writing
4. **Git**: Optionally commit handover (`--commit` flag or config)
