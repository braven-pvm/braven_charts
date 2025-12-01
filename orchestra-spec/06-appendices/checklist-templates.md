# Checklist Templates

> **Navigation**: [Index](../readme.md) | **Prev**: [Glossary](glossary.md) | **Next**: [Example Files](example-files.md)

---

## Overview

Pre-built checklists for common Orchestra operations. Copy and use as needed.

---

## Orchestrator Checklists

### Pre-Sprint Checklist

Before starting a new sprint:

- [ ] Sprint specification complete
- [ ] manifest.yaml created with all tasks
- [ ] Hidden verification criteria created for each task
- [ ] Task dependencies defined
- [ ] Phases organized logically
- [ ] SpecKit traceability links added
- [ ] progress.yaml initialized
- [ ] handover folder empty
- [ ] Git branch created for sprint
- [ ] Scripts tested and working

### Task Preparation Checklist

Before handing off a task:

- [ ] Previous task closed (run closeout check)
- [ ] Handover folder cleared
- [ ] current-task.md populated with task details
- [ ] task-context.md reflects current phase
- [ ] completion-signal.md template copied
- [ ] verification/ folder created (empty)
- [ ] Manifest status updated to "in-progress"
- [ ] Handover committed to git
- [ ] Ready to invoke implementor

### Verification Checklist

When verifying completed work:

- [ ] Pre-signal artifact exists
- [ ] Read pre-signal artifact contents
- [ ] Load hidden verification criteria
- [ ] Execute each check in order:
  - [ ] BLOCKING checks first
  - [ ] MAJOR checks second
  - [ ] MINOR checks third
  - [ ] INFO checks last
- [ ] Document results for each check
- [ ] Determine pass/fail:
  - [ ] No BLOCKING failures?
  - [ ] Fewer than 2 MAJOR failures?
- [ ] If VISUAL task: view screenshot via Chrome DevTools MCP
- [ ] Write verification result

### Visual Verification Checklist

For VISUAL category tasks:

- [ ] Screenshot file exists at expected path
- [ ] Open in browser: `file:///{path}`
- [ ] Take screenshot via Chrome DevTools MCP
- [ ] Verify visual content:
  - [ ] Expected elements present?
  - [ ] Colors match specification?
  - [ ] Layout correct?
  - [ ] No placeholder or wrong content?
- [ ] Close browser page
- [ ] Document what was observed

### Task Closeout Checklist

After verification passes:

- [ ] Create archive folder: results/task-NNN/
- [ ] Copy handover contents to archive
- [ ] Create metadata.json with completion info
- [ ] Update progress.yaml
- [ ] Mark SpecKit tasks complete (if linked)
- [ ] Clear handover folder
- [ ] Commit archive
- [ ] Prepare next task (or end sprint)

### Failure Feedback Checklist

When verification fails:

- [ ] Document each failed check specifically
- [ ] Provide expected vs actual for each
- [ ] Give actionable fix instructions
- [ ] Note attempt number (of 3)
- [ ] Update attempt count in progress
- [ ] Write feedback to completion-signal.md
- [ ] Determine if escalation needed (3rd attempt)
- [ ] Invoke implementor with feedback

### Sprint Closeout Checklist

After all tasks complete:

- [ ] All tasks in "completed" status
- [ ] All SpecKit items marked complete
- [ ] All archives have metadata
- [ ] Handover folder empty
- [ ] Git history clean
- [ ] progress.yaml shows all complete
- [ ] Create sprint retrospective notes
- [ ] Merge branch to main (if applicable)

---

## Implementor Checklists

### Task Start Checklist

When receiving a new task:

- [ ] Read current-task.md fully
- [ ] Read task-context.md for sprint context
- [ ] Understand deliverables list
- [ ] Review linked specification
- [ ] Check for dependencies (are they complete?)
- [ ] Understand file locations
- [ ] Plan implementation approach

### Implementation Checklist

During task work:

- [ ] Create files per deliverables list
- [ ] Follow coding standards
- [ ] Write tests for new functionality
- [ ] Run tests frequently (not just at end)
- [ ] Commit incrementally
- [ ] Handle edge cases
- [ ] Consider adversarial inputs

### Pre-Signal Checklist

Before signaling completion:

