# Task: [TODO: TITLE]

# <!--

# ORCHESTRATOR PRE-FLIGHT CHECKLIST

Complete ALL items below. This section will be SAVED to verification/ folder
then DELETED before implementor sees this file.

- [ ] I have READ `.orchestra/readme.md` (not from memory!)
- [ ] I have READ `.orchestra/manifest.yaml` for this task's details
- [ ] I have READ the SpecKit `tasks.md` for detailed requirements
- [ ] I have identified task type: [ ] Logic [ ] Visual/Rendering [ ] Integration
- [ ] If VISUAL: I have included Section 7 (flutter_agent.py workflow)
- [ ] If INTEGRATION: I have listed files that MUST be modified (not just created)
- [ ] I have filled ALL sections below (content or [N/A] with reason)
- [ ] No [TODO] markers remain in this document (except title which gets filled)
- [ ] I have saved this checklist to `.orchestra/verification/orchestrator-preflight-NNN.md`

AFTER completing checklist:

1. Save checklist section to verification folder
2. Delete this entire HTML comment block
3. # Proceed to invoke implementor
   -->

## 1. Task Overview

[TODO: Brief description of what this task accomplishes]

**Phase**: [TODO: Foundation / Core Normalization / Rendering / Widget Integration]

---

## 2. SpecKit Traceability

**SpecKit Tasks Covered**:

- [TODO: T0XX - Description]
- [TODO: T0XX - Description]

**Contract References** (if applicable):

- [TODO: Path to contract file, or N/A]

---

## 3. Deliverables

### Files to CREATE:

| File         | Purpose         |
| ------------ | --------------- |
| [TODO: path] | [TODO: purpose] |

### Files to MODIFY:

| File                | Changes              |
| ------------------- | -------------------- |
| [TODO: path or N/A] | [TODO: what changes] |

---

## 4. Technical Context

### Dependencies (imports from completed tasks):

```dart
// [TODO: List imports from prior tasks]
import 'package:braven_charts/src/...';
```

### ⚠️ MUST USE (DO NOT DUPLICATE):

These existing utilities MUST be used. Do NOT reimplement their logic inline.

| Utility | Use For | DO NOT |
|---------|---------|--------|
| [TODO: e.g., MultiAxisNormalizer.normalize()] | [TODO: e.g., Converting data values to 0-1 range] | [TODO: e.g., Inline (value - min) / (max - min)] |

[N/A - Reason: No existing utilities apply to this task]

### Relevant Existing Code:

- [TODO: Reference existing files/classes implementor should understand]

---

## 5. TDD Requirements

**Test File**: `[TODO: test/unit/multi_axis/xxx_test.dart]`

**Test Cases to Implement FIRST**:

1. [TODO: Test case 1]
2. [TODO: Test case 2]
3. [TODO: Test case 3]

[N/A - Reason: _____________] ← Use this format if TDD not applicable

---

## 6. Code Scaffolds

[TODO: Provide starter code structure, OR mark N/A]

```dart
// [TODO: Scaffold code here]
```

[N/A - Reason: Implementor should design from scratch] ← Example N/A

---

## 7. Visual Verification

**Task Category**: [TODO: INFRASTRUCTURE / INTEGRATION / VISUAL]

### INFRASTRUCTURE Tasks (NO visual verification):

Infrastructure tasks create classes, methods, and logic that are NOT yet wired
into the main widget. Visual verification is PREMATURE for these tasks.

[N/A - Reason: Infrastructure task. Creates [component] but does not integrate
into BravenChartPlus. Visual verification will occur in integration task.]

### INTEGRATION / VISUAL Tasks (REQUIRE visual verification):

These tasks wire components into BravenChartPlus or modify rendering. A
STANDALONE demo is required to isolate the visual behavior being tested.

#### Step 1: Create Standalone Demo File

**Demo Path**: `example/lib/demos/task_[NNN]_[name]_demo.dart`

```dart
// [TODO: Provide minimal self-contained demo that shows ONLY this task's output]
// Must be runnable independently - no navigation required
// Example scaffold:
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

void main() => runApp(const TaskNNNDemo());

class TaskNNNDemo extends StatelessWidget {
  const TaskNNNDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: BravenChartPlus(
              // [TODO: Minimal config showing THIS task's feature]
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Step 2: Flutter Agent Workflow

1. **Start Flutter with the standalone demo** (from repo root):

```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_NNN_demo.dart -d chrome"
```

2. **Wait for app to be ready**:

```powershell
cd "e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example"
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 30
```

3. **Take screenshot**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py screenshot
```

4. **Stop when done**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py stop
```

**Expected Visual Output**:

- [TODO: Describe EXACTLY what should be visible in the screenshot]
- [TODO: List specific elements to verify (positions, labels, colors)]

---

## 8. Quality Gates (MANDATORY)

### Linting - Zero Issues

```bash
flutter analyze [TODO: lib/src/path/to/impl.dart]
flutter analyze [TODO: test/path/to/test.dart]
```

### All Sprint Tests Must Pass

```bash
flutter test test/unit/multi_axis/
flutter test test/integration/multi_axis_*.dart
```

**Current Test Baseline**: [TODO: NNN] tests (MUST NOT decrease!)

---

## 9. Completion Protocol

When done:

1. **Verify linting is clean** (BLOCKING)
2. **Verify ALL tests pass** (BLOCKING)
3. **Visual verification completed** (if applicable)
4. Stage your changes: `git add .`
5. Write to `.orchestra/handover/completion-signal.md`:
   - Files created/modified
   - Number of tests added
   - Confirm linting clean
   - Confirm all sprint tests pass
   - Visual verification notes (if applicable)
6. Say "Task complete - ready for review"
