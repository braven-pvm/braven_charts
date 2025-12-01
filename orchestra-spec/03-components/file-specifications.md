# File Specifications

> **Navigation**: [Index](../readme.md) | **Prev**: [Folder Structure](folder-structure.md) | **Next**: [Scripts](scripts.md)

---

## Overview

This document defines the format and schema for key Orchestra files.

## manifest.yaml

**Location**: `orchestrator/manifest.yaml`  
**Purpose**: Complete task list for the sprint  
**Access**: Orchestrator only

### Schema

```yaml
sprint:
  name: "011-multi-axis-normalization"
  version: "1.0"
  created: "2025-11-28"
  baseline_tests: 262

phases:
  - id: 1
    name: "Foundation"
    description: "Data models and enums"
    tdd_required: false
    
  - id: 2
    name: "Normalization"
    description: "Core normalization logic"
    tdd_required: true

tasks:
  - id: 1
    title: "Create YAxisPosition Enum"
    phase: 1
    category: "INFRASTRUCTURE"
    status: "completed"
    commit: "abc1234"
    speckit_tasks: ["T001"]
    
  - id: 2
    title: "Create YAxisConfig Model"
    phase: 1
    category: "INFRASTRUCTURE"
    status: "completed"
    commit: "def5678"
    speckit_tasks: ["T003", "T005"]
    
  - id: 8
    title: "Pipeline Integration"
    phase: 2
    category: "INTEGRATION"
    status: "pending"
    speckit_tasks: ["T019", "T020", "T021"]
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sprint.name` | string | Yes | Sprint identifier |
| `sprint.version` | string | Yes | Manifest version |
| `sprint.created` | date | Yes | Creation date |
| `sprint.baseline_tests` | int | Yes | Test count before sprint |
| `phases[].id` | int | Yes | Phase number |
| `phases[].name` | string | Yes | Phase name |
| `phases[].tdd_required` | bool | Yes | Whether TDD is mandatory |
| `tasks[].id` | int | Yes | Task number |
| `tasks[].title` | string | Yes | Task title |
| `tasks[].phase` | int | Yes | Phase this task belongs to |
| `tasks[].category` | enum | Yes | INFRASTRUCTURE, INTEGRATION, or VISUAL |
| `tasks[].status` | enum | Yes | pending, in-progress, failed, completed |
| `tasks[].commit` | string | On complete | Git commit hash |
| `tasks[].speckit_tasks` | array | If using SpecKit | SpecKit task IDs |

## progress.yaml

**Location**: `orchestrator/progress.yaml`  
**Purpose**: Track sprint progress and metrics  
**Access**: Orchestrator only

### Schema

```yaml
sprint: "011-multi-axis-normalization"
started: "2025-11-28"
current_task: 10
previous_task: 9

summary:
  total_tasks: 16
  completed: 9
  in_progress: 1
  pending: 6
  failed: 0

metrics:
  first_attempt_passes: 8
  total_attempts: 10
  test_count: 256
  baseline_tests: 262

tasks:
  - id: 1
    status: "completed"
    attempts: 1
    completed_at: "2025-11-28"
    commit: "abc1234"
    tests_added: 14
    
  - id: 10
    status: "in-progress"
    attempts: 1
    started_at: "2025-11-29"
```

## task-NNN.yaml (Verification Criteria)

**Location**: `orchestrator/.orchestrator-only/verification/task-NNN.yaml`  
**Purpose**: Hidden verification criteria for a task  
**Access**: Orchestrator only (HIDDEN from implementor)

### Schema

```yaml
task_id: 8
title: "Pipeline Integration"
category: "INTEGRATION"
created: "2025-11-28"
version: 1

structural_checks:
  - id: "files_exist"
    description: "Required files created"
    severity: "BLOCKING"
    checks:
      - path: "lib/src/rendering/multi_axis_normalizer.dart"
        type: "exists"
      - path: "test/unit/multi_axis/normalizer_test.dart"
        type: "exists"
        
  - id: "existing_modified"
    description: "Existing pipeline file modified"
    severity: "BLOCKING"
    checks:
      - path: "lib/src/widgets/braven_chart.dart"
        type: "modified"
        verify: "git diff shows changes"

  - id: "exports_added"
    description: "New classes exported"
    severity: "MAJOR"
    checks:
      - path: "lib/braven_charts.dart"
        contains: "multi_axis_normalizer"

functional_checks:
  - id: "tests_pass"
    description: "All task tests pass"
    severity: "BLOCKING"
    command: "flutter test test/unit/multi_axis/normalizer_test.dart"
    
  - id: "sprint_tests_pass"
    description: "All sprint tests still pass"
    severity: "BLOCKING"
    command: "flutter test test/unit/multi_axis/"
    
  - id: "minimum_tests"
    description: "At least 15 tests added"
    severity: "MAJOR"
    minimum: 15

  - id: "static_analysis"
    description: "No linting issues"
    severity: "BLOCKING"
    command: "flutter analyze lib/src/rendering/"
    expected: "No issues found"

adversarial_checks:
  - id: "real_integration"
    description: "Normalizer is actually called, not just imported"
    severity: "BLOCKING"
    check: "grep for actual function invocation in pipeline"
    
  - id: "not_fake"
    description: "If normalizer is commented out, chart behaves differently"
    severity: "MAJOR"
    check: "Remove normalizer call - output should change"

screenshot:
  required: true
  path: ".orchestra/handover/verification/screenshots/task-008-integration.png"
  verify:
    - "Chart renders with normalized data"
    - "Multiple series visible with different scales"
    - "Axes show original values, not 0-1"
```

