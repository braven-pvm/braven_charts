# Implementation Integration Checklist

## PURPOSE

This checklist exists because of a CRITICAL FAILURE where an entire sprint was marked complete with passing tests, but **NONE of the new code was actually connected to the application**.

### The Failure Pattern

```
❌ What Happened:
   Task: "Integrate multi-axis rendering into chart pipeline"
   Agent: Created new file chart_painter.dart with MultiAxisPainter class
   Test: expect(find.byType(BravenChartPlus), findsOneWidget) ← PASSED
   Reality: ChartRenderBox.paint() NEVER calls MultiAxisPainter
   User: "Why doesn't multi-axis work?"
   
✅ What Should Have Happened:
   Task: "Integrate multi-axis rendering into chart pipeline"
   Agent: MODIFIED chart_render_box.dart to call MultiAxisPainter
   Test: Verified multiple axes actually render with visual/golden tests
   Reality: ChartRenderBox.paint() calls MultiAxisPainter.paint()
   User: Multi-axis feature works as expected
```

---

## PART 1: PRE-IMPLEMENTATION VERIFICATION

### Before Writing ANY Code

- [ ] I have identified the **ENTRY POINT** where new code must be called from
- [ ] I can name the **EXACT FILE** that will be modified (not just created)
- [ ] I can name the **EXACT METHOD** that will call the new code
- [ ] I have read and understand the existing entry point method

### Entry Point Identification

For this task, complete this section:

```
ENTRY POINT FILE: ___________________________________
ENTRY POINT METHOD: ________________________________
CURRENT LINE OF EXECUTION: _________________________
HOW NEW CODE CONNECTS: _____________________________
```

### Example (Multi-Axis Feature)

```
ENTRY POINT FILE: lib/src_plus/rendering/chart_render_box.dart
ENTRY POINT METHOD: paint(PaintingContext context, Offset offset)
CURRENT LINE OF EXECUTION: Line 3122 - AxisRenderer(_yAxis!, ...).paint(...)
HOW NEW CODE CONNECTS: Replace single axis render with MultiYAxisRenderer loop
```

---

## PART 2: DURING IMPLEMENTATION

### For Every New Class/Method Created

- [ ] I can trace the call path FROM the entry point TO this new code
- [ ] The call chain has **ZERO GAPS**
- [ ] Every method in the chain **EXISTS AND IS IMPLEMENTED**

### Call Chain Verification

Document the complete call chain:

```
1. [Entry Point] calls →
2. [Intermediate Step] calls →
3. [Intermediate Step] calls →
4. [New Code]
```

### Example (Correct)

```
1. ChartRenderBox.paint() calls →
2. _paintYAxes() [NEW METHOD] calls →
3. MultiYAxisRenderer.render() [NEW CLASS]
```

### Example (INCORRECT - Gap in Chain)

```
1. ChartRenderBox.paint() calls →
2. ??? (Nothing calls the new code!)
3. MultiYAxisRenderer.render() [NEW CLASS - NEVER CALLED!]
```

---

## PART 3: THE INTEGRATION PROOF

### This is the CRITICAL Check

After implementation, I can prove integration by:

- [ ] Running `git diff` shows modifications to the ENTRY POINT FILE
- [ ] The entry point method now contains a call to the new code
- [ ] I can set a breakpoint in the new code and it gets hit during execution
- [ ] Commenting out the new code causes visible/testable changes

### Integration Evidence (REQUIRED)

```
git diff --name-only HEAD~1

Expected output MUST include:
- The entry point file (e.g., chart_render_box.dart)
- The new implementation file(s)

If the entry point file is NOT in the diff, INTEGRATION IS NOT COMPLETE.
```

### The Delete Test (MANDATORY)

```dart
// 1. Comment out the integration call:
// _multiAxisRenderer.render(...); 

// 2. Run the feature
// 3. EXPECTED: Feature visibly breaks or tests fail
// 4. If nothing changes, the code was never connected!
```

---

## PART 4: COMMON FAILURE PATTERNS

### ❌ Pattern 1: "Create New File" Instead of "Integrate"

```
Task says: "Integrate X into Y"
Agent does: Creates new file X
Agent should: Modifies Y to call X
```

**Prevention**: For any "integrate" task, the git diff MUST show changes to the target file.

### ❌ Pattern 2: Widget Has Parameter But Doesn't Use It

```dart
// Widget accepts configuration:
BravenChartPlus(
  yAxes: [axis1, axis2, axis3],  // Config exists
);

// But render box never receives it:
class ChartRenderBox {
  // No yAxes property!
  // No setYAxes() method!
}
```

**Prevention**: Trace every config parameter from widget through to render output.

### ❌ Pattern 3: "Working" Tests That Test Nothing

```dart
testWidgets('multi-axis works', (tester) async {
  await tester.pumpWidget(MyWidget(yAxes: multipleAxes));
  expect(find.byType(MyWidget), findsOneWidget);  // TESTS NOTHING!
});
```

**Prevention**: Tests MUST verify specific output, not just widget existence.

### ❌ Pattern 4: Creating Supporting Code But Not The Glue

```
Files created:
✅ multi_axis_normalizer.dart (math utilities)
✅ y_axis_renderer.dart (rendering utilities)
✅ axis_color_resolver.dart (color utilities)

Files modified:
❌ chart_render_box.dart (NOTHING CHANGED!)

Result: Beautiful supporting code that nothing ever calls.
```

**Prevention**: Track which core files need modification, verify they're actually changed.

---

## PART 5: VERIFICATION SCRIPT

Run this verification after any "integrate" task:

```bash
# 1. Check git diff includes the entry point file
git diff --name-only HEAD~1 | grep "chart_render_box.dart"

# If grep finds nothing, INTEGRATION IS NOT COMPLETE

# 2. Search for actual usage of new code in entry point
grep -n "MultiYAxisRenderer\|multiAxis\|_yAxes" lib/src_plus/rendering/chart_render_box.dart

# If grep finds nothing, NEW CODE IS NOT BEING USED

# 3. Run the feature and verify visually
flutter run -d chrome
# Navigate to feature, verify it works WITH YOUR EYES
```

---

## PART 6: INTEGRATION TASK TEMPLATE

Every integration task MUST specify:

```markdown
## Task: [Task Name]

### Integration Target
- **File to Modify**: [exact path to existing file]
- **Method to Modify**: [exact method name]
- **Current Behavior**: [what happens now]
- **New Behavior**: [what should happen after]

### New Code to Create
- **File**: [path to new file]
- **Class/Function**: [name]
- **Called From**: [exact location in integration target]

### Verification
1. [ ] git diff shows changes to [integration target file]
2. [ ] [Method name] now calls [new code]
3. [ ] Feature visibly works when tested
4. [ ] Commenting out integration call breaks the feature

### Acceptance Criteria
- [ ] Entry point file is modified (not just new files created)
- [ ] New code is called during execution
- [ ] Feature produces visible/testable output
- [ ] Delete test confirms integration
```

---

## SUMMARY: THE GOLDEN RULE

> **If you're "integrating" something and your git diff only shows NEW files, you haven't integrated anything.**

Integration means MODIFYING existing code to USE new code. Creating new code in isolation is not integration—it's just creating orphaned files.

### Before Marking Any Integration Task Complete

1. ✅ Entry point file is in git diff
2. ✅ New code is called from entry point
3. ✅ Feature visibly/testably works
4. ✅ Delete test passes (commenting out breaks it)

If ANY of these fail, the task is NOT complete.
