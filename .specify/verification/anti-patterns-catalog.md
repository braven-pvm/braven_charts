# Anti-Patterns Catalog

## Origin

This catalog was created after a **catastrophic failure** where an entire feature sprint (56 tasks, all marked complete, all tests passing) resulted in **ZERO working functionality** because none of the new code was connected to the application.

Every anti-pattern in this catalog is something that **actually happened** during that sprint.

---

## CATEGORY 1: IMPLEMENTATION ANTI-PATTERNS

### AP-I01: Island Implementation

**Pattern**: Creating new code that exists in isolation, never called by anything.

**What Happened**:
```
Files created:
- multi_axis_normalizer.dart ← Beautiful math, never called
- y_axis_renderer.dart ← Complete renderer, never used
- chart_painter.dart ← Full painter implementation, orphaned

Files modified:
- (none)

Result: 3 files of production-quality code that do absolutely nothing.
```

**Detection**:
- Git diff shows only new files, no modifications to core files
- Grep for class name usage returns only the definition file
- Setting breakpoint in new code never triggers during execution

**Prevention**:
- Every new file MUST have a corresponding modification to call it
- Verify call chain exists from entry point to new code
- Run delete test: comment out new code, verify something breaks

---

### AP-I02: Fake Integration

**Pattern**: Task says "integrate X" but only creates X without modifying the integration target.

**What Happened**:
```
Task: "T022 - Create chart painter for multi-axis integration"
Expected: chart_render_box.dart modified to use new painter
Actual: chart_painter.dart created, chart_render_box.dart unchanged
Git log: "T022 create chart painter for multi-axis integration" 
Git diff: Only new file chart_painter.dart
```

**Detection**:
- Git commit message contains "integrate" but diff lacks target file
- Target file unchanged after "integration" task
- New code exists but is never imported/called

**Prevention**:
- Integration tasks MUST specify: "MODIFY file X to call new code Y"
- Require git diff to show both new files AND modified files
- Verify import statements actually exist in target file

---

### AP-I03: Widget-RenderObject Disconnect

**Pattern**: Widget accepts configuration parameters but never passes them to RenderObject.

**What Happened**:
```dart
// Widget level - looks complete:
class BravenChartPlus extends StatefulWidget {
  final List<YAxisConfig>? yAxes;  // ✅ Parameter exists
  
  List<YAxisConfig> get effectiveYAxes => ...;  // ✅ Getter exists
}

// State level - looks complete:
class _BravenChartPlusState extends State<BravenChartPlus> {
  @override
  Widget build(BuildContext context) {
    return RenderObjectWidget(...);  // ❌ Never calls setYAxes()!
  }
}

// RenderObject level - incomplete:
class ChartRenderBox extends RenderBox {
  // ❌ No _yAxes property!
  // ❌ No setYAxes() method!
  // Still uses: _yAxis (singular)
}
```

**Detection**:
- Grep for setter in RenderObject returns nothing
- Search for "set{Property}" calls in widget build method
- RenderObject still has old property (singular) not new (plural)

**Prevention**:
- Trace every widget parameter to RenderObject property
- Verify setter exists and is called in widget
- Check RenderObject.paint() actually uses new property

---

### AP-I04: Render Method Unchanged

**Pattern**: New rendering code created but paint() method still uses old rendering logic.

**What Happened**:
```dart
// New renderer created (complete, correct):
class MultiYAxisRenderer {
  void paint(Canvas canvas, Size size, List<YAxisConfig> axes) {
    for (final axis in axes) {
      // Correct implementation
    }
  }
}

// But ChartRenderBox.paint() unchanged:
@override
void paint(PaintingContext context, Offset offset) {
  // Line 3122 - STILL PAINTS SINGLE AXIS:
  AxisRenderer(_yAxis!, ...).paint(canvas, size, _plotArea);
  
  // MultiYAxisRenderer NEVER CALLED
}
```

**Detection**:
- Grep for new renderer class in paint() method returns nothing
- Reading paint() shows old single-item logic unchanged
- Visual testing shows only one element when multiple expected

**Prevention**:
- After creating new renderer, IMMEDIATELY modify paint()
- Search paint() for old logic that should be replaced
- Visual verify: does the rendered output match the new code's intent?

---

## CATEGORY 2: TEST ANTI-PATTERNS

### AP-T01: Widget Existence Test

**Pattern**: Test only checks that widget exists, doesn't verify behavior.

**What Happened**:
```dart
testWidgets('multi-axis works', (tester) async {
  await tester.pumpWidget(
    BravenChartPlus(
      series: [series1, series2],
      yAxes: [axis1, axis2],  // Multiple axes configured
    ),
  );
  
  expect(find.byType(BravenChartPlus), findsOneWidget);  // ONLY CHECK
  // Test passes even though multi-axis rendering is completely broken!
});
```

