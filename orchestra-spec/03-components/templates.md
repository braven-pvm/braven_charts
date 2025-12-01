# Template Definitions

> **Navigation**: [Index](../readme.md) | **Prev**: [Scripts](scripts.md) | **Next**: [Task Lifecycle](../04-processes/task-lifecycle.md)

---

## Overview

Templates ensure consistency and completeness. All handover documents are created from templates, never from scratch.

## Template Philosophy

### Why Templates?

1. **Structure > Memory**: Agents forget sections; templates have all sections
2. **Explicit N/A**: Empty is ambiguous; "N/A - Reason" is intentional
3. **Validation-friendly**: Scripts can check templates are filled
4. **Consistency**: Every task has same structure

### Template Rules

1. All sections MUST be filled with content OR marked `[N/A - Reason: ...]`
2. No `[TODO]` or `[TBD]` markers allowed in final documents
3. Templates include instructional comments (removed when filled)
4. Validation scripts check for completeness

## Template: current-task.md

**Location**: `common/templates/current-task.md.template`  
**Purpose**: Single task handover from orchestrator to implementor

```markdown
# Task [TASK_ID]: [TASK_TITLE]

<!-- ORCHESTRATOR: Replace all [BRACKETED] placeholders -->
<!-- ORCHESTRATOR: Fill every section with content OR mark [N/A - Reason: ...] -->
<!-- ORCHESTRATOR: Remove all HTML comments before handover -->

**Phase**: [PHASE_NUMBER] - [PHASE_NAME]  
**Category**: [INFRASTRUCTURE | INTEGRATION | VISUAL]  
**SpecKit Tasks**: [T001, T002, ...] or [N/A - no SpecKit]

---

## 1. Objective

[Clear, specific statement of what to accomplish. One paragraph max.]

---

## 2. Deliverables

### Files to CREATE

| File Path | Purpose |
|-----------|---------|
| `[full/path/to/file.dart]` | [What this file provides] |
| `[full/path/to/test.dart]` | [Test coverage for above] |

<!-- If no files to create, use: [N/A - This task only modifies existing files] -->

### Files to UPDATE

| File Path | Changes Required |
|-----------|------------------|
| `[full/path/to/existing.dart]` | [Specific changes: add method X, modify Y] |

<!-- If no files to update, use: [N/A - This task only creates new files] -->

### Export Location

- Export new public classes from: `[lib/barrel_file.dart]`

<!-- If nothing to export, use: [N/A - No public exports] -->

---

## 3. Technical Context

### Dependencies

This task depends on:
- `[ClassName]` from `[path/to/file.dart]` - [how it's used]
- `[AnotherClass]` from `[path/to/other.dart]` - [how it's used]

<!-- If no dependencies, use: [N/A - Standalone implementation] -->

### MUST USE (Do Not Duplicate)

| Utility | Use For | DO NOT |
|---------|---------|--------|
| `[ExistingClass.method()]` | [Purpose] | [Inline equivalent to avoid] |

<!-- If nothing to reuse, use: [N/A - No existing utilities to use] -->

### Existing Patterns to Follow

- [Pattern 1: e.g., "Use /// for doc comments, not //"]
- [Pattern 2: e.g., "Enum values use camelCase"]
- [Pattern 3: e.g., "Include copyWith, ==, hashCode for models"]

---

## 4. TDD Requirements

**Status**: [REQUIRED | OPTIONAL | N/A - Reason]

<!-- For TDD REQUIRED tasks: -->

### Test File

Create: `[test/path/to/test_file.dart]`

### Test Expectations

| Test Name | Verifies |
|-----------|----------|
| `[test name 1]` | [Expected behavior] |
| `[test name 2]` | [Expected behavior] |
| `[test name 3]` | [Expected behavior] |

Minimum test count: [N]

### Sample Test Data

```dart
// Concrete example inputs and expected outputs
final input = [Example input];
final expected = [Expected output];
```

<!-- For N/A: [N/A - Reason: Simple enum, tests optional] -->

---

## 5. Code Scaffolds

<!-- Provide starter code if helpful. Otherwise: [N/A - Implementation is straightforward] -->

```dart
// Suggested structure for main file
class [ClassName] {
  // TODO: Implement
}
```

---

## 6. Visual Verification

**Task Category**: [INFRASTRUCTURE | INTEGRATION | VISUAL]

<!-- Choose ONE of the following blocks based on category -->

<!-- FOR INFRASTRUCTURE TASKS: -->
[N/A - Reason: Infrastructure task]

This task creates foundational classes that are not yet integrated into the 
visible UI. Visual verification will occur in a future INTEGRATION task.

<!-- FOR INTEGRATION or VISUAL TASKS: -->

### Demo File

Create standalone demo:
```
example/lib/demos/task_[NNN]_demo.dart
```

Demo scaffold:
```dart
import 'package:flutter/material.dart';
// TODO: Add imports

