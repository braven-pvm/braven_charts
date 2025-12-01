# Example Files

> **Navigation**: [Index](../readme.md) | **Prev**: [Checklist Templates](checklist-templates.md)

---

## Overview

Reference examples for key Orchestra files. Use these as templates when creating new sprints or tasks.

---

## manifest.yaml Example

```yaml
# Sprint manifest for multi-axis normalization feature
sprint:
  id: "011"
  name: "multi-axis-normalization"
  description: "Support for multiple Y-axes with independent scales"
  branch: "011-multi-axis-normalization"
  started: "2025-11-15"
  status: "in-progress"

phases:
  - id: 1
    name: "Foundation"
    description: "Core types and enums"
    tasks: [1, 2, 3, 4, 5]
    
  - id: 2
    name: "Normalization"
    description: "Scale normalization logic"
    tasks: [6, 7, 8]
    
  - id: 3
    name: "Integration"
    description: "Widget integration"
    tasks: [9, 10, 11, 12]
    
  - id: 4
    name: "Visual"
    description: "Visual verification and polish"
    tasks: [13, 14, 15, 16]

tasks:
  - id: 1
    title: "Create YAxisPosition Enum"
    description: "Define left/right axis positioning"
    category: "INFRASTRUCTURE"
    status: "completed"
    commit: "abc1234"
    
  - id: 2
    title: "Create YAxisScaleType Enum"
    description: "Define linear/logarithmic/percent scale types"
    category: "INFRASTRUCTURE"
    dependencies: []
    status: "completed"
    commit: "def5678"
    
  - id: 3
    title: "Create YAxisConfig Model"
    description: "Configuration class for Y-axis settings"
    category: "INTEGRATION"
    dependencies: [1, 2]
    speckit_tasks:
      - "SPEC-011-3.1"
      - "SPEC-011-3.2"
    status: "completed"
    commit: "ghi9012"
    
  - id: 4
    title: "Create MultiAxisNormalizer"
    description: "Normalization logic for multiple axes"
    category: "INTEGRATION"
    dependencies: [3]
    status: "in-progress"
    
  - id: 5
    title: "Multi-Axis Demo"
    description: "Visual demonstration of multi-axis feature"
    category: "VISUAL"
    dependencies: [4]
    status: "pending"
```

---

## progress.yaml Example

```yaml
# Task progress tracking
sprint: "011"
updated: "2025-11-25T14:30:00Z"

tasks:
  - id: 1
    status: "completed"
    attempts: 1
    started_at: "2025-11-15T09:00:00Z"
    completed_at: "2025-11-15T11:30:00Z"
    commit: "abc1234"
    
  - id: 2
    status: "completed"
    attempts: 2
    started_at: "2025-11-15T13:00:00Z"
    completed_at: "2025-11-16T10:00:00Z"
    commit: "def5678"
    attempt_history:
      - attempt: 1
        result: "failed"
        reason: "Missing validation for empty values"
        timestamp: "2025-11-15T16:00:00Z"
      - attempt: 2
        result: "passed"
        timestamp: "2025-11-16T10:00:00Z"
    
  - id: 3
    status: "completed"
    attempts: 1
    started_at: "2025-11-16T11:00:00Z"
    completed_at: "2025-11-16T15:00:00Z"
    commit: "ghi9012"
    
  - id: 4
    status: "in-progress"
    attempts: 1
    started_at: "2025-11-17T09:00:00Z"

summary:
  total: 16
  completed: 3
  in_progress: 1
  pending: 12
  failed: 0
  first_attempt_pass_rate: 0.67
```

---

## Hidden Verification Criteria Example

```yaml
# .orchestrator-only/verification/task-003.yaml
# HIDDEN FROM IMPLEMENTOR

task_id: 3
title: "Create YAxisConfig Model"
category: "INTEGRATION"

verification:
  - id: "V3.1"
    check: "YAxisConfig class exists"
    severity: "BLOCKING"
    expected: "File lib/src/models/y_axis_config.dart exists with YAxisConfig class"
    validation: "File exists and contains 'class YAxisConfig'"
    
  - id: "V3.2"
    check: "Required properties present"
    severity: "BLOCKING"
    expected: |
      YAxisConfig has properties:
      - id (String)
      - position (YAxisPosition)
      - scaleType (YAxisScaleType)
      - min (double?, optional)
      - max (double?, optional)
    validation: "Inspect class definition for required properties"
    
  - id: "V3.3"
    check: "Validation method exists"
    severity: "MAJOR"
    expected: "validate() method that throws on invalid configuration"
    validation: "Method exists and handles edge cases"
    
  - id: "V3.4"
    check: "Unit tests exist"
    severity: "MAJOR"
    expected: "Tests cover creation, validation, and edge cases"
    validation: "Test file exists with meaningful tests"
    
  - id: "V3.5"
    check: "Tests pass"
    severity: "BLOCKING"
    expected: "All tests in y_axis_config_test.dart pass"
    validation: "flutter test test/unit/y_axis_config_test.dart"
    
  - id: "V3.6"
    check: "Documentation comments"
    severity: "MINOR"
    expected: "Class and public methods have /// doc comments"
    validation: "Inspect source for documentation"
    
  - id: "V3.7"
    check: "Immutable pattern"
    severity: "INFO"
    expected: "Consider using freezed or immutable pattern"
    validation: "Suggestion only, not required"

adversarial_checks:
  - "What happens with null id?"
  - "What happens with conflicting min/max?"
  - "What happens with negative scale values?"
  - "Does validation provide clear error messages?"
```