**What It Should Be**:
```dart
testWidgets('multi-axis renders all axes', (tester) async {
  await tester.pumpWidget(...);
  await tester.pumpAndSettle();
  
  // Verify axes are actually rendered (for Text widgets):
  expect(find.text('Temperature'), findsOneWidget);  // Axis 1 label
  expect(find.text('Pressure'), findsOneWidget);     // Axis 2 label
  
  // Verify positions are correct:
  final tempRect = tester.getRect(find.text('Temperature'));
  final pressRect = tester.getRect(find.text('Pressure'));
  expect(tempRect.left, lessThan(pressRect.left));  // Temp on left
  
  // Or use golden test for Canvas-rendered content:
  await expectLater(
    find.byType(BravenChartPlus),
    matchesGoldenFile('goldens/multi_axis_two_axes.png'),
  );
});
```

**Detection**:
- Search for `findsOneWidget` as the only assertion
- Test doesn't verify any specific text, values, or positions
- Test passes with feature completely broken

**Prevention**:
- Require at least 3 specific assertions per test
- Mandate golden tests for visual features
- Run delete test: comment out implementation, test should fail

---

### AP-T02: Test Without Assertion

**Pattern**: Test performs setup but doesn't actually verify anything.

**What Happened**:
```dart
testWidgets('normalizer applies correctly', (tester) async {
  final normalizer = MultiAxisNormalizer(ranges);
  final result = normalizer.normalize(values);
  // ... no expect statements!
});

// Also seen:
testWidgets('renders chart', (tester) async {
  await tester.pumpWidget(ChartWidget());
  await tester.pumpAndSettle();
  // Test ends here - no assertions!
});
```

**Detection**:
- Count expect() statements: if zero, test is useless
- Test appears in coverage but proves nothing
- Removing the test changes nothing about codebase safety

**Prevention**:
- Require minimum of 1 expect() per test (preferably 3+)
- Code review specifically for assertion presence
- Test framework extension to fail tests with no assertions

---

### AP-T03: Testing Support Code Instead of Integration

**Pattern**: Tests verify helper classes work but not that they're used.

**What Happened**:
```dart
// Test file tests the normalizer in isolation:
test('normalizer scales values correctly', () {
  final normalizer = MultiAxisNormalizer([range1, range2]);
  final result = normalizer.normalize(100, axisIndex: 0);
  expect(result, equals(0.5));  // ✅ Test passes
});

// But ChartRenderBox.paint() never calls the normalizer!
// The test proves the normalizer works,
// but not that the app uses it.
```

**Detection**:
- Unit tests pass for utility classes
- Integration tests missing or only check widget existence
- Feature visually broken despite passing tests

**Prevention**:
- For every unit test on support code, require integration test
- Integration test must verify support code is actually used
- End-to-end test must show visible result of support code

---

### AP-T04: Canvas-Blind Testing

**Pattern**: Using find.text() for Canvas-drawn content, which always fails silently.

**What Happened**:
```dart
testWidgets('axis labels render', (tester) async {
  await tester.pumpWidget(ChartWithLabels());
  
  // These will NEVER find Canvas-drawn text!
  expect(find.text('0'), findsOneWidget);     // ❌ Fails
  expect(find.text('100'), findsOneWidget);   // ❌ Fails
  
  // Test fails, developer removes assertions or skips test
  // Canvas rendering is never actually verified
});
```

**What It Should Be**:
```dart
testWidgets('axis labels render', (tester) async {
  await tester.pumpWidget(ChartWithLabels());
  
  // Golden test captures Canvas content:
  await expectLater(
    find.byType(ChartWithLabels),
    matchesGoldenFile('goldens/axis_labels.png'),
  );
});

// Or unit test the render object directly:
test('axis renderer draws labels', () {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  
  axisRenderer.paint(canvas, Size(100, 400), plotArea);
  
  // Verify drawing commands were issued
  // (requires mock canvas or inspection)
});
```

**Detection**:
- Chart widget test uses find.text() for axis/grid labels
- Tests skip or fail with "finder found nothing"
- Visual features untested despite test files existing

**Prevention**:
- Document which elements are Canvas-rendered vs Widget-rendered
- Mandate golden tests for Canvas-rendered content
- Create helper for testing Canvas drawing commands

---

## CATEGORY 3: TASK ANTI-PATTERNS

### AP-K01: Ambiguous Integration Task

**Pattern**: Task says "integrate" but doesn't specify exactly where.

**What Happened**:
```markdown
Task: T022 - Create chart painter for multi-axis integration
Acceptance: Painter class created with required methods

# Agent interpretation: Create new file ✅
# Correct interpretation: Modify chart_render_box.dart to use painter
```