void main() => runApp(const TaskNNNDemo());

class TaskNNNDemo extends StatelessWidget {
  const TaskNNNDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Task NNN: [Feature Name]')),
        body: Center(
          child: // TODO: Add widget demonstrating feature
        ),
      ),
    );
  }
}
```

### Screenshot Workflow

```powershell
# 1. Start app in separate window
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_[NNN]_demo.dart -d chrome"

# 2. Wait for ready
python tools/flutter_agent/flutter_agent.py wait --timeout 60

# 3. Take screenshot
python tools/flutter_agent/flutter_agent.py screenshot --output .orchestra/handover/verification/screenshots/task-[NNN]-[feature].png

# 4. Stop
python tools/flutter_agent/flutter_agent.py stop
```

---

## 7. Quality Gates

### Static Analysis

```powershell
flutter analyze [paths/to/affected/files]
# Expected: "No issues found!"
```

### Task Tests

```powershell
flutter test [path/to/task/tests]
```

### Sprint Tests (Regression)

```powershell
flutter test [sprint/test/path/]
```

### Baseline

- Current sprint test count: [N]
- Must not decrease

---

## 8. Completion Protocol

When implementation is complete:

1. **Run Pre-Signal Check**
   ```powershell
   .orchestra/implementor/.implementor-only/scripts/pre-signal-check.ps1 -TaskNumber [N]
   ```

2. **Write Completion Signal**
   - Fill: `.orchestra/handover/verification/completion-signal.md`

3. **Stage Changes**
   ```powershell
   git add -A
   ```

4. **Signal Ready**
   - Say: "Ready for review"

---

<!-- ORCHESTRATOR CHECKLIST (delete before handover):
- [ ] All [BRACKETED] placeholders replaced
- [ ] All sections filled or marked N/A with reason
- [ ] No TODO/TBD markers remain
- [ ] File paths are unambiguous (full relative paths)
- [ ] Sample test data provided for TDD tasks
- [ ] Demo scaffold provided for visual tasks
- [ ] HTML comments removed
-->
```

## Template: task-context.md

**Location**: `common/templates/task-context.md.template`  
**Purpose**: Sprint/phase context for implementor

```markdown
# Task Context

<!-- This document provides sprint-level context. Update when phase changes. -->

## Current Sprint

**Name**: [SPRINT_NAME]  
**Branch**: [BRANCH_NAME]  
**Started**: [START_DATE]

## Current Phase

**Phase**: [PHASE_NUMBER] - [PHASE_NAME]  
**Description**: [What this phase accomplishes]

## Sprint Progress

| Phase | Status | Tasks |
|-------|--------|-------|
| 1. [Phase Name] | [Complete/In Progress/Pending] | [N/M] |
| 2. [Phase Name] | [Complete/In Progress/Pending] | [N/M] |

## Key Classes Created (This Sprint)

| Class | File | Purpose |
|-------|------|---------|
| `[ClassName]` | `[path/to/file.dart]` | [What it does] |

## Test Locations

- Unit tests: `test/unit/[sprint_folder]/`
- Integration tests: `test/integration/[sprint_name]_*.dart`

## Important Conventions

- [Convention 1 established in this sprint]
- [Convention 2 established in this sprint]

## Previous Tasks Summary

<!-- Brief summary of what previous tasks accomplished -->

- Task 1: [Brief outcome]
- Task 2: [Brief outcome]
- ...
```

## Template: completion-signal.md

**Location**: `common/templates/completion-signal.md.template`  
**Purpose**: Implementor's completion report

```markdown
# Completion Signal

**Task**: [TASK_ID] - [TASK_TITLE]  
**Date**: [YYYY-MM-DD]  
**Attempt**: [N]

---

## Implementation Summary

<!-- Brief description of what was implemented (2-3 sentences) -->

[Description here]

---

## Files Changed

### Created

| File | Purpose |
|------|---------|
| `[path/to/file.dart]` | [What it provides] |

### Modified

| File | Changes |
|------|---------|
| `[path/to/existing.dart]` | [What was changed] |

---

## Test Results

| Check | Result | Count |
|-------|--------|-------|
| Task tests | [PASS/FAIL] | [N] tests |
| Sprint tests | [PASS/FAIL] | [N] tests |
| Static analysis | [PASS/FAIL] | - |

---

## Visual Verification

<!-- For INFRASTRUCTURE tasks: [N/A - Infrastructure task] -->

<!-- For INTEGRATION/VISUAL tasks: -->
- Screenshot: `verification/screenshots/task-[NNN]-[feature].png`
- Shows: [Description of what screenshot demonstrates]

---

## Notes

<!-- Any observations, edge cases handled, decisions made -->

[Notes here, or "None"]

---

## Pre-Signal Check

- [x] Ran `.implementor-only/scripts/pre-signal-check.ps1`
- Artifact: `implementor/artifacts/pre-signal/task-[NNN]-[timestamp].txt`
```

