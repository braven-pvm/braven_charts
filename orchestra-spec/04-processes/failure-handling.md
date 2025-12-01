# Failure Handling

> **Navigation**: [Index](../readme.md) | **Prev**: [Visual Verification](visual-verification.md) | **Next**: [Handover Lifecycle](handover-lifecycle.md)

---

## Overview

When verification fails, Orchestra has structured processes for feedback, retry, and escalation. This document describes how failures are handled at each level.

## Failure Categories

### Verification Failures

Tasks fail verification when checks don't pass:

| Severity | Effect on Task |
|----------|----------------|
| BLOCKING | Immediate failure, must fix |
| MAJOR | Accumulate; 2+ = failure |
| MINOR | Noted but task can pass |
| INFO | Suggestions only, no effect |

### Process Failures

Non-task failures that interrupt the workflow:

- Missing artifacts (files, screenshots)
- Test failures (compile errors, assertion failures)
- Script errors (PowerShell execution issues)
- Git errors (merge conflicts, uncommitted changes)

## Feedback Protocol

When a task fails, the orchestrator provides structured feedback.

### Feedback Structure

```markdown
## Verification Result: FAILED

**Attempt**: 2 of 3
**Failed Checks**: 2

### Check 1: Unit test coverage (BLOCKING)
**Status**: FAILED
**Expected**: Tests exist for YAxisConfig validation  
**Actual**: No tests found for validation edge cases
**Fix**: Add tests for null position, invalid scale combinations

### Check 2: Error message format (MAJOR)
**Status**: FAILED
**Expected**: Errors include axis ID in message
**Actual**: Generic "Invalid configuration" without context
**Fix**: Include axis ID: "YAxis 'right': Invalid scale type"

### What to Do

1. Add validation tests to `test/unit/y_axis_config_test.dart`
2. Update error messages in `YAxisConfig.validate()`
3. Run `flutter test` to verify
4. Re-run pre-signal check
5. Signal completion again
```

### Feedback Principles

1. **Specific**: Exactly what failed, not vague guidance
2. **Actionable**: Clear steps to fix
3. **Bounded**: Only address actual failures
4. **Honest**: No false positives or moving goalposts

## Retry Mechanism

### Attempt Limits

Each task allows up to 3 attempts:

| Attempt | Guidance Level |
|---------|----------------|
| 1 | Standard feedback |
| 2 | Enhanced guidance with examples |
| 3 | Maximum detail, consider spec issue |

### Attempt Tracking

Progress file tracks attempts:

```yaml
tasks:
  - id: 5
    status: "in-progress"
    attempts: 2
    attempt_history:
      - attempt: 1
        result: "failed"
        reason: "Missing validation tests"
        timestamp: "2025-11-28T10:00:00Z"
      - attempt: 2
        result: "in-progress"
        started: "2025-11-28T10:30:00Z"
```

### Between Attempts

What happens when retry begins:

1. Implementor reads feedback (completion-signal.md)
2. Implementor addresses specific issues
3. Does NOT restart from scratch
4. Focuses only on failed checks
5. Re-runs pre-signal check
6. Signals completion again

## Escalation

### When to Escalate

Escalate to human when:

1. **3 failed attempts**: Pattern indicates systemic issue
2. **Impossible constraint**: Spec asks for contradictory things
3. **Tooling limitation**: AI cannot perform required action
4. **Ambiguous requirement**: Spec open to interpretation

### Escalation Protocol

```markdown
## Escalation Notice

**Task**: 5 - Create YAxisConfig Model
**Attempts**: 3 (all failed)
**Pattern**: Same failure on each attempt

### Failure Pattern

Implementor consistently creates tests that pass locally
but fail in verification due to timing-dependent assertions.

### Analysis

The specification requires "instant response" but the widget
rebuild cycle introduces 16ms minimum delay. This may be
a specification issue rather than implementation issue.

### Recommended Actions

1. Clarify "instant" definition in specification
2. Allow 16ms tolerance for widget rebuilds
3. Or redesign to avoid widget dependency

### Human Decision Needed

- [ ] Adjust specification
- [ ] Provide implementation hint
- [ ] Accept with documented limitation
- [ ] Other: _____________
```

### Human Resolution Options

After escalation, human can:

1. **Fix the spec**: Clarify or adjust requirements
2. **Provide hints**: Give implementation guidance
3. **Accept with notes**: Document known limitation
4. **Split task**: Break into smaller achievable tasks
5. **Defer**: Move to later sprint
6. **Cancel**: Remove from scope

## Common Failure Patterns

### Pattern: Vague Feedback Loop

**Symptom**: Implementor keeps failing same check
**Cause**: Feedback not specific enough
**Fix**: Orchestrator must provide exact expected vs actual

### Pattern: Unstable Tests

**Symptom**: Tests pass sometimes, fail others
**Cause**: Timing dependencies, random seeds, etc.
**Fix**: Identify and stabilize or mark as known flaky

### Pattern: Scope Creep in Verification

**Symptom**: New checks appear on retry
**Cause**: Moving goalposts
**Fix**: Verification criteria are fixed at task start

### Pattern: Missing Pre-conditions

**Symptom**: Task fails due to missing prior work
**Cause**: Dependency not completed
**Fix**: Review task ordering, ensure prerequisites

## Process Failure Handling

### Missing Artifacts

When required files don't exist:

```powershell
# Pre-signal check detects
if (-not (Test-Path "handover/verification/screenshot.png")) {
    Write-Error "BLOCKING: Required screenshot not found"
    exit 1
}
```

**Resolution**: Create the missing artifact, re-run check

### Test Failures

When tests don't pass:

```powershell
# Pre-signal check runs tests
$result = flutter test $testFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "BLOCKING: Tests failed"
    exit 1
}
```

**Resolution**: Fix tests until passing, re-run check

### Git Errors

When git operations fail:

```powershell
# Closeout check verifies clean state
$status = git status --porcelain
if ($status) {
    Write-Error "BLOCKING: Uncommitted changes exist"
    exit 1
}
```

**Resolution**: Commit or stash changes, re-run check

## Recovery Procedures

### Starting Fresh

When too much context pollution:

1. Run closeout check for current state
2. Note what was attempted
3. Start fresh agent session
4. Provide summary of prior attempts
5. Continue from last known good state

### Rollback

When implementation broke something:

```powershell
# Identify last good commit
git log --oneline -10

# Reset to that commit
git reset --hard <commit>

# Or revert specific commits
git revert <bad-commit>
```

### Force Progress

When stuck but need to move forward:

1. Document the blocker in detail
2. Add to TECHNICAL_DEBT.md
3. Create workaround if possible
4. Accept task with documented limitation
5. Create follow-up task to address properly

## Failure Prevention

### Before Starting Task

1. Verify all dependencies complete
2. Check tooling works (flutter, git, etc.)
3. Confirm test suite passing
4. Review specification for clarity

### During Implementation

1. Test frequently, not just at end
2. Commit incrementally
3. Run pre-signal check before signaling
4. Address warnings, not just errors

### Before Signaling

1. Run full pre-signal check
2. Verify all artifacts exist
3. Review against specification
4. Consider adversarial scenarios

## Metrics

Track failure patterns for process improvement:

```yaml
sprint_metrics:
  total_tasks: 16
  first_attempt_pass: 12
  second_attempt_pass: 3
  third_attempt_pass: 0
  escalated: 1
  
  common_failures:
    - type: "missing_tests"
      count: 3
    - type: "visual_verification"
      count: 2
    - type: "documentation"
      count: 1
```

These metrics help identify:
- Specification quality issues
- Training needs
- Tooling gaps
- Process improvements
