# Sprint Verification Framework

**Version**: 1.0.0  
**Created**: 2025-11-28  
**Purpose**: Prevent implementation theater - ensure all sprint artifacts produce working, verified functionality

---

## Table of Contents

1. [Part 1: Artifact Creation Guidelines](#part-1-artifact-creation-guidelines)
   - [Task Specification Standards](#task-specification-standards)
   - [Test Creation Standards](#test-creation-standards)
   - [Integration Requirements](#integration-requirements)
2. [Part 2: Verification Protocol](#part-2-verification-protocol)
   - [Verification Checkpoints](#verification-checkpoints)
   - [Third-Party Verification Process](#third-party-verification-process)
   - [Red Flags & Automatic Failures](#red-flags--automatic-failures)
3. [Appendices](#appendices)
   - [Task Templates](#appendix-a-task-templates)
   - [Test Templates](#appendix-b-test-templates)
   - [Verification Checklists](#appendix-c-verification-checklists)

---

# Part 1: Artifact Creation Guidelines

## Core Principle: Provable Completion

> **Every artifact must answer: "How would someone PROVE this works?"**
> 
> If you cannot describe concrete, observable proof, the artifact is incomplete.

---

## Task Specification Standards

### 1.1 Task Anatomy

Every task MUST include these sections:

```markdown
## T### [Story] Task Title

### Functional Requirement Link
- FR-XXX: [Exact text from spec]
- SC-XXX: [Success criteria this satisfies]

### Task Type Classification
[ ] NEW_FILE - Creates new file(s) only
[ ] MODIFY_EXISTING - Changes existing file(s)
[ ] INTEGRATION - Connects components (MUST modify existing files)
[ ] TEST_ONLY - Adds tests without implementation

### Files Affected
**Create:**
- `path/to/new_file.dart` - Purpose

**Modify (REQUIRED for INTEGRATION tasks):**
- `path/to/existing_file.dart`
  - Function: `specificFunction()`
  - Lines: ~XXX-YYY
  - Change: Description of modification

### Acceptance Criteria (Observable)
1. [Criterion that can be visually or programmatically verified]
2. [Another observable criterion]

### Implementation Guidance
[Specific technical approach, NOT just "implement X"]

### Test Requirements
- Unit test: `test/unit/path/test_file.dart`
- Widget test: `test/widget/path/test_file.dart`
- Integration test: `test/integration/path/test_file.dart` (if applicable)

### Verification Artifacts (REQUIRED)
- [ ] Screenshot: `docs/verification/T###_description.png`
- [ ] Git diff: Must show changes to [specific files]
- [ ] Test output: Paste from `flutter test [path]`

### Definition of Done
- [ ] All tests pass
- [ ] Visual verification completed
- [ ] Git diff confirms expected file changes
- [ ] No "findsOneWidget" only assertions in tests
```

### 1.2 Task Type Rules

#### NEW_FILE Tasks
- ONLY creates new files
- Cannot claim "integration" - that's a separate task
- Must include unit tests for the new code
- Example: "Create MultiAxisNormalizer class"

#### MODIFY_EXISTING Tasks  
- MUST specify exact file, function, and approximate line numbers
- MUST show BEFORE and AFTER code snippets
- Git diff is primary verification
- Example: "Add setYAxes() method to ChartRenderBox"

#### INTEGRATION Tasks
- MUST modify at least TWO existing files
- MUST show data flow: Source → Consumer
- MUST include end-to-end test
- Example: "Connect YAxisConfig from widget to render box"

**🚨 CRITICAL RULE:**
> A task that says "integrate" but only creates new files is INVALID.
> Integration means connecting existing components, not creating new ones.

### 1.3 Forbidden Task Patterns

These patterns are BANNED and must be rewritten:

| ❌ Forbidden | ✅ Required |
|-------------|-------------|
| "Implement X in `new_file.dart`" | "Create X in `new_file.dart`, then call X from `existing_file.dart` line ~NNN" |
| "Add multi-axis support" | "Modify `ChartRenderBox.paint()` to call `MultiYAxisRenderer` when `_yAxes` is set" |
| "Integrate with chart" | "Add `setYAxes()` call in `_ChartRenderWidget.updateRenderObject()` at line ~2608" |
| "Update rendering" | "Replace single Y-axis paint at line 3122 with multi-axis loop" |

### 1.4 Task Wording Requirements

**Action Verbs That Require Proof:**

| Verb | Proof Required |
|------|----------------|
| CREATE | New file exists, has content, compiles |
| MODIFY | Git diff shows specific file changed |
| INTEGRATE | Git diff shows BOTH source and consumer changed |
| CONNECT | Data flows end-to-end (test proves it) |
| RENDER | Screenshot shows visual output |
| CALL | Debugger/log shows function invoked |

**Forbidden Vague Words:**
- "Support" (support how?)
- "Handle" (handle by doing what?)
- "Enable" (enable via what mechanism?)
- "Add functionality" (what functionality, where?)

---

## Test Creation Standards

### 2.1 Test Anatomy

Every test MUST follow this structure:

```dart
/// TEST: [Descriptive name matching requirement]
/// 
/// REQUIREMENT: FR-XXX / SC-XXX
/// 
/// PROVES: [What this test proves when it passes]
/// 
/// FAILURE MODE: [What broken behavior would this catch?]
/// 
/// VERIFICATION: [How a third party confirms this test is valid]
@TestMetadata(
  requirement: 'FR-004',
  provesWhen: 'Both series visually span full plot height',
  failureMode: 'One series appears as flat line',
)
testWidgets('multi-axis normalizes series to full height', (tester) async {
  // ARRANGE: Setup with specific, verifiable values
  
  // ACT: Perform the action
  
  // ASSERT: Meaningful assertions that PROVE functionality
  
  // VERIFICATION ARTIFACT: Generate proof
});
```

### 2.2 Assertion Requirements

#### BANNED Assertion Patterns

```dart
// ❌ BANNED: Tests nothing meaningful
expect(find.byType(BravenChartPlus), findsOneWidget);

// ❌ BANNED: Tautology (always true)
expect(widget != null, isTrue);

// ❌ BANNED: Only checks no crash
expect(tester.takeException(), isNull);

// ❌ BANNED: Vague matcher
expect(result, isNotNull);
```

#### REQUIRED Assertion Patterns

```dart
// ✅ REQUIRED: Tests specific behavior
expect(normalizer.normalizeY(50, min: 0, max: 100), equals(0.5));

// ✅ REQUIRED: Tests visual output
expect(find.text('Power (W)'), findsOneWidget);

// ✅ REQUIRED: Tests pixel positions
expect(leftAxisRect.right, lessThan(plotArea.left));
expect(rightAxisRect.left, greaterThan(plotArea.right));

// ✅ REQUIRED: Golden test for complex rendering
await expectLater(
  find.byType(BravenChartPlus),
  matchesGoldenFile('goldens/multi_axis_two_axes.png'),
);

// ✅ REQUIRED: Tests data flow end-to-end
expect(renderBox.yAxes, isNotNull);
expect(renderBox.yAxes!.length, equals(2));
```

### 2.3 The "Delete Test" Rule

> **Every test MUST fail if you delete/comment out the implementation.**

Before committing, verify:
```bash
# Comment out the implementation
# Run the test
# Test MUST fail
# Uncomment the implementation  
# Test MUST pass
```

If the test passes with implementation commented out, the test is WORTHLESS.

### 2.4 Test Categories & Requirements

| Category | Purpose | Required Assertions |
|----------|---------|---------------------|
| **Unit** | Logic works | Specific input → specific output |
| **Widget** | Renders correctly | Find specific widgets/text, verify layout |
| **Golden** | Visual regression | matchesGoldenFile with reference image |
| **Integration** | End-to-end flow | Data flows from input to visible output |

### 2.5 Test Documentation Block

Every test file MUST begin with:

```dart
/// # Test Suite: [Name]
/// 
/// ## Purpose
/// [What aspect of the feature this tests]
/// 
/// ## Requirements Covered
/// - FR-XXX: [Requirement text]
/// - SC-XXX: [Success criterion text]
/// 
/// ## Verification Instructions
/// 1. Run: `flutter test path/to/this_test.dart`
/// 2. Expected: All N tests pass
/// 3. Manual check: [Any manual verification needed]
/// 
/// ## Failure Investigation
/// If tests fail:
/// 1. [First thing to check]
/// 2. [Second thing to check]
/// 
/// ## Last Verified
/// - Date: YYYY-MM-DD
/// - By: [Name/Agent]
/// - Commit: [hash]
```

---

## Integration Requirements

### 3.1 Integration Task Checklist

For ANY task labeled "integrate", "connect", or "wire up":

```markdown
### Integration Verification

#### Source Component
- File: `path/to/source.dart`
- Exports: `ClassName`, `functionName`
- Verified export: [ ] Yes

#### Consumer Component  
- File: `path/to/consumer.dart`
- Imports source: [ ] Yes (show import line)
- Calls/uses source: [ ] Yes (show usage line)

#### Data Flow Proof
```
[Source] --[method/property]--> [Consumer] --[renders]--> [Visual Output]
```

#### Git Diff Requirement
MUST show changes to BOTH files:
```bash
git diff --stat HEAD~1
# Expected output includes:
# path/to/source.dart   | X +++
# path/to/consumer.dart | Y +++
```
```

### 3.2 Integration Anti-Patterns

| ❌ Anti-Pattern | Problem | ✅ Correct Approach |
|----------------|---------|---------------------|
| Create "integration point" | Code exists but isn't called | Create AND call in same task |
| "Ready for integration" | Defers actual connection | Integrate now, not later |
| New file imports existing | Direction is backwards | Existing code must import/call new code |
| Tests new code in isolation | Doesn't test integration | Test through the consumer |

---

# Part 2: Verification Protocol

## Verification Checkpoints

### 4.1 Checkpoint Types

| Checkpoint | When | Verifier | Artifacts Required |
|------------|------|----------|-------------------|
| **Task Start** | Before coding | Self | Task spec review |
| **Implementation** | Code written | Self | Git diff, test results |
| **Task Complete** | Marked done | Third Party | Full verification package |
| **Phase Complete** | Phase ends | Third Party | All phase tasks verified |
| **Sprint Complete** | Sprint ends | Third Party | Visual demo + all proofs |

### 4.2 Task Completion Verification Package

Every completed task MUST produce:

```
docs/verification/T###/
├── README.md           # Summary of what was done
├── git_diff.txt        # Output of git diff for this task
├── test_output.txt     # Output of flutter test
├── screenshot.png      # Visual proof (if UI-related)
├── code_snippets.md    # Key code changes with context
└── checklist.md        # Completed verification checklist
```

### 4.3 Verification Checklist Template

```markdown
# Task T### Verification

## Basic Checks
- [ ] Task type correctly classified (NEW_FILE/MODIFY_EXISTING/INTEGRATION)
- [ ] All specified files exist
- [ ] Code compiles without errors
- [ ] No new lint warnings introduced

## Git Verification
- [ ] Git diff attached
- [ ] Diff shows expected files modified
- [ ] For INTEGRATION: Multiple files in diff
- [ ] Commit message references task ID

## Test Verification  
- [ ] Test file exists at specified path
- [ ] Tests have meaningful assertions (not just findsOneWidget)
- [ ] Tests pass: `flutter test [path]`
- [ ] "Delete test" verified: Tests fail when implementation commented out

## Visual Verification (if applicable)
- [ ] Screenshot attached
- [ ] Screenshot shows expected visual output
- [ ] Before/after comparison (if modifying existing behavior)

## Integration Verification (for INTEGRATION tasks)
- [ ] Data flows from source to consumer
- [ ] Consumer actually calls/uses source
- [ ] End-to-end test proves connection works

## Requirement Traceability
- [ ] FR-XXX addressed: [How]
- [ ] SC-XXX satisfied: [Evidence]

## Sign-off
- Implementer: _________ Date: _________
- Verifier: _________ Date: _________
```

---

## Third-Party Verification Process

### 5.1 Verifier Role

The third-party verifier:
- Does NOT write code
- Does NOT fix issues (reports them)
- DOES check artifacts against requirements
- DOES run tests independently
- DOES inspect visual evidence
- DOES validate git history

### 5.2 Verification Steps

```markdown
## Third-Party Verification Protocol

### Step 1: Artifact Check (2 min)
1. Open `docs/verification/T###/`
2. Confirm all required files present:
   - [ ] README.md
   - [ ] git_diff.txt
   - [ ] test_output.txt
   - [ ] screenshot.png (if UI task)
   - [ ] checklist.md

**FAIL FAST**: Missing artifacts = REJECTED

### Step 2: Git Diff Review (3 min)
1. Open `git_diff.txt`
2. Check files modified match task spec
3. For INTEGRATION tasks: Confirm 2+ files changed
4. Look for actual code changes (not just comments)

**RED FLAGS**:
- Only new files created for "integration" task
- Changes only in test files
- Trivial changes (imports only, no logic)

### Step 3: Test Validation (5 min)
1. Read test file specified in task
2. Check assertions:
   ```
   grep -n "expect(" test_file.dart | head -20
   ```
3. Confirm NO banned patterns:
   - `findsOneWidget` as only assertion
   - `isNotNull` without follow-up
   - No specific value checks

4. Run tests independently:
   ```bash
   flutter test path/to/test_file.dart
   ```
5. Confirm output matches `test_output.txt`

**RED FLAGS**:
- Tests pass but assertions are trivial
- Test names don't match what they test
- Comments say "TODO: add real assertions"

### Step 4: Visual Verification (2 min, if applicable)
1. Open `screenshot.png`
2. Compare to expected behavior in task spec
3. Confirm visible output matches requirement

**RED FLAGS**:
- Screenshot shows error/blank screen
- Screenshot doesn't show the feature being tested
- "Before" and "After" look identical

### Step 5: Code Sanity Check (3 min)
1. Open modified files
2. Confirm new code is actually reachable:
   - Search for callers of new functions
   - Trace data flow from entry point
3. Look for dead code (created but never called)

**RED FLAGS**:
- New class/function with zero callers
- "TODO: integrate this" comments
- Isolated code islands

### Step 6: Final Verdict
- [ ] APPROVED - All checks pass
- [ ] REJECTED - Reason: _______________
- [ ] NEEDS WORK - Issues: _______________
```

### 5.3 Verification Report Template

```markdown
# Verification Report: T###

**Task**: [Title]
**Verifier**: [Name]
**Date**: [YYYY-MM-DD]
**Commit**: [hash]

## Artifact Check
| Artifact | Present | Valid |
|----------|---------|-------|
| README.md | ✅/❌ | ✅/❌ |
| git_diff.txt | ✅/❌ | ✅/❌ |
| test_output.txt | ✅/❌ | ✅/❌ |
| screenshot.png | ✅/❌/N/A | ✅/❌/N/A |
| checklist.md | ✅/❌ | ✅/❌ |

## Git Diff Analysis
- Files modified: [list]
- Expected files: [list]
- Match: ✅/❌
- Integration verified: ✅/❌/N/A

## Test Analysis
- Test file: [path]
- Assertions found: [count]
- Meaningful assertions: ✅/❌
- Tests run independently: ✅/❌
- All tests pass: ✅/❌

## Visual Verification
- Screenshot reviewed: ✅/❌/N/A
- Shows expected output: ✅/❌/N/A

## Code Reachability
- New code has callers: ✅/❌
- Data flow verified: ✅/❌

## Red Flags Found
- [ ] None
- [ ] [Description of issue]

## Verdict
**STATUS**: APPROVED / REJECTED / NEEDS WORK

**Notes**: [Any additional comments]

**Signature**: _____________ Date: _____________
```

---

## Red Flags & Automatic Failures

### 6.1 Instant Rejection Criteria

The following trigger IMMEDIATE task rejection:

| Red Flag | Why It's Fatal |
|----------|----------------|
| Missing verification artifacts | No proof = no completion |
| `expect(find.byType(X), findsOneWidget)` as only assertion | Tests nothing |
| "Integration" task with only new files | Not actually integrated |
| Test passes with implementation commented out | Test is worthless |
| Screenshot shows single Y-axis for multi-axis task | Feature doesn't work |
| Git diff shows only test file changes | No implementation |
| "TODO: implement" in committed code | Incomplete work |
| No callers for new public function | Dead code |

### 6.2 Warning Signs (Require Explanation)

| Warning | Required Response |
|---------|------------------|
| Very short git diff for complex task | Explain why minimal changes |
| All tests pass first time | Confirm "delete test" was done |
| No visual verification for UI task | Justify why not needed |
| Single file changed for "integration" | Explain integration path |

### 6.3 Code Smell Patterns

```dart
// 🚨 SMELL: Test that tests nothing
testWidgets('should render multi-axis', (tester) async {
  await tester.pumpWidget(chart);
  expect(find.byType(BravenChartPlus), findsOneWidget); // FAIL: Proves nothing
});

// 🚨 SMELL: Comment acknowledging inadequacy
// Note: Actual verification depends on implementation
expect(find.byType(Widget), findsOneWidget); // FAIL: Admission of guilt

// 🚨 SMELL: Created but never used
class MultiAxisRenderer { // FAIL: No callers in codebase
  void render() { ... }
}

// 🚨 SMELL: Integration point without integration
/// Integration point for ChartRenderBox // FAIL: Point exists, integration doesn't
class ChartPainter { ... }
```

---

# Appendices

## Appendix A: Task Templates

### A.1 NEW_FILE Task Template

```markdown
## T### [Story] Create [Component Name]

### Functional Requirement Link
- FR-XXX: [Requirement text]

### Task Type Classification
[X] NEW_FILE - Creates new file(s) only
[ ] MODIFY_EXISTING
[ ] INTEGRATION
[ ] TEST_ONLY

### Files Affected
**Create:**
- `lib/path/to/component.dart` - [Purpose]

**Note:** This task creates the component. A SEPARATE integration task
will connect it to the existing system.

### Acceptance Criteria
1. File exists and compiles
2. Public API matches specification
3. Unit tests cover all public methods

### Test Requirements
- Unit test: `test/unit/path/component_test.dart`
  - Test each public method
  - Test edge cases documented in spec

### Verification Artifacts
- [ ] File exists at specified path
- [ ] `dart analyze` passes
- [ ] Unit tests pass
- [ ] No "TODO" comments in production code

### Definition of Done
- [ ] File created with complete implementation
- [ ] All public members documented
- [ ] Unit tests written and passing
- [ ] Ready for integration (separate task)
```

### A.2 MODIFY_EXISTING Task Template

```markdown
## T### [Story] Modify [Component] to [Change]

### Functional Requirement Link
- FR-XXX: [Requirement text]

### Task Type Classification
[ ] NEW_FILE
[X] MODIFY_EXISTING - Changes existing file(s)
[ ] INTEGRATION
[ ] TEST_ONLY

### Files Affected
**Modify:**
- `lib/path/to/existing.dart`
  - Function: `existingFunction()`
  - Lines: ~XXX-YYY
  - Change: [Specific modification]

### Current Code (BEFORE)
```dart
// Lines ~XXX-YYY of existing.dart
void existingFunction() {
  // Current implementation
}
```

### Required Code (AFTER)
```dart
// Lines ~XXX-YYY of existing.dart  
void existingFunction() {
  // Modified implementation
  newBehavior(); // Added
}
```

### Acceptance Criteria
1. Function behaves differently as specified
2. Existing tests still pass
3. New behavior covered by new tests

### Verification Artifacts
- [ ] Git diff shows changes to specified file
- [ ] Git diff shows changes at specified lines
- [ ] Before/after behavior demonstrated

### Definition of Done
- [ ] Existing file modified (not new file created)
- [ ] Changes at specified location
- [ ] All existing tests pass
- [ ] New behavior tested
```

### A.3 INTEGRATION Task Template

```markdown
## T### [Story] Integrate [Source] with [Consumer]

### Functional Requirement Link
- FR-XXX: [Requirement text]

### Task Type Classification
[ ] NEW_FILE
[ ] MODIFY_EXISTING
[X] INTEGRATION - Connects components (MUST modify existing files)
[ ] TEST_ONLY

### Files Affected
**Modify (REQUIRED - both files):**

1. `lib/path/to/consumer.dart`
   - Function: `consumerFunction()`
   - Lines: ~XXX-YYY
   - Change: Import and call source

2. `lib/path/to/source.dart` (if changes needed)
   - Function: `sourceFunction()`
   - Lines: ~XXX-YYY
   - Change: [Any modifications for integration]

### Data Flow
```
[Source Component] 
    ↓ via [method/property name]
[Consumer Component]
    ↓ via [render/process method]
[Observable Output]
```

### Integration Code

**Consumer changes (lib/path/to/consumer.dart):**
```dart
// Add import
import 'source.dart';

// In function at line ~XXX
void consumerFunction() {
  final source = Source();
  source.doThing(); // NEW: Actually use the source
}
```

### Acceptance Criteria
1. Source is imported by consumer
2. Source methods/properties are CALLED by consumer
3. Data flows end-to-end
4. Visual/observable output proves connection

### Verification Artifacts
- [ ] Git diff shows BOTH files modified
- [ ] Integration test proves data flow
- [ ] Screenshot shows connected output

### Anti-Pattern Check
- [ ] NOT just creating an "integration point"
- [ ] NOT creating new file that imports existing
- [ ] Consumer ACTUALLY CALLS source

### Definition of Done
- [ ] Both files modified
- [ ] Import statement added
- [ ] Source called from consumer
- [ ] End-to-end test passes
- [ ] Visual proof attached
```

---

## Appendix B: Test Templates

### B.1 Unit Test Template

```dart
// Copyright (c) [Year] [Project]. All rights reserved.
// Unit tests for [Component Name]

/// # Test Suite: [Component] Unit Tests
/// 
/// ## Purpose
/// Verify [Component] logic works correctly in isolation.
/// 
/// ## Requirements Covered
/// - FR-XXX: [Requirement text]
/// 
/// ## Verification Instructions
/// 1. Run: `flutter test test/unit/path/this_test.dart`
/// 2. Expected: All tests pass
/// 3. Delete-test: Comment out implementation, tests should FAIL
/// 
/// ## Last Verified
/// - Date: [Date]
/// - Commit: [Hash]

import 'package:flutter_test/flutter_test.dart';
import 'package:project/path/to/component.dart';

void main() {
  group('[Component Name]', () {
    group('constructor', () {
      test('creates instance with valid parameters', () {
        // ARRANGE
        const validParam = 'value';
        
        // ACT
        final instance = Component(param: validParam);
        
        // ASSERT - Specific value checks
        expect(instance.param, equals(validParam));
        expect(instance.derivedValue, equals(expectedDerived));
      });
      
      test('throws on invalid parameters', () {
        // ASSERT - Specific exception
        expect(
          () => Component(param: null),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
    
    group('methodName', () {
      /// PROVES: [What passing this test proves]
      /// FAILURE MODE: Would catch [broken behavior]
      test('returns expected output for given input', () {
        // ARRANGE
        final component = Component();
        const input = 42;
        const expectedOutput = 84;
        
        // ACT
        final result = component.methodName(input);
        
        // ASSERT - Exact value comparison
        expect(result, equals(expectedOutput));
      });
      
      test('handles edge case: zero input', () {
        final component = Component();
        expect(component.methodName(0), equals(0));
      });
      
      test('handles edge case: negative input', () {
        final component = Component();
        expect(component.methodName(-5), equals(-10));
      });
    });
  });
}
```

### B.2 Widget Test Template

```dart
// Copyright (c) [Year] [Project]. All rights reserved.
// Widget tests for [Feature Name]

/// # Test Suite: [Feature] Widget Tests
/// 
/// ## Purpose
/// Verify [Feature] renders correctly and responds to interaction.
/// 
/// ## Requirements Covered
/// - FR-XXX: [Requirement text]
/// - SC-XXX: [Success criterion]
/// 
/// ## Verification Instructions
/// 1. Run: `flutter test test/widget/path/this_test.dart`
/// 2. Expected: All tests pass
/// 3. Visual check: Run app and compare to screenshots
/// 
/// ## Last Verified
/// - Date: [Date]
/// - Commit: [Hash]

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/path/to/widget.dart';

void main() {
  group('[Feature Name] Widget', () {
    /// PROVES: Widget renders with expected visible elements
    /// FAILURE MODE: Would catch missing axis labels
    testWidgets('renders required visual elements', (tester) async {
      // ARRANGE
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureWidget(
              // Specific configuration for test
              config: TestConfig(
                label: 'TEST_LABEL',  // Unique, searchable
                value: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // ASSERT - Find specific elements, NOT just container
      expect(find.text('TEST_LABEL'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      
      // ASSERT - Verify layout
      final labelFinder = find.text('TEST_LABEL');
      final valueFinder = find.text('42');
      
      final labelBox = tester.getRect(labelFinder);
      final valueBox = tester.getRect(valueFinder);
      
      // Label should be above value
      expect(labelBox.bottom, lessThan(valueBox.top));
    });
    
    /// PROVES: Multiple elements render at correct positions
    /// FAILURE MODE: Would catch only one axis rendering
    testWidgets('renders multiple elements at distinct positions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: FeatureWidget(
                items: [
                  Item(id: 'left', position: Position.left),
                  Item(id: 'right', position: Position.right),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // CRITICAL: Find BOTH items
      expect(find.text('left'), findsOneWidget);
      expect(find.text('right'), findsOneWidget);
      
      // Verify positions
      final leftBox = tester.getRect(find.text('left'));
      final rightBox = tester.getRect(find.text('right'));
      
      // Left should be on left side of screen
      expect(leftBox.center.dx, lessThan(400));
      // Right should be on right side
      expect(rightBox.center.dx, greaterThan(400));
    });
    
    /// PROVES: Feature works end-to-end with real data flow
    /// FAILURE MODE: Would catch disconnected components
    testWidgets('INTEGRATION: data flows from config to visual output', (tester) async {
      // Use distinctive values that will be visible in output
      const testValue = 12345.67;
      const testLabel = 'INTEGRATION_TEST_AXIS';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureWidget(
              axes: [
                AxisConfig(
                  id: 'test',
                  label: testLabel,
                  value: testValue,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // If integration works, this label appears in rendered output
      expect(find.text(testLabel), findsOneWidget);
      
      // If normalization works, value appears formatted
      expect(find.textContaining('12345'), findsOneWidget);
    });
  });
}
```

### B.3 Golden Test Template

```dart
// Copyright (c) [Year] [Project]. All rights reserved.
// Golden tests for [Feature Name]

/// # Test Suite: [Feature] Golden Tests
/// 
/// ## Purpose
/// Visual regression testing - detect unintended visual changes.
/// 
/// ## Requirements Covered
/// - SC-XXX: Visual appearance criteria
/// 
/// ## Verification Instructions
/// 1. Generate goldens: `flutter test --update-goldens test/golden/path/`
/// 2. Review generated images manually
/// 3. Commit golden files
/// 4. Future runs compare against committed goldens
/// 
/// ## Golden File Management
/// - Goldens stored in: test/golden/path/goldens/
/// - Naming: feature_variant_WxH.png
/// - Review ALL golden changes before committing
/// 
/// ## Last Verified
/// - Date: [Date]
/// - Commit: [Hash]

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/path/to/widget.dart';

void main() {
  group('[Feature Name] Golden Tests', () {
    testWidgets('matches golden: two axis layout', (tester) async {
      // Fixed size for reproducible screenshots
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          // Disable animations for deterministic output
          home: MediaQuery(
            data: const MediaQueryData(),
            child: Scaffold(
              body: FeatureWidget(
                axes: [
                  AxisConfig(id: 'left', position: Position.left),
                  AxisConfig(id: 'right', position: Position.right),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(FeatureWidget),
        matchesGoldenFile('goldens/feature_two_axis_800x400.png'),
      );
    });
    
    testWidgets('matches golden: four axis layout', (tester) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeatureWidget(
              axes: [
                AxisConfig(id: 'leftOuter', position: Position.leftOuter),
                AxisConfig(id: 'left', position: Position.left),
                AxisConfig(id: 'right', position: Position.right),
                AxisConfig(id: 'rightOuter', position: Position.rightOuter),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(FeatureWidget),
        matchesGoldenFile('goldens/feature_four_axis_1200x600.png'),
      );
    });
  });
}
```

### B.4 Integration Test Template

```dart
// Copyright (c) [Year] [Project]. All rights reserved.
// Integration tests for [Feature Name]

/// # Test Suite: [Feature] Integration Tests
/// 
/// ## Purpose
/// Verify complete feature works end-to-end in real app context.
/// 
/// ## Requirements Covered
/// - FR-XXX: End-to-end requirement
/// - SC-XXX: User-observable success criterion
/// 
/// ## Verification Instructions
/// 1. Run: `flutter test integration_test/path/this_test.dart`
/// 2. Watch the test run (uses real device/emulator)
/// 3. Compare against expected behavior
/// 
/// ## Manual Verification
/// After automated test passes:
/// 1. Run app manually
/// 2. Navigate to feature
/// 3. Confirm visual output matches screenshots
/// 
/// ## Last Verified
/// - Date: [Date]
/// - Commit: [Hash]

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('[Feature Name] Integration', () {
    testWidgets('complete user flow works', (tester) async {
      // Start real app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to feature
      await tester.tap(find.text('Feature Name'));
      await tester.pumpAndSettle();
      
      // Verify feature is visible and working
      expect(find.text('Expected Title'), findsOneWidget);
      expect(find.byType(FeatureWidget), findsOneWidget);
      
      // Interact with feature
      await tester.tap(find.byKey(Key('action_button')));
      await tester.pumpAndSettle();
      
      // Verify result
      expect(find.text('Action Completed'), findsOneWidget);
      
      // Take screenshot for manual verification
      // (Screenshot will be in test artifacts)
    });
  });
}
```

---

## Appendix C: Verification Checklists

### C.1 Task Start Checklist

```markdown
# Task Start Verification: T###

Before writing ANY code, verify:

## Task Specification
- [ ] Task has clear type (NEW_FILE/MODIFY_EXISTING/INTEGRATION)
- [ ] Files to modify are explicitly listed with line numbers
- [ ] Acceptance criteria are observable/measurable
- [ ] Test requirements are specified
- [ ] Verification artifacts are listed

## Understanding Check
- [ ] I can explain what "done" looks like
- [ ] I know which EXISTING files will change
- [ ] I know what tests will prove it works
- [ ] I know what screenshot/visual proof is needed

## Red Flag Check
- [ ] Task does NOT use vague words (support, handle, enable)
- [ ] "Integration" tasks specify 2+ files to modify
- [ ] Test requirements include meaningful assertions

## Ready to Start
- [ ] All above checks pass
- [ ] If any fail, escalate for task clarification

Signed: _____________ Date: _____________
```

### C.2 Implementation Checklist

```markdown
# Implementation Verification: T###

During and after coding:

## Code Changes
- [ ] Changes are in files specified by task
- [ ] For MODIFY tasks: Changed existing code (not just added new)
- [ ] For INTEGRATION tasks: Modified 2+ files
- [ ] No "TODO: implement" left in code
- [ ] No dead code (unreachable functions/classes)

## Test Changes
- [ ] Tests exist at specified paths
- [ ] Tests have meaningful assertions
- [ ] DELETE TEST DONE: Commented out impl, tests failed
- [ ] Tests pass with implementation uncommented

## Reachability Check
For new code:
- [ ] New class/function is imported somewhere
- [ ] New class/function is CALLED somewhere
- [ ] Can trace call path from entry point to new code

## Quick Sanity Checks
```bash
# Verify changes
git diff --stat

# For integration, expect 2+ files:
git diff --stat | grep -c "|"  # Should be >= 2

# Check for dead code
grep -r "class NewClass" lib/  # Find definition
grep -r "NewClass(" lib/       # Find usage (should exist!)
```

Signed: _____________ Date: _____________
```

### C.3 Task Completion Checklist

```markdown
# Task Completion Verification: T###

Before marking task as complete:

## Artifacts Generated
- [ ] docs/verification/T###/README.md
- [ ] docs/verification/T###/git_diff.txt
- [ ] docs/verification/T###/test_output.txt
- [ ] docs/verification/T###/screenshot.png (if UI)
- [ ] docs/verification/T###/checklist.md

## Git Verification
```bash
# Run and save to git_diff.txt
git diff HEAD~1 > docs/verification/T###/git_diff.txt
```
- [ ] Diff saved
- [ ] Diff shows expected files
- [ ] For INTEGRATION: 2+ files in diff

## Test Verification
```bash
# Run and save to test_output.txt
flutter test path/to/test.dart > docs/verification/T###/test_output.txt 2>&1
```
- [ ] All tests pass
- [ ] Output saved
- [ ] No "skip" or "TODO" in tests

## Visual Verification (if applicable)
```bash
cd example && flutter run -d chrome
# Navigate to feature, take screenshot
```
- [ ] Screenshot taken
- [ ] Screenshot shows expected output
- [ ] Screenshot saved to verification folder

## Final Checks
- [ ] No banned assertion patterns in tests
- [ ] No "TODO" comments in production code
- [ ] All acceptance criteria met
- [ ] Requirement FR-XXX addressed
- [ ] Success criterion SC-XXX satisfied

## Sign-off
Implementer confirms all checks pass: _____________ Date: _____________
Ready for third-party verification: ✅
```

### C.4 Third-Party Verification Checklist

```markdown
# Third-Party Verification: T###

**Verifier**: _____________ 
**Date**: _____________
**Time Spent**: ___ minutes

## 1. Artifact Presence (Pass/Fail)
| Artifact | Present | Notes |
|----------|---------|-------|
| README.md | ⬜ | |
| git_diff.txt | ⬜ | |
| test_output.txt | ⬜ | |
| screenshot.png | ⬜ | |
| checklist.md | ⬜ | |

**STOP if any required artifact missing**: ❌ REJECTED - Missing: _________

## 2. Git Diff Analysis (3 min)
Open `git_diff.txt`:
- Files changed: _________________________________
- Task type: [ ] NEW_FILE [ ] MODIFY [ ] INTEGRATION
- For INTEGRATION, 2+ files modified? [ ] Yes [ ] No

**Red Flags**:
- [ ] Only new files for "integration" task
- [ ] Only test files changed
- [ ] Trivial changes only

## 3. Test Validation (5 min)
Run independently:
```bash
flutter test [path from task]
```
- Tests pass? [ ] Yes [ ] No
- Output matches test_output.txt? [ ] Yes [ ] No

Check assertions:
```bash
grep -n "expect(" [test_file]
```
- [ ] Assertions test specific values
- [ ] No `findsOneWidget` as only assertion
- [ ] No `isNotNull` without follow-up

## 4. Visual Verification (2 min)
Open `screenshot.png`:
- Shows expected feature? [ ] Yes [ ] No
- Matches task requirements? [ ] Yes [ ] No

## 5. Code Reachability (3 min)
For new code:
```bash
# Find new classes/functions
grep -n "class \|void \|Future " [new_file]

# Find callers
grep -r "[ClassName]" lib/ --include="*.dart"
```
- New code has callers? [ ] Yes [ ] No

## 6. Red Flag Summary
- [ ] No red flags found
- [ ] Red flags found: ________________________________

## Verdict

[ ] ✅ APPROVED - All checks pass
[ ] ❌ REJECTED - Reason: _________________________________
[ ] ⚠️ NEEDS WORK - Issues: _________________________________

**Verifier Signature**: _____________ **Date**: _____________
```

---

## Appendix D: .specify Integration

### D.1 Template Additions

Add to `.specify/templates/tasks.md`:

```markdown
<!-- TASK TEMPLATE - Use for all task generation -->

## T### [Story] [Action Verb] [Component] [Change Description]

### Functional Requirement Link
- FR-XXX: [Copy exact text from spec.md]

### Task Type Classification
<!-- Check exactly ONE -->
[ ] NEW_FILE - Creates new file(s) only
[ ] MODIFY_EXISTING - Changes existing file(s)  
[ ] INTEGRATION - Connects components (MUST modify 2+ existing files)
[ ] TEST_ONLY - Adds tests without implementation

### Files Affected

**Create:** <!-- For NEW_FILE tasks -->
- `lib/path/to/new_file.dart` - [Purpose description]

**Modify:** <!-- For MODIFY_EXISTING and INTEGRATION tasks -->
- `lib/path/to/existing.dart`
  - Function: `functionName()`
  - Lines: ~XXX-YYY  
  - Change: [Specific change description]

<!-- For INTEGRATION tasks, list at least 2 files to modify -->

### Code Context

**BEFORE** (current code at specified location):
```dart
// Paste actual current code
```

**AFTER** (required code):
```dart
// Show expected code after change
```

### Acceptance Criteria
<!-- Must be observable/measurable -->
1. [Observable criterion that can be verified]
2. [Another observable criterion]

### Test Requirements
- Unit: `test/unit/path/test.dart`
- Widget: `test/widget/path/test.dart`  
- Integration: `test/integration/path/test.dart` (if applicable)

### Verification Artifacts
<!-- All tasks must produce these -->
- [ ] `docs/verification/T###/git_diff.txt`
- [ ] `docs/verification/T###/test_output.txt`
- [ ] `docs/verification/T###/screenshot.png` (if UI change)
- [ ] `docs/verification/T###/checklist.md`

### Definition of Done
- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] Verification artifacts generated
- [ ] Third-party verification complete
```

### D.2 Commands Update

Add to `.specify/README.md`:

```markdown
## Verification Commands

### During Implementation
```bash
# Verify task type matches changes
speckit verify-task T###

# Check for red flags
speckit lint-task T###
```

### After Implementation
```bash
# Generate verification package
speckit package-verification T###

# Run third-party verification  
speckit verify --third-party T###
```

### Phase Completion
```bash
# Verify all tasks in phase
speckit verify-phase [phase-number]

# Generate phase report
speckit report-phase [phase-number]
```
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-11-28 | Post-mortem analysis | Initial creation after implementation theater incident |

---

## Acknowledgment

This framework exists because of a complete implementation failure where:
- 56 tasks were "completed" without working functionality
- Tests passed while testing nothing meaningful
- Code was created but never integrated
- Visual verification was skipped entirely

**Never again.**

---

*"The purpose of testing is not to prove the code works. It's to prove the code COULD fail if it was broken."*
