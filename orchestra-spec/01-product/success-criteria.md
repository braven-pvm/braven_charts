# Success Criteria

> **Navigation**: [Index](../readme.md) | **Prev**: [Requirements](requirements.md) | **Next**: [Architecture Overview](../02-architecture/overview.md)

---

## Overview

Measurable criteria to determine if an Orchestra implementation is successful.

## Sprint-Level Metrics

### SC-001: First-Attempt Pass Rate

**Target**: > 80%

**Measurement**: `(Tasks passing on first attempt) / (Total tasks)`

**Rationale**: Clear, complete handover documents should reduce rework. Lower rates indicate specification gaps.

### SC-002: Integration Task Success Rate

**Target**: 100%

**Measurement**: `(Integration tasks that genuinely modify existing code) / (Integration tasks attempted)`

**Rationale**: Integration tasks are where implementation theater is most dangerous. Fake integrations (new files only) must be detected.

**Verification method**:
- Git diff shows existing file modifications (not just new files)
- grep/static analysis confirms actual function calls added
- Integration tests exercise the integration path

### SC-003: Visual Bug Detection Rate

**Target**: > 90%

**Measurement**: `(Visual bugs caught by orchestrator) / (Total visual bugs found including human-caught)`

**Rationale**: Screenshot verification should catch most rendering issues before human review.

### SC-004: Human Intervention Rate

**Target**: < 10% of tasks

**Measurement**: `(Tasks requiring human intervention) / (Total tasks)`

**Rationale**: Autonomous operation is a key goal. Frequent human intervention indicates process gaps.

**Excludes**: Planned human checkpoints (phase gates, final review)

### SC-005: Test Coverage Quality

**Target**: Tests exceed minimum by > 50%

**Measurement**: `(Actual test count) / (Required minimum test count)`

**Rationale**: Implementors following the pattern should naturally exceed minimums due to quality focus.

## Task-Level Metrics

### SC-010: Verification Completeness

**Target**: 100%

**Measurement**: All verification checks in task YAML must be executed and documented

**Verification method**:
- Verification results document includes all check IDs
- Each check has PASS/FAIL with evidence
- No checks skipped without explicit reason

### SC-011: Artifact Completeness

**Target**: 100%

**Measurement**: All required artifacts present before signaling completion

**Artifacts include**:
- [ ] Pre-signal check artifact (proves script ran)
- [ ] Test output file
- [ ] Screenshots (for visual tasks)
- [ ] Completion signal document

### SC-012: Handover Quality

**Target**: 100% autonomous execution possible

**Measurement**: Implementor should not need to ask clarifying questions

**Verification method**:
- Handover validation script passes
- No TODO/TBD placeholders
- All file paths are unambiguous
- TDD section includes sample test data

## Process Health Metrics

### SC-020: Script Execution Compliance

**Target**: 100%

**Measurement**: All mandatory scripts executed (proven by artifacts)

**Scripts include**:
- Orchestrator: `task-closeout-check.ps1` before new task
- Implementor: `pre-signal-check.ps1` before signaling
- Both: `set-env.ps1` at session start

### SC-021: SpecKit Traceability

**Target**: 100% bidirectional coverage

**Measurement**: 
- All SpecKit tasks mapped to orchestrator tasks
- All completed orchestrator tasks have corresponding SpecKit checkmarks
- No orphan tasks in either direction

### SC-022: Archive Completeness

**Target**: 100%

**Measurement**: Every completed task has full archive in `results/`

**Archive includes**:
- Complete handover folder copy
- Verification results
- Metadata (timestamps, commit, etc.)

## Anti-Pattern Detection

### SC-030: Implementation Theater Detection

**Target**: 0 instances undetected

**Symptoms to check**:
- [ ] Integration tasks that only create new files
- [ ] Tests that only check existence (not behavior)
- [ ] Self-reported completion without external verification
- [ ] Shallow test counts (meeting exact minimum)

### SC-031: Orchestrator Drift Detection

**Target**: 0 instances

**Symptoms to check**:
- [ ] Verification run from memory (not reading YAML)
- [ ] Missing visual verification despite task requiring it
- [ ] Severity downgraded during verification
- [ ] Handover prepared without reading templates

### SC-032: Process Skip Detection

**Target**: 0 instances

**Symptoms to check**:
- [ ] Missing pre-signal artifact
- [ ] Stale completion-signal.md from previous task
- [ ] SpecKit tasks not marked when orchestrator task completes
- [ ] Progress.yaml not updated after verification

## Comparison Baseline

### Sprint 011 (Before Orchestra)

| Metric | Sprint 011 Value | Notes |
|--------|-----------------|-------|
| Tasks completed | 56/56 (100%) | All "completed" |
| Actual functionality | 0% | Nothing worked |
| Integration success | 0% | All fake (new files only) |
| Visual verification | None | Never ran the app |
| Human intervention | 0% | No humans involved |
| Outcome | **Total failure** | Implementation theater |

### Sprint 011 Retry (With Orchestra)

| Metric | Actual Value | Target | Status |
|--------|--------------|--------|--------|
| Tasks completed | 16/16 (100%) | - | Done |
| First-attempt pass | 87.5% (14/16) | > 80% | [x] Met |
| Integration success | 100% (3/3) | 100% | [x] Met |
| Visual bugs caught by orchestrator | 0%* | > 90% | [ ] Gap |
| Human intervention | ~15% | < 10% | [ ] Close |
| Test count vs required | ~175% | > 150% | [x] Met |
| Total tests | 316 | - | - |

*Note: Visual bug caught by human, not orchestrator. Process gap identified and documented.

## Continuous Improvement Targets

As Orchestra matures, targets should tighten:

| Metric | v0.1 Target | v0.5 Target | v1.0 Target |
|--------|-------------|-------------|-------------|
| First-attempt pass | > 80% | > 85% | > 90% |
| Human intervention | < 10% | < 5% | < 2% |
| Visual detection | > 90% | > 95% | > 98% |
| Script compliance | 100% | 100% | 100% |