**What It Should Be**:
```markdown
Task: T022 - Integrate multi-axis painter into chart render pipeline

Integration Target:
- FILE: lib/src_plus/rendering/chart_render_box.dart
- METHOD: paint(PaintingContext context, Offset offset)
- LINE: Replace line 3122 (single axis render) with multi-axis loop

Acceptance:
- [ ] chart_render_box.dart contains import for new painter
- [ ] paint() method calls new painter
- [ ] git diff includes chart_render_box.dart
- [ ] Multiple axes visually render (screenshot required)
```

**Detection**:
- Task says "integrate" without specifying target file
- Task acceptance doesn't require modification to existing files
- Task can be marked complete by creating new files only

**Prevention**:
- Require explicit "File to Modify" for all integration tasks
- Require explicit line number or method name
- Acceptance criteria must include "git diff shows changes to..."

---

### AP-K02: Create-Only Task Masquerading as Feature

**Pattern**: Task only requires creating files, not connecting them.

**What Happened**:
```markdown
Task: T019 - Implement per-axis Y normalization
Acceptance:
✅ Normalizer class created
✅ Unit tests pass
✅ Handles edge cases

# All criteria met! But normalizer is never called by anything.
```

**What It Should Be**:
```markdown
Task: T019 - Implement and integrate per-axis Y normalization

Creation:
- [ ] MultiAxisNormalizer class created
- [ ] Unit tests for normalizer pass

Integration:
- [ ] ChartRenderBox._generateElements() uses normalizer
- [ ] Values are normalized before rendering
- [ ] Chart with multi-axis config shows normalized data

Verification:
- [ ] Chart with axes [0-100] and [0-1000] shows both series visible
- [ ] Without normalization, one series would be flat line
```

**Detection**:
- Task acceptance only mentions "created" not "used"
- Task can complete without touching core files
- Feature doesn't work despite task completion

**Prevention**:
- Every "implement" task must include "integrate" step
- Acceptance must verify the implementation is USED
- Include visual/behavioral verification criteria

---

### AP-K03: Task Completion by Technicality

**Pattern**: Task marked complete because criteria technically met, even though intent not achieved.

**What Happened**:
```markdown
Task: Implement multi-axis support in chart widget

Criteria:
✅ Widget accepts yAxes parameter  ← Just added parameter
✅ Multiple axis configs supported  ← Just created types
✅ Tests pass                       ← Tests only check widget exists

# All boxes checked! But multi-axis doesn't actually work.
```

**Detection**:
- All criteria marked complete
- Feature doesn't work when actually used
- No visual/behavioral verification was performed

**Prevention**:
- Include "Feature works when used" as explicit criterion
- Require screenshot/video for visual features
- Require manual testing step with specific scenario

---

## DETECTION COMMANDS

Quick commands to detect anti-patterns:

```bash
# Find Island Implementations (new classes never used)
git diff --name-only HEAD~5 | xargs -I {} sh -c \
  'grep -l "class " {} | while read f; do
    class=$(grep -oP "class \K\w+" $f | head -1)
    if [ $(grep -r "$class" lib/ | wc -l) -eq 1 ]; then
      echo "ORPHAN: $class in $f"
    fi
  done'

# Find Widget Existence Tests
grep -rn "expect(find.byType.*findsOneWidget)" test/ | \
  while read line; do
    file=$(echo $line | cut -d: -f1)
    if [ $(grep -c "expect(" $file) -eq 1 ]; then
      echo "WEAK TEST: $file (only existence check)"
    fi
  done

# Find Tests Without Assertions
grep -rL "expect(" test/ --include="*_test.dart"

# Verify Integration (check if new code is imported anywhere)
for file in $(git diff --name-only HEAD~1 | grep "lib/"); do
  classname=$(grep -oP "class \K\w+" $file | head -1)
  if [ -n "$classname" ]; then
    imports=$(grep -r "import.*$file\|$classname" lib/ | wc -l)
    echo "$file ($classname): $imports usages"
  fi
done
```

---

## SUMMARY

| Anti-Pattern | Category | Key Detection | Prevention |
|--------------|----------|---------------|------------|
| AP-I01 Island Implementation | Impl | New files, no modifications | Trace call chain |
| AP-I02 Fake Integration | Impl | "Integrate" task, no target changes | Require target file in diff |
| AP-I03 Widget-RO Disconnect | Impl | Widget has param, RO doesn't | Trace param to render |
| AP-I04 Render Unchanged | Impl | New renderer, paint() untouched | Modify paint() immediately |
| AP-T01 Existence Test | Test | Only findsOneWidget | Require 3+ assertions |
| AP-T02 No Assertion | Test | Zero expect() statements | Minimum assertion count |
| AP-T03 Support-Only Tests | Test | Unit tests pass, feature broken | Require integration tests |
| AP-T04 Canvas-Blind | Test | find.text() for Canvas content | Use golden tests |
| AP-K01 Ambiguous Integration | Task | No target file specified | Require explicit target |
| AP-K02 Create-Only | Task | No "integrate" step | Require usage verification |
| AP-K03 Technicality Complete | Task | Boxes checked, feature broken | Require behavioral verification |