### Severity Levels

| Level | Meaning | On Failure |
|-------|---------|------------|
| BLOCKING | Fundamental requirement | Task FAILS |
| MAJOR | Significant quality issue | Task FAILS |
| MINOR | Small issue | Task PASSES with note |
| INFO | Observation only | Task PASSES |

**Important**: Severity is IMMUTABLE. Set when criteria are created, cannot be changed during verification.

## current-task.md

**Location**: `handover/current-task.md`  
**Purpose**: Single task handover document  
**Access**: Both roles (orchestrator creates, implementor reads)

### Template Structure

```markdown
# Task [ID]: [TITLE]

**Phase**: [PHASE_NAME]  
**Category**: [INFRASTRUCTURE | INTEGRATION | VISUAL]  
**SpecKit Tasks**: [T001, T002, ...]

## 1. Objective

[Clear statement of what to accomplish]

## 2. Deliverables

### Files to CREATE
| File | Purpose |
|------|---------|
| `path/to/file.dart` | Description |

### Files to UPDATE
| File | Change |
|------|--------|
| `path/to/existing.dart` | Add method X, modify Y |

### Export Location
- Export new classes from: `lib/barrel_file.dart`

## 3. Technical Context

### Dependencies
- [List of classes/files this task depends on]

### MUST USE (Do Not Duplicate)
| Utility | Use For | DO NOT |
|---------|---------|--------|
| `ExistingClass.method()` | Purpose | Inline equivalent |

### Existing Patterns
- [Pattern 1 to follow]
- [Pattern 2 to follow]

## 4. TDD Requirements

[REQUIRED | N/A with reason]

### Test Expectations
| Test | Verifies |
|------|----------|
| `test_name` | Expected behavior |

### Sample Test Data
```dart
// Concrete example inputs and expected outputs
```

## 5. Code Scaffolds

[Optional scaffolding code or N/A]

## 6. Visual Verification

**Category**: [INFRASTRUCTURE | INTEGRATION | VISUAL]

[If INFRASTRUCTURE]
[N/A - Reason: Infrastructure task. Visual verification in future integration task.]

[If INTEGRATION or VISUAL]
### Demo File
Create: `example/lib/demos/task_NNN_demo.dart`

### Screenshot Workflow
```powershell
# Commands to run
```

## 7. Quality Gates

### Static Analysis
```powershell
flutter analyze [paths]
```

### Tests
```powershell
flutter test [task_tests]
flutter test [sprint_tests]
```

### Baseline
- Sprint test count: [N] (must not decrease)

## 8. Completion Protocol

1. Run pre-signal check script
2. Write completion-signal.md
3. Stage changes: `git add -A`
4. Say: "Ready for review"
```

## completion-signal.md

**Location**: `handover/verification/completion-signal.md`  
**Purpose**: Implementor's completion report  
**Access**: Both roles (implementor creates, orchestrator reads)

### Template

```markdown
# Completion Signal

**Task**: [ID] - [TITLE]  
**Date**: [DATE]  
**Attempt**: [N]

## Implementation Summary

[Brief description of what was implemented]

## Files Changed

### Created
- `path/to/new/file.dart` - Purpose

### Modified
- `path/to/existing.dart` - What was changed

## Test Results

- Task tests: [PASS/FAIL] ([N] tests)
- Sprint tests: [PASS/FAIL] ([N] tests)
- Static analysis: [PASS/FAIL]

## Visual Verification

[If applicable]
- Screenshot: `verification/screenshots/task-NNN-feature.png`
- Shows: [Description of what screenshot demonstrates]

## Notes

[Any observations, edge cases handled, decisions made]

## Pre-Signal Check

- [x] Ran `.implementor-only/scripts/pre-signal-check.ps1`
- Artifact: `implementor/artifacts/pre-signal/task-NNN-*.txt`
```

## metadata.json

**Location**: `orchestrator/results/task-NNN/metadata.json`  
**Purpose**: Archive metadata for completed task  
**Access**: Both roles (read-only after creation)

### Schema

```json
{
  "task_id": 8,
  "title": "Pipeline Integration",
  "category": "INTEGRATION",
  "phase": 2,
  "archived_at": "2025-11-29 14:30:00",
  "commit": "abc1234def5678",
  "attempts": 1,
  "verified_by": "orchestrator",
  "speckit_tasks": ["T019", "T020", "T021"],
  "metrics": {
    "tests_added": 20,
    "files_created": 2,
    "files_modified": 1,
    "lines_added": 450,
    "lines_removed": 0
  }
}
```

## Pre-Signal Artifact

**Location**: `implementor/artifacts/pre-signal/task-NNN-YYYY-MM-DD_HHMMSS.txt`  
**Purpose**: Proof that pre-signal check was executed  
**Access**: Both roles

### Format

```
================================================================
PRE-SIGNAL CHECK ARTIFACT
================================================================
Task: 8 - Pipeline Integration
Date: 2025-11-29 14:25:00
Status: PASSED

Checks Performed:
  [x] All CREATE files exist
  [x] All UPDATE files modified
  [x] Tests pass
  [x] Static analysis clean
  [x] Demo exists (visual task)
  [x] No TODO markers in code

Summary:
  Files checked: 5
  Tests run: 20
  Issues: 0
================================================================
```