## Template: verification.yaml

**Location**: `orchestrator/.orchestrator-only/templates/verification-template.yaml`  
**Purpose**: Hidden verification criteria structure

```yaml
# Verification Criteria for Task [NNN]
# HIDDEN FROM IMPLEMENTOR - Do not share

task_id: [NNN]
title: "[TASK_TITLE]"
category: "[INFRASTRUCTURE | INTEGRATION | VISUAL]"
created: "[YYYY-MM-DD]"
version: 1

# ============================================
# STRUCTURAL CHECKS
# Verify files exist and are properly integrated
# ============================================

structural_checks:
  - id: "files_created"
    description: "Required files exist"
    severity: "BLOCKING"
    checks:
      - path: "[path/to/new/file.dart]"
        type: "exists"
      # Add more files as needed
      
  - id: "files_modified"
    description: "Existing files updated"
    severity: "BLOCKING"
    checks:
      - path: "[path/to/existing.dart]"
        type: "modified"
        verify: "git diff shows changes"
    # Use [N/A] if no existing files to modify
    
  - id: "exports_added"
    description: "New classes properly exported"
    severity: "MAJOR"
    checks:
      - path: "[lib/barrel.dart]"
        contains: "[new_class_name]"

# ============================================
# FUNCTIONAL CHECKS
# Verify implementation correctness
# ============================================

functional_checks:
  - id: "tests_pass"
    description: "All task tests pass"
    severity: "BLOCKING"
    command: "flutter test [test/path/to/tests.dart]"
    
  - id: "sprint_tests_pass"
    description: "Sprint regression tests pass"
    severity: "BLOCKING"
    command: "flutter test [test/sprint/path/]"
    
  - id: "minimum_tests"
    description: "Minimum test coverage met"
    severity: "MAJOR"
    minimum: [N]
    
  - id: "static_analysis"
    description: "No linting issues"
    severity: "BLOCKING"
    command: "flutter analyze [affected/paths/]"
    expected: "No issues found"

# ============================================
# ADVERSARIAL CHECKS (for critical tasks)
# Verify implementation is genuine, not fake
# ============================================

adversarial_checks:
  # For integration tasks:
  - id: "real_integration"
    description: "New code is actually called"
    severity: "BLOCKING"
    check: "grep for function invocation in caller"
    
  # Remove section if not needed:
  # adversarial_checks: []

# ============================================
# VISUAL VERIFICATION (for INTEGRATION/VISUAL)
# ============================================

screenshot:
  required: [true | false]
  path: "[.orchestra/handover/verification/screenshots/task-NNN-feature.png]"
  verify:
    - "[Visual criterion 1: e.g., 'Multiple axes visible']"
    - "[Visual criterion 2: e.g., 'Colors match specification']"
    - "[Visual criterion 3: e.g., 'Labels show correct values']"
  # For INFRASTRUCTURE tasks:
  # required: false
  # verify: []

# ============================================
# SEVERITY REFERENCE
# ============================================
# BLOCKING: Fundamental requirement - task FAILS
# MAJOR: Significant issue - task FAILS  
# MINOR: Small issue - task PASSES with note
# INFO: Observation only - task PASSES
#
# SEVERITY IS IMMUTABLE - Set here, not during verification
```

## Template Usage Workflow

### Orchestrator Creating Handover

```powershell
# 1. Copy template
Copy-Item ".orchestra/common/templates/current-task.md.template" `
  ".orchestra/handover/current-task.md"

# 2. Fill template (manual or scripted)
# Replace all [BRACKETED] placeholders
# Fill or N/A all sections
# Remove HTML comments

# 3. Validate
.orchestra/orchestrator/scripts/handover-validate.ps1
```

### Implementor Completing Signal

```powershell
# 1. Template already exists from prepare-handover.ps1
# File: .orchestra/handover/verification/completion-signal.md

# 2. Fill template
# Add implementation summary
# List files changed
# Record test results
# Note visual verification (if applicable)

# 3. Pre-signal check adds artifact reference
.orchestra/implementor/.implementor-only/scripts/pre-signal-check.ps1
```

## Template Validation Rules

Validation scripts check:

| Rule | Check Method |
|------|--------------|
| No `[TODO]` markers | String search |
| No `[TBD]` markers | String search |
| No `[BRACKETED]` placeholders | Regex `\[[A-Z_]+\]` |
| All sections present | Header search |
| N/A sections have reason | Pattern `[N/A - Reason:` |
| Category is valid enum | One of three values |
| File paths are absolute-relative | Start with known roots |