- [ ] All deliverables created
- [ ] All tests passing
- [ ] Code compiles without errors
- [ ] Analyzer shows no issues
- [ ] Run pre-signal check script
- [ ] Verify artifact created
- [ ] Create screenshot (if VISUAL task)
- [ ] Fill completion-signal.md:
  - [ ] Summary of work done
  - [ ] Artifacts created
  - [ ] Tests added
  - [ ] Any implementation notes

### Retry Checklist

After receiving failure feedback:

- [ ] Read feedback completely
- [ ] Understand each failed check
- [ ] Focus ONLY on failed items
- [ ] Do NOT restart from scratch
- [ ] Make targeted fixes
- [ ] Re-run tests
- [ ] Run pre-signal check again
- [ ] Update completion-signal.md
- [ ] Signal completion again

### Screenshot Checklist

For VISUAL tasks:

- [ ] Use flutter_agent.py (not terminal)
- [ ] Start in separate window: Start-Process
- [ ] Wait for app ready: `flutter_agent.py wait`
- [ ] Capture screenshot: `flutter_agent.py screenshot`
- [ ] Verify screenshot file exists
- [ ] Stop app: `flutter_agent.py stop`
- [ ] Screenshot shows actual feature (not placeholder)
- [ ] Screenshot demonstrates verification criteria

---

## Quick Reference Cards

### Severity Quick Reference

| Severity | Failure Effect | Can Downgrade? |
|----------|---------------|----------------|
| BLOCKING | Immediate fail | No |
| MAJOR | 2+ = fail | No |
| MINOR | Noted only | No |
| INFO | Suggestion only | No |

### Task Category Quick Reference

| Category | Focus | Verification |
|----------|-------|--------------|
| INFRASTRUCTURE | Files/config | Existence, syntax |
| INTEGRATION | Code/tests | Tests pass |
| VISUAL | Appearance | Actual viewing |

### Lifecycle Quick Reference

```
PENDING → IN-PROGRESS → AWAITING-VERIFICATION
                                    ↓
                        ┌─── COMPLETED (pass)
                        └─── FAILED (fail → retry or escalate)
```

### Attempt Quick Reference

| Attempt | On Failure |
|---------|------------|
| 1 | Feedback, retry |
| 2 | Detailed guidance, retry |
| 3 | Escalate to human |

---

## Template: Task Preparation Notes

```markdown
# Task Preparation: Task NNN

## Previous Task Status
- [ ] Task N-1 complete
- [ ] Closeout check passed
- [ ] Handover cleared

## Current Task Details
- ID: NNN
- Title: ___
- Category: INFRASTRUCTURE / INTEGRATION / VISUAL
- Phase: ___

## Dependencies
- [ ] Task X complete (provides: ___)
- [ ] Task Y complete (provides: ___)

## Handover Prepared
- [ ] current-task.md filled
- [ ] task-context.md updated
- [ ] completion-signal.md template ready
- [ ] verification/ folder created

## Notes for Implementor
___
```

---

## Template: Verification Notes

```markdown
# Verification: Task NNN

## Pre-Check
- [ ] Pre-signal artifact exists
- [ ] Artifact timestamp reasonable
- [ ] Completion signal filled

## Check Results

### Check 1: ___ (BLOCKING)
- Status: PASS / FAIL
- Expected: ___
- Actual: ___
- Notes: ___

### Check 2: ___ (MAJOR)
- Status: PASS / FAIL
- Expected: ___
- Actual: ___
- Notes: ___

### Check 3: ___ (MINOR)
- Status: PASS / FAIL
- Expected: ___
- Actual: ___
- Notes: ___

## Visual Verification (if applicable)
- [ ] Screenshot viewed via Chrome DevTools MCP
- Observed: ___
- Expected: ___
- Match: YES / NO

## Decision
- [ ] PASS: All BLOCKING pass, <2 MAJOR fail
- [ ] FAIL: Any BLOCKING fail OR 2+ MAJOR fail

## Attempt: ___ of 3
```

---

## Template: Failure Feedback

```markdown
# Verification Result: FAILED

**Task**: NNN - ___
**Attempt**: X of 3

## Failed Checks

### Check 1: ___ (SEVERITY)
**Status**: FAILED
**Expected**: ___
**Actual**: ___
**Fix**: ___

### Check 2: ___ (SEVERITY)
**Status**: FAILED
**Expected**: ___
**Actual**: ___
**Fix**: ___

## What to Do

1. ___
2. ___
3. Re-run pre-signal check
4. Signal completion again

## Notes
___
```
