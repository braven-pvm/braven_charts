# Visual Verification

> **Navigation**: [Index](../readme.md) | **Prev**: [Verification Protocol](verification-protocol.md) | **Next**: [Failure Handling](failure-handling.md)

---

## Overview

Visual verification is the process of confirming that rendered output matches expected visual criteria. This is critical for catching rendering bugs that tests cannot detect.

## The Visual Verification Gap

### The Incident (2025-12-01)

During Task 16 (final demo), human observer noticed both data series were NOT scaling correctly vertically. The normalization was visually broken.

**What was true**:
- App ran without errors
- Screenshot file existed
- Tests passed
- File was not empty

**What was wrong**:
- Actual visual output didn't match specification
- One series was compressed instead of spanning full height

**Detection**: Human caught it, not the automated process.

### The Lesson

> **"Screenshot exists" ≠ "Screenshot is correct"**

File existence checks cannot verify content. An implementor could create an empty, wrong, or placeholder image that passes all existence checks.

## Two Phases of Visual Verification

| Phase | Actor | Tool | Purpose |
|-------|-------|------|---------|
| CAPTURE | Implementor | `flutter_agent.py` | Run app, take screenshot |
| VIEW | Orchestrator | Chrome DevTools MCP | View existing file, verify content |

These are completely different operations with different tools.

## Phase 1: Screenshot Capture (Implementor)

### When to Capture

Capture screenshots for:
- INTEGRATION tasks (proves wiring works)
- VISUAL tasks (proves rendering correct)

Do NOT capture for:
- INFRASTRUCTURE tasks (components not yet integrated)

### Tool: flutter_agent.py

**Location**: `tools/flutter_agent/flutter_agent.py`

The `flutter_agent.py` tool runs Flutter apps and captures screenshots via file-based IPC.

### Capture Workflow

```powershell
# 1. Start Flutter in SEPARATE window (CRITICAL!)
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_NNN_demo.dart -d chrome"

# 2. Wait for app ready (from agent's terminal)
python tools/flutter_agent/flutter_agent.py wait --timeout 60

# 3. Take screenshot
python tools/flutter_agent/flutter_agent.py screenshot --output .orchestra/handover/verification/screenshots/task-NNN-feature.png

# 4. Stop app
python tools/flutter_agent/flutter_agent.py stop
```

### Why Separate Window?

If you run `flutter run` in the agent's terminal:
- Subsequent commands go to the SAME terminal
- This kills the Flutter process
- No way to interact with running app

Starting via `Start-Process` creates a completely separate PowerShell window.

### Prohibited Approaches

| Approach | Why It Fails |
|----------|--------------|
| `flutter run` in agent terminal | Commands kill the process |
| `run_in_terminal` with Flutter | Same problem |
| `tools/flutter_runner.py` | Deprecated, use flutter_agent.py |
| Chrome DevTools MCP for capture | Can't connect to Flutter's Chrome instance |

## Phase 2: Screenshot Viewing (Orchestrator)

### When to View

View screenshots for:
- All tasks with `screenshot.required: true`
- Any task where visual output matters

### Tool: Chrome DevTools MCP

The Chrome DevTools MCP can open local files and return the image content to the agent.

### View Workflow

```
# 1. Open file in browser via file:// URL
mcp_chrome-devtoo_new_page(url: "file:///E:/full/path/to/screenshot.png")

# 2. Capture what's displayed (returns image to agent)
mcp_chrome-devtoo_take_screenshot()

# 3. Agent now has the image in context and can analyze it!

# 4. Close browser page when done
mcp_chrome-devtoo_close_page(pageIdx: 1)
```

### What to Check

The orchestrator must verify EACH criterion in `screenshot.verify`:

```yaml
screenshot:
  verify:
    - "Multiple Y-axes visible (left and right)"
    - "Each axis has distinct color matching its series"
    - "All series span full vertical height"
    - "Axis labels show original values (not 0-1)"
```

For EACH criterion:
1. Look at the returned image
2. Determine if criterion is satisfied
3. Document observation
4. Record PASS or FAIL

### Documentation Example

```
VISUAL VERIFICATION: Task 16

Criterion: "Multiple Y-axes visible (left and right)"
  Observation: Left axis labeled "Power (W)", right axis labeled "Volume (L)"
  Status: PASS

Criterion: "Each axis has distinct color"
  Observation: Left axis is blue (#2196F3), right axis is green (#4CAF50)
  Status: PASS

Criterion: "All series span full vertical height"
  Observation: Power series spans ~80% of height. Volume series compressed to 
               top 20%, appears as nearly flat line despite range 0.5-4.0L
  Status: FAIL

Criterion: "Axis labels show original values"
  Observation: Left shows "0, 100, 200, 300", right shows "0.5, 1.5, 2.5, 3.5"
  Status: PASS

OVERALL: FAILED - Criterion "All series span full vertical height" not met
```

