# Screenshot Verification Protocol

**Version**: 1.0.0  
**Created**: 2025-11-28  
**Purpose**: Standardized screenshot capture and verification for visual features

---

## Overview

For any task involving visual/UI changes, screenshots serve as **proof of implementation**. This document defines:

1. **Naming conventions** - How to name screenshots for traceability
2. **Capture requirements** - When and how to take screenshots
3. **Verification process** - How verifiers validate screenshots
4. **Storage and linking** - Where screenshots go and how to reference them

---

## Screenshot Naming Convention

### Standard Format

```
{TaskID}_{TestName}_{Step}_{Description}.png
```

**Components:**
| Component | Description | Example |
|-----------|-------------|---------|
| `TaskID` | Task number from tasks.md | `T015` |
| `TestName` | Name of the integration test | `zoom_test` |
| `Step` | Sequential step number | `01`, `02`, `03` |
| `Description` | What the screenshot shows | `after_keyboard_zoom` |

**Examples:**
```
T015_zoom_test_01_initial_state.png
T015_zoom_test_02_after_keyboard_zoom.png
T015_zoom_test_03_after_scroll_zoom.png
T023_tooltip_test_01_hover_data_point.png
T023_tooltip_test_02_tooltip_visible.png
```

### For Proof Tests (General Verification)

```
proof_{feature}_{step}_{description}.png
```

**Examples:**
```
proof_multi_axis_01_initial.png
proof_multi_axis_02_normalized.png
proof_chart_navigation_01_home_screen.png
proof_chart_navigation_02_chart_screen.png
```

---

## In-Test Screenshot Implementation

### Standard Pattern

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // TASK ID constant for traceability
  const String taskId = 'T015';
  const String testName = 'zoom_test';
  
  testWidgets('$taskId: Zoom functionality test', (WidgetTester tester) async {
    // Step 1: Initial state
    app.main();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('${taskId}_${testName}_01_initial_state');
    
    // Step 2: After keyboard zoom
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('${taskId}_${testName}_02_after_keyboard_zoom');
    
    // Step 3: After scroll zoom
    // ... interaction code ...
    await binding.takeScreenshot('${taskId}_${testName}_03_after_scroll_zoom');
  });
}
```

### Screenshot Manifest Comment

Every integration test file MUST include a manifest comment at the top:

```dart
/// SCREENSHOT MANIFEST for Task T015
/// 
/// This test produces the following screenshots:
/// - T015_zoom_test_01_initial_state.png - Chart before any zoom
/// - T015_zoom_test_02_after_keyboard_zoom.png - Chart after 5x keyboard zoom
/// - T015_zoom_test_03_after_scroll_zoom.png - Chart after shift+scroll zoom
/// 
/// Screenshots saved to: example/screenshots/
/// 
/// VERIFICATION: Compare against expected behavior in spec.md Section 3.2
```

---

## Capture Requirements

### When to Capture Screenshots

| Scenario | Required Screenshots |
|----------|---------------------|
| **UI Feature** | Before, During (if multi-step), After |
| **Interaction** | Before interaction, After each interaction type |
| **Animation** | Start state, End state (intermediate optional) |
| **Error Handling** | Normal state, Error state displayed |
| **Navigation** | Each screen in the flow |

### Minimum Screenshots per Task Type

| Task Type | Minimum Screenshots |
|-----------|---------------------|
| `[NEW]` UI component | 1 (component rendered) |
| `[MOD]` visual change | 2 (before implied by baseline, after required) |
| `[INT]` UI integration | 2 (component in isolation, component in context) |
| Interaction feature | 3 (initial, during, final) |

---

## Screenshot Storage

### Directory Structure

```
example/
├── screenshots/                    # Raw test output (gitignored)
│   ├── T015_zoom_test_01_initial_state.png
│   ├── T015_zoom_test_02_after_keyboard_zoom.png
│   └── ...
│
docs/
├── verification/
│   ├── T015/                       # Task-specific verification folder
│   │   ├── screenshots/            # Curated/verified screenshots
│   │   │   ├── T015_zoom_test_01_initial_state.png
│   │   │   └── T015_zoom_test_02_after_keyboard_zoom.png
│   │   ├── verification.md         # Verification notes
│   │   └── test_output.txt         # Test run output
│   └── README.md
```

### Workflow

1. **Test runs** → Screenshots saved to `example/screenshots/`
2. **Verification** → Verifier reviews screenshots
3. **Approval** → Copy approved screenshots to `docs/verification/T###/screenshots/`
4. **Commit** → Verification artifacts committed as proof

---

## Verifier Protocol

### Pre-Verification Checklist

Before reviewing screenshots:

- [ ] Confirm task ID matches screenshot prefix
- [ ] Confirm all expected screenshots exist (check manifest)
- [ ] Confirm screenshots are recent (check file timestamps)

### Visual Verification Checklist

For each screenshot:

- [ ] **Identifiable**: Can clearly see what the screenshot is showing
- [ ] **Matches Description**: Screenshot matches its filename description
- [ ] **Shows Feature**: The feature being tested is visible and functioning
- [ ] **No Errors**: No error dialogs, red screens, or console errors visible
- [ ] **Consistent**: Multiple screenshots show logical progression

### Comparison Verification

| Check | How to Verify |
|-------|---------------|
| Feature visible | Compare to mockup/spec if available |
| State change | Compare before/after screenshots |
| Correct behavior | Does the visual match the expected outcome in spec? |

### Screenshot Verification Report

Template for verification notes:

```markdown
# Screenshot Verification: T015

**Task**: T015 - Implement keyboard zoom
**Test File**: `example/integration_test/zoom_test.dart`
**Screenshots Reviewed**: 3
**Date**: 2025-11-28
**Verifier**: [Name/Agent ID]

## Screenshots

### T015_zoom_test_01_initial_state.png
- [x] Chart visible at default zoom level
- [x] Axes labels readable
- [x] Data series rendered correctly

### T015_zoom_test_02_after_keyboard_zoom.png
- [x] Chart visibly zoomed in (compare to 01)
- [x] Zoom level indicator updated (if applicable)
- [x] Data still renders correctly at zoom level

### T015_zoom_test_03_after_scroll_zoom.png
- [x] Additional zoom visible (compare to 02)
- [x] No rendering artifacts
- [x] Consistent with expected behavior

## Verdict

- [x] **PASS** - All screenshots verify expected behavior
- [ ] **FAIL** - Issues found (document below)

## Notes
[Any observations or concerns]
```

---

## Linking Screenshots to Tasks

### In tasks.md

```markdown
- [ ] T015 [US1] [INT] Implement keyboard zoom in BravenChart

  **Verification Artifacts:**
  - Integration test: `example/integration_test/T015_zoom_test.dart`
  - Screenshots: `docs/verification/T015/screenshots/`
  - Verification report: `docs/verification/T015/verification.md`
```

### In Test Files

```dart
/// Links to Task: T015
/// Spec Reference: spec.md Section 3.2 - Zoom Interactions
/// Expected Screenshots: 3
/// Screenshot Location: example/screenshots/T015_*.png
```

### In Verification Reports

```markdown
## Task Reference
- **Task ID**: T015
- **Task File**: `specs/011-feature/tasks.md` line 45
- **Test File**: `example/integration_test/T015_zoom_test.dart`
- **Screenshots**: See `docs/verification/T015/screenshots/`
```

---

## Automated Screenshot Validation (Future)

### Screenshot Manifest File

Each integration test can generate a manifest:

```json
{
  "taskId": "T015",
  "testFile": "example/integration_test/zoom_test.dart",
  "testName": "T015: Zoom functionality test",
  "runDate": "2025-11-28T14:30:00Z",
  "screenshots": [
    {
      "name": "T015_zoom_test_01_initial_state.png",
      "step": 1,
      "description": "Chart before any zoom",
      "path": "example/screenshots/T015_zoom_test_01_initial_state.png"
    },
    {
      "name": "T015_zoom_test_02_after_keyboard_zoom.png", 
      "step": 2,
      "description": "Chart after 5x keyboard zoom",
      "path": "example/screenshots/T015_zoom_test_02_after_keyboard_zoom.png"
    }
  ],
  "verified": false,
  "verifiedBy": null,
  "verifiedDate": null
}
```

---

## Quick Reference

### For Implementers

1. Add `taskId` and `testName` constants at top of test
2. Use `${taskId}_${testName}_##_description` naming pattern
3. Add SCREENSHOT MANIFEST comment at file top
4. Capture: initial state, after each interaction, final state

### For Verifiers

1. Check screenshot manifest matches actual files
2. Review each screenshot against its description
3. Compare before/after for state changes
4. Create verification report in `docs/verification/T###/`
5. Mark task complete only after screenshots verified

### Screenshot Checklist

```
□ Naming follows convention: {TaskID}_{TestName}_{Step}_{Description}.png
□ Manifest comment in test file lists all screenshots
□ Initial state captured before interactions
□ Final state captured after all interactions
□ Screenshots saved to example/screenshots/
□ Verified screenshots copied to docs/verification/T###/screenshots/
□ Verification report created
```

---

## See Also

- [Integration Testing Guide](../../../integration-testing.md) - How to run integration tests
- [Verification Framework](./verification-framework.md) - Complete verification protocol
- [Test Templates](./templates/widget-test-template.dart) - Test file templates