---

## current-task.md Example

```markdown
# Task 4: Create MultiAxisNormalizer

## Objective

Create the normalization logic that maps data values to normalized 0.0-1.0 range for each axis independently.

## Background

With multiple Y-axes potentially having different scales (linear, logarithmic, percentage), we need a normalizer that can:
1. Accept data points and axis configuration
2. Normalize values per-axis based on scale type
3. Support reverse normalization (normalized → data value)

## Requirements

### Functional Requirements
1. Create `MultiAxisNormalizer` class
2. Implement `normalize(value, axisId)` method
3. Implement `denormalize(normalized, axisId)` method
4. Handle linear, logarithmic, and percentage scales
5. Support auto-ranging when min/max not specified

### Non-Functional Requirements
1. Performance: O(1) for individual normalizations
2. Thread-safe for read operations
3. Clear error messages for invalid axis IDs

## Deliverables

- [ ] `lib/src/math/multi_axis_normalizer.dart` - Main class
- [ ] `test/unit/multi_axis_normalizer_test.dart` - Unit tests
- [ ] Tests cover all scale types
- [ ] Tests cover edge cases (empty data, single point, etc.)

## Technical Notes

- Use existing `YAxisConfig` for axis configuration
- May need to cache computed ranges for performance
- Logarithmic scale requires positive values only

## Files to Create/Modify

| File | Action |
|------|--------|
| `lib/src/math/multi_axis_normalizer.dart` | Create |
| `test/unit/multi_axis_normalizer_test.dart` | Create |
| `lib/braven_charts.dart` | Add export |

## Dependencies

- Task 3 (YAxisConfig) - provides axis configuration model

## Hints

Consider using a `RangeInfo` helper class to store computed min/max/span per axis.
```

---

## completion-signal.md Example (Filled)

```markdown
# Completion Signal

## Task
4: Create MultiAxisNormalizer

## Summary

Created the MultiAxisNormalizer class with support for linear, logarithmic, and percentage scale normalization. Implemented both normalize() and denormalize() methods with proper error handling.

Key implementation decisions:
- Used RangeCache to store computed ranges per axis
- Logarithmic scale uses natural log (ln) for smoothness
- Percentage scale divides by 100 before normalizing

## Artifacts Created

- [x] `lib/src/math/multi_axis_normalizer.dart` - 180 lines
- [x] `lib/src/math/range_cache.dart` - 45 lines (helper class)
- [x] `test/unit/multi_axis_normalizer_test.dart` - 220 lines
- [x] Updated `lib/braven_charts.dart` with export

## Tests

- [x] All tests passing (15 tests)
- [x] Test file: `test/unit/multi_axis_normalizer_test.dart`

Test coverage:
- Linear scale: 5 tests
- Logarithmic scale: 4 tests
- Percentage scale: 3 tests
- Error cases: 3 tests

## Notes

- Chose natural log over log10 for smoother curves
- RangeCache is internal, not exported
- Added validation for logarithmic scale with non-positive values
- Consider adding scale inversion support in future task
```

---

## Pre-Signal Artifact Example

```json
{
  "task_id": 4,
  "timestamp": "2025-11-17T14:30:00Z",
  "script_version": "1.2.0",
  "checks": {
    "tests_passed": true,
    "test_count": 15,
    "analyzer_clean": true,
    "artifacts_exist": [
      "lib/src/math/multi_axis_normalizer.dart",
      "lib/src/math/range_cache.dart",
      "test/unit/multi_axis_normalizer_test.dart"
    ]
  },
  "git": {
    "branch": "011-multi-axis-normalization",
    "uncommitted_changes": true,
    "staged_files": 4
  }
}
```

---

## Archive Metadata Example

```json
{
  "task_id": 3,
  "title": "Create YAxisConfig Model",
  "category": "INTEGRATION",
  "archived_at": "2025-11-16T15:30:00Z",
  "attempts": 1,
  "commit": "ghi9012",
  "verification": {
    "result": "PASSED",
    "checks_total": 7,
    "checks_passed": 7,
    "blocking_passed": 3,
    "major_passed": 2,
    "minor_passed": 1,
    "info_noted": 1
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

---

## task-context.md Example

```markdown
# Sprint Context

## Sprint Info
- **Sprint**: 011 - Multi-Axis Normalization
- **Branch**: 011-multi-axis-normalization
- **Status**: In Progress

## Current Phase
- **Phase**: 2 - Normalization
- **Tasks in Phase**: 6, 7, 8
- **Current Task**: 7

## Completed Work

### Phase 1: Foundation (Complete)
- Task 1: YAxisPosition enum ✓
- Task 2: YAxisScaleType enum ✓
- Task 3: YAxisConfig model ✓
- Task 4: YAxisConfigCollection ✓
- Task 5: Foundation tests ✓

### Phase 2: Normalization (In Progress)
- Task 6: MultiAxisNormalizer ✓
- Task 7: NormalizationStrategy → CURRENT
- Task 8: Range computation (pending)

## Key Decisions

1. Using natural log for logarithmic scales
2. RangeCache is internal implementation detail
3. Immutable configurations, mutable cache

## Files of Interest

| File | Purpose |
|------|---------|
| `lib/src/models/y_axis_config.dart` | Axis configuration |
| `lib/src/math/multi_axis_normalizer.dart` | Normalization logic |
| `lib/src/math/range_cache.dart` | Performance cache |

## Next Steps

After current task:
- Task 8: Range computation edge cases
- Phase 3: Widget integration begins
```
