# Verification Protocol

> **Navigation**: [Index](../readme.md) | **Prev**: [Task Lifecycle](task-lifecycle.md) | **Next**: [Visual Verification](visual-verification.md)

---

## Overview

Verification is the critical process where orchestrator validates implementor's work against hidden criteria. This document defines the complete verification procedure.

## Principles

### 1. Hidden Criteria

Verification criteria are defined BEFORE implementation and hidden from implementor. This prevents:
- Gaming metrics (Goodhart's Law)
- Optimizing for checks rather than correctness
- Shallow implementations that pass obvious tests

### 2. Immutable Severity

Severity levels are set when criteria are created, NOT during verification. The orchestrator cannot rationalize failures as "minor" to avoid rework.

### 3. Evidence-Based

Every check must produce evidence. "I ran the tests" is not enough; test output must be captured and reviewed.

### 4. Systematic Execution

All checks must be executed in order. Skipping checks is a process violation, even if the task "looks complete."

## Verification Workflow

### Step 1: Accept Signal Check

Before any verification, confirm implementor ran their pre-signal check.

```powershell
.orchestra/orchestrator/scripts/accept-signal-check.ps1 -TaskNumber N
```

**What it checks**:
- Pre-signal artifact exists: `implementor/artifacts/pre-signal/task-N-*.txt`
- Artifact shows "PASSED" (not "FAILED")
- Artifact timestamp is from current task attempt

**If check fails**: STOP. Task cannot be verified. Implementor skipped required validation.

### Step 2: Load Verification Criteria

Read the hidden verification YAML for this task.

```powershell
$criteria = Get-Content ".orchestra/orchestrator/.orchestrator-only/verification/task-NNN.yaml" | ConvertFrom-Yaml
```

**Never verify from memory**. Always read the YAML file fresh.

### Step 3: Execute Structural Checks

Verify files exist, exports are added, existing files modified.

| Check Type | Verification Method |
|------------|---------------------|
| File exists | `Test-Path <path>` |
| File modified | `git diff --name-only` includes file |
| Export present | `Select-String -Path <barrel> -Pattern <export>` |
| Import present | `Select-String -Path <file> -Pattern <import>` |

**Document each check**:
```
CHECK: files_created (BLOCKING)
  - lib/src/models/config.dart: PASS (exists)
  - test/unit/config_test.dart: PASS (exists)
```

### Step 4: Execute Functional Checks

Verify tests pass, analysis clean, minimum coverage met.

| Check Type | Verification Method |
|------------|---------------------|
| Tests pass | `flutter test <path>` |
| Analysis clean | `flutter analyze <path>` |
| Minimum tests | Count `test(` occurrences |
| Specific behavior | Run test, check output |

**Capture test output**:
```powershell
flutter test test/unit/multi_axis/ 2>&1 | Tee-Object -Variable testOutput
# Analyze $testOutput for pass/fail
```

### Step 5: Execute Adversarial Checks

For critical tasks, verify implementation is genuine.

| Check Type | Verification Method |
|------------|---------------------|
| Real integration | `Select-String` for function calls |
| Not fake import | Comment out import, rebuild fails |
| Actually called | Grep for invocation, not just definition |

**Example adversarial check**:
```powershell
# Verify MultiAxisNormalizer is CALLED, not just imported
$usages = Select-String -Path "lib/src/widgets/chart.dart" -Pattern "MultiAxisNormalizer\."
if ($usages.Count -eq 0) {
    # FAIL: Imported but never called = fake integration
}
```

### Step 6: Execute Visual Verification

For INTEGRATION and VISUAL tasks, verify screenshot content.

#### 6.1: Verify Screenshot Exists

```powershell
Test-Path ".orchestra/handover/verification/screenshots/task-NNN-*.png"
```

#### 6.2: View Screenshot Content

```
# Open in browser via Chrome DevTools MCP
mcp_chrome-devtoo_new_page(url: "file:///full/path/to/screenshot.png")

# Capture what's displayed
mcp_chrome-devtoo_take_screenshot()

# Agent now has the image and can analyze it
```

#### 6.3: Verify Each Visual Criterion

For EACH item in `screenshot.verify` array:

```yaml
screenshot:
  verify:
    - "Multiple Y-axes visible (left and right)"
    - "Each axis has distinct color"
    - "All series span full vertical height"
```

**For each criterion**:
1. Look at the returned image
2. Determine if criterion is satisfied
3. Document finding: `PASS` or `FAIL` with observation

**Example**:
```
VISUAL: "Multiple Y-axes visible (left and right)"
  Observation: Left axis shows "Power (W)", right axis shows "Volume (L)"
  Status: PASS

VISUAL: "All series span full vertical height"
  Observation: Power series spans 80% height, Volume series compressed to 20%
  Status: FAIL - Volume series not using available space
```

#### 6.4: Close Browser

```
mcp_chrome-devtoo_close_page(pageIdx: 1)
```

### Step 7: Determine Result

Apply severity rules to determine task outcome.

```
For each check:
  IF severity == BLOCKING and status == FAIL:
    Task FAILS
  IF severity == MAJOR and status == FAIL:
    Task FAILS
  IF severity == MINOR and status == FAIL:
    Task PASSES with note
  IF severity == INFO and status == FAIL:
    Task PASSES
```

**Task PASSES if**: All BLOCKING and MAJOR checks pass.

**Task FAILS if**: ANY BLOCKING or MAJOR check fails.

### Step 8: Document Results

Create verification results document.

```markdown
# Verification Results: Task N

**Date**: YYYY-MM-DD
**Attempt**: N
**Result**: [PASSED | FAILED]

## Structural Checks

| ID | Description | Severity | Status | Evidence |
|----|-------------|----------|--------|----------|
| files_created | Files exist | BLOCKING | PASS | Test-Path confirmed |

## Functional Checks

| ID | Description | Severity | Status | Evidence |
|----|-------------|----------|--------|----------|
| tests_pass | Tests pass | BLOCKING | PASS | 25/25 tests passed |

## Adversarial Checks

| ID | Description | Severity | Status | Evidence |
|----|-------------|----------|--------|----------|
| real_integration | Code is called | BLOCKING | PASS | 7 usages found |

## Visual Verification

| Criterion | Status | Observation |
|-----------|--------|-------------|
| Multiple axes visible | PASS | Left and right axes present |
| Series span full height | FAIL | Volume series compressed |

## Decision

**FAILED**: Visual criterion "Series span full height" not met (MAJOR).

## Feedback for Retry

[Specific instructions for implementor to fix the issue]
```

### Step 9: Handle Result

**If PASSED**:
1. Archive task: `archive-and-close.ps1 -TaskNumber N`
2. Update progress.yaml
3. Prepare next task handover

**If FAILED**:
1. Increment attempt count
2. Write feedback to completion-signal.md
3. Implementor addresses feedback and re-signals
4. Repeat verification

## Severity Reference

| Level | When to Use | On Failure |
|-------|-------------|------------|
| BLOCKING | Fundamental requirement that makes feature non-functional | Task FAILS immediately |
| MAJOR | Significant quality issue that should not ship | Task FAILS |
| MINOR | Small issue that can be fixed later | Task PASSES, logged for follow-up |
| INFO | Observation or style preference | Task PASSES |

### Severity Examples

| Check | Severity | Rationale |
|-------|----------|-----------|
| File doesn't exist | BLOCKING | Can't function without it |
| Tests fail | BLOCKING | Code is broken |
| Static analysis errors | BLOCKING | Won't compile in strict mode |
| Minimum tests not met | MAJOR | Quality below standard |
| Duplicate logic instead of using utility | MAJOR | Technical debt |
| Missing doc comment | MINOR | Can add later |
| Verbose implementation | INFO | Style preference |

## Anti-Patterns to Avoid

### 1. Verifying from Memory

**Wrong**: "I remember the criteria, let me check..."
**Right**: Read `task-NNN.yaml` before every verification

### 2. Downgrading Severity

**Wrong**: "This MAJOR failure is really just a MINOR issue..."
**Right**: Severity is immutable. MAJOR = task fails.

### 3. Skipping Visual Verification

**Wrong**: "Screenshot exists, good enough"
**Right**: View screenshot via Chrome DevTools MCP, check each criterion

### 4. Partial Check Execution

**Wrong**: "Tests pass, I'll skip the adversarial checks"
**Right**: Execute ALL checks in the YAML

### 5. No Evidence

**Wrong**: "Tests passed" (no output)
**Right**: Captured output showing "25/25 tests passed"

## Verification Checklist

Before marking task as PASSED:

- [ ] Accept-signal-check passed (artifact exists)
- [ ] Read verification YAML (not from memory)
- [ ] All structural checks executed with evidence
- [ ] All functional checks executed with evidence
- [ ] All adversarial checks executed with evidence
- [ ] Visual verification completed (if required)
  - [ ] Screenshot viewed via Chrome DevTools MCP
  - [ ] Each criterion in `screenshot.verify` checked
  - [ ] Observations documented
- [ ] Verification results document created
- [ ] No BLOCKING or MAJOR failures