## Task Categories and Visual Requirements

| Category | Screenshot Required | Rationale |
|----------|--------------------| ----------|
| INFRASTRUCTURE | No | Not integrated into visible UI yet |
| INTEGRATION | Yes | Must prove wiring works visually |
| VISUAL | Yes | Must prove rendering is correct |

### Handling INFRASTRUCTURE Tasks

For INFRASTRUCTURE tasks, use N/A with reason:

```markdown
## Visual Verification

**[N/A - Reason: Infrastructure task]**

This task creates foundational classes (MultiAxisPainter) but does NOT integrate 
them into BravenChartPlus. Visual verification will occur when these components 
are wired in (Task 10: Multi-Axis Integration).
```

### Handling INTEGRATION/VISUAL Tasks

For INTEGRATION and VISUAL tasks, include full workflow:

```markdown
## Visual Verification

**Task Category**: INTEGRATION

### Demo File
Create: `example/lib/demos/task_010_demo.dart`

### Screenshot Workflow
[Full flutter_agent.py workflow]

### Expected Visual Output
- Multiple axes should be visible (left and right)
- Each axis should have distinct coloring
- Both series should span the full vertical height
```

## Designing Effective Screenshots

### Good Screenshot Criteria

| Good | Bad |
|------|-----|
| "Multiple axes visible with distinct colors" | "Chart looks correct" |
| "Series spans 80%+ of vertical space" | "Series is visible" |
| "Tooltip shows original value (not normalized)" | "Tooltip works" |
| "Left axis labeled 'Power (W)', right labeled 'Volume (L)'" | "Labels present" |

### Tips for Specification

1. **Be specific**: Name expected values, colors, positions
2. **Be measurable**: "80% of height" not "most of height"
3. **Include contrast**: Criteria should distinguish correct from incorrect
4. **Cover edge cases**: What should NOT appear?

### Demo File Design

Create demos that reveal issues:

```dart
// GOOD: Uses diverse data that reveals normalization issues
final powerData = [0, 50, 100, 200, 300, 250, 150]; // Range: 0-300
final volumeData = [0.5, 1.0, 2.0, 4.0, 3.5, 2.5, 1.5]; // Range: 0.5-4.0

// BAD: Uses similar ranges that hide normalization issues  
final data1 = [0, 25, 50, 75, 100];
final data2 = [0, 20, 40, 60, 80];
```

## Error Handling

### Screenshot Doesn't Exist

```
CHECK: screenshot_exists (BLOCKING)
  Path: .orchestra/handover/verification/screenshots/task-016-*.png
  Result: FAIL - No matching files found

TASK FAILED: Missing required screenshot artifact
```

### Screenshot Is Empty/Corrupt

```
CHECK: screenshot_valid
  File: task-016-showcase.png
  Size: 0 bytes
  Result: FAIL - File is empty

TASK FAILED: Screenshot artifact is invalid
```

### Screenshot Exists But Wrong Content

```
VISUAL: "All series span full vertical height"
  Observation: Volume series compressed to 20% of available space
  Status: FAIL

TASK FAILED: Screenshot content does not match criteria
```

## Integration with Verification Protocol

Visual verification is Step 6 in the verification workflow:

1. Accept signal check
2. Load verification criteria
3. Structural checks
4. Functional checks
5. Adversarial checks
6. **Visual verification** ← Here
7. Determine result
8. Document results
9. Handle result

Visual failure at severity BLOCKING or MAJOR fails the entire task.

## Checklist

### Implementor (Capture)

- [ ] Task is INTEGRATION or VISUAL (not INFRASTRUCTURE)
- [ ] Demo file created with diverse test data
- [ ] flutter_agent.py started in SEPARATE window
- [ ] Wait for app ready before screenshot
- [ ] Screenshot saved to verification/screenshots/
- [ ] App stopped after capture
- [ ] Screenshot path noted in completion-signal.md

### Orchestrator (View)

- [ ] Screenshot file exists (Test-Path)
- [ ] Screenshot file has content (not empty)
- [ ] Opened via Chrome DevTools MCP (mcp_chrome-devtoo_new_page)
- [ ] Captured via take_screenshot
- [ ] For EACH criterion in screenshot.verify:
  - [ ] Analyzed what's visible
  - [ ] Determined pass/fail
  - [ ] Documented observation
- [ ] Browser page closed
- [ ] Results documented in verification-results.md
