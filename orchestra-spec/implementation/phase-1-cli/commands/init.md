# Command: `orchestra init`

> **Navigation**: [Phase 1 Index](../readme.md) | **Next**: [prepare](prepare.md)

---

## Purpose

Initialize a new Orchestra sprint from a SpecKit specification. Creates the `.orchestra/` folder structure, generates manifest from spec, and sets up verification criteria templates.

## Synopsis

```bash
orchestra init [OPTIONS]
```

## Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--spec` | PATH | Yes | - | Path to SpecKit spec.md file |
| `--output` | PATH | No | `.orchestra/` | Output directory |
| `--force` | FLAG | No | false | Overwrite existing files |
| `--dry-run` | FLAG | No | false | Show what would be created |
| `--json` | FLAG | No | false | Output JSON format |

## Behavior

### Step 1: Validate Input

```typescript
// src/core/manifest.ts
import { z } from 'zod';

const SpecDocumentSchema = z.object({
  title: z.string(),
  phases: z.array(PhaseSchema),
  tasks: z.array(TaskSchema)
});

export async function parseSpec(specPath: string): Promise<SpecDocument> {
  const content = await fs.readFile(specPath, 'utf-8');
  // Parse markdown, extract structure
  return SpecDocumentSchema.parse(parsed);
}
```

### Step 2: Parse Spec

Extract from spec:
- Sprint ID and name
- Task list with titles, descriptions, categories
- Phase organization
- Dependencies between tasks

### Step 3: Create Folder Structure

```
.orchestra/
├── orchestrator/
│   ├── .orchestrator-only/
│   │   ├── manifest.yaml
│   │   ├── progress.yaml
│   │   └── verification/
│   │       ├── task-001.yaml
│   │       ├── task-002.yaml
│   │       └── ...
│   ├── scripts/
│   └── results/
├── implementor/
│   ├── .implementor-only/
│   │   └── scripts/
│   └── artifacts/
├── common/
│   ├── scripts/
│   └── templates/
├── handover/
│   ├── agent_readme.md
│   ├── current-task.md
│   ├── task-context.md
│   └── completion-signal.md
├── docs/
└── config.yaml
```

### Step 4: Generate Manifest

```yaml
# .orchestra/orchestrator/.orchestrator-only/manifest.yaml
sprint:
  id: "012"
  name: "feature-name"
  description: "Feature description from spec"
  branch: "012-feature-name"
  created: "2025-12-01T10:00:00Z"
  status: "not-started"

phases:
  - id: 1
    name: "Foundation"
    tasks: [1, 2, 3]
  - id: 2
    name: "Integration"
    tasks: [4, 5, 6]

tasks:
  - id: 1
    title: "Task title from spec"
    description: "Task description"
    category: "INFRASTRUCTURE"
    dependencies: []
    status: "pending"
    speckit_tasks: ["SPEC-012-1.1"]
    
  - id: 2
    title: "Another task"
    # ...
```

### Step 5: Generate Progress File

```yaml
# .orchestra/orchestrator/.orchestrator-only/progress.yaml
sprint: "012"
created: "2025-12-01T10:00:00Z"
current_task: null
current_phase: null

summary:
  total: 12
  completed: 0
  in_progress: 0
  pending: 12
  failed: 0

tasks: {}
```

### Step 6: Generate Verification Templates

For each task, create verification criteria based on category:

```yaml
# .orchestra/orchestrator/.orchestrator-only/verification/task-001.yaml
task_id: 1
title: "Task title"
category: "INFRASTRUCTURE"
generated: "2025-12-01T10:00:00Z"

verification:
  - id: "V1.1"
    check: "File exists"
    severity: "BLOCKING"
    expected: "lib/src/models/file.dart exists"
    command: "test -f lib/src/models/file.dart"
    
# NOTE: Orchestrator should review and customize these
```

## Output

### Success (Human)

```
Orchestra Initialized
─────────────────────────────────────────
Sprint: 012-feature-name
Tasks: 12
Phases: 3

Created:
  ✓ .orchestra/orchestrator/.orchestrator-only/manifest.yaml
  ✓ .orchestra/orchestrator/.orchestrator-only/progress.yaml
  ✓ .orchestra/orchestrator/.orchestrator-only/verification/ (12 files)
  ✓ .orchestra/handover/ (4 templates)
  ✓ .orchestra/config.yaml

Next: Review verification criteria, then run 'orchestra prepare --task 1'
```

### Success (JSON)

```json
{
  "success": true,
  "sprint": {
    "id": "012",
    "name": "feature-name",
    "tasks_count": 12,
    "phases_count": 3
  },
  "created_files": [
    ".orchestra/orchestrator/.orchestrator-only/manifest.yaml",
    ".orchestra/orchestrator/.orchestrator-only/progress.yaml"
  ],
  "next_action": "Review verification criteria, then prepare task 1"
}
```

### Error

```
Error: Spec file not found: specs/012/spec.md
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Spec file not found |
| 2 | Spec parse error |
| 3 | Output directory exists (without --force) |
| 4 | Write permission error |

## Examples

```bash
# Basic initialization
orchestra init --spec specs/012-feature/spec.md

# Force overwrite existing
orchestra init --spec specs/012-feature/spec.md --force

# Dry run to preview
orchestra init --spec specs/012-feature/spec.md --dry-run

# Custom output location
orchestra init --spec specs/012-feature/spec.md --output ./my-orchestra

# JSON output for scripting
orchestra init --spec specs/012-feature/spec.md --json
```

## Spec File Format

The init command expects a SpecKit spec with this structure:

```markdown
# Feature: Multi-Axis Normalization

## Overview
Description of the feature...

## Tasks

### Phase 1: Foundation

#### Task 1: Create YAxisPosition Enum
- Category: INFRASTRUCTURE
- Description: Define left/right positioning
- Deliverables:
  - lib/src/models/y_axis_position.dart
  - test/unit/y_axis_position_test.dart

#### Task 2: Create YAxisScaleType Enum
- Category: INFRASTRUCTURE
- Dependencies: Task 1
...
```

## Implementation Notes

1. **Idempotency**: Without `--force`, refuse to overwrite existing `.orchestra/`
2. **Validation**: Verify spec format before creating any files
3. **Atomicity**: Create all files or none (rollback on failure)
4. **Templates**: Verification templates are starting points - orchestrator customizes
