# Task Template

Copy this template when creating new tasks. Delete this instruction after copying.

---

## T### [Story] [Action Verb] [Component] [Change Description]

### Functional Requirement Link

- FR-XXX: [Copy exact requirement text from spec.md]
- SC-XXX: [Copy success criterion if applicable]

### Task Type Classification

<!-- Check EXACTLY ONE. Task type determines verification requirements. -->

- [ ] **NEW_FILE** - Creates new file(s) only. Does NOT connect to existing system.
- [ ] **MODIFY_EXISTING** - Changes existing file(s). Must specify exact location.
- [ ] **INTEGRATION** - Connects components. MUST modify 2+ existing files.
- [ ] **TEST_ONLY** - Adds tests without implementation changes.

### Files Affected

<!-- For NEW_FILE tasks: -->

**Create:**

- `lib/path/to/new_file.dart` - [One-line purpose description]

<!-- For MODIFY_EXISTING tasks: -->

**Modify:**

- `lib/path/to/existing_file.dart`
  - **Function**: `functionName()`
  - **Lines**: ~XXX-YYY (approximate)
  - **Change**: [One-line description of modification]

<!-- For INTEGRATION tasks: List at least 2 files -->

**Modify:**

1. `lib/path/to/source.dart`

   - **Function**: `sourceMethod()`
   - **Lines**: ~XXX-YYY
   - **Change**: [Export/expose functionality]

2. `lib/path/to/consumer.dart`
   - **Function**: `consumerMethod()`
   - **Lines**: ~XXX-YYY
   - **Change**: [Import and call source]

### Code Context

<!-- Show actual current code and required changes -->

**BEFORE** (current code at line ~XXX):

```dart
// Paste actual current code from file
// Include 3-5 lines of context
void existingMethod() {
  // current implementation
}
```

**AFTER** (required code):

```dart
// Show the exact code that should exist after task
// Include 3-5 lines of context
void existingMethod() {
  // modified implementation
  newFunctionality(); // ADDED
}
```

### Data Flow (for INTEGRATION tasks)

```
[Source Component]
    ↓ via [method/property name]
[Consumer Component]
    ↓ via [render/display method]
[Observable Output]
```

### Acceptance Criteria

<!-- Must be OBSERVABLE and MEASURABLE. Third party must be able to verify. -->

1. [ ] [Observable criterion - can be visually or programmatically verified]
2. [ ] [Another observable criterion]
3. [ ] [Avoid vague criteria like "works correctly"]

### Test Requirements

<!-- Specify exact test file paths and what they must test -->

- **Unit Test**: `test/unit/path/component_test.dart`

  - Tests: [Specific functionality to test]
  - Assertions: [Type of assertions required]

- **Widget Test**: `test/widget/path/feature_test.dart`

  - Tests: [Specific rendering/interaction to test]
  - Assertions: [Must find specific elements, NOT just container]

- **Integration Test**: `test/integration/path/feature_test.dart` (if applicable)
  - Tests: [End-to-end flow]
  - Assertions: [Data flows from input to output]

### Test Specification

<!-- Describe what tests MUST verify -->

```dart
/// Example test structure - tests MUST include assertions like:
test('specific behavior description', () {
  // ARRANGE - specific setup
  // ACT - specific action
  // ASSERT - specific value checks, NOT just "exists"
  expect(result.specificValue, equals(expectedValue));
  expect(find.text('Specific Text'), findsOneWidget);
});
```

**BANNED assertion patterns:**

- ❌ `expect(find.byType(Widget), findsOneWidget)` alone
- ❌ `expect(result, isNotNull)` alone
- ❌ `expect(success, isTrue)` without checking result

### Verification Artifacts

<!-- All completed tasks MUST produce these -->

- [ ] `docs/verification/T###/README.md` - Summary of what was done
- [ ] `docs/verification/T###/git_diff.txt` - Output of `git diff HEAD~1`
- [ ] `docs/verification/T###/test_output.txt` - Output of `flutter test`
- [ ] `docs/verification/T###/screenshot.png` - Visual proof (if UI change)
- [ ] `docs/verification/T###/checklist.md` - Completed verification checklist

### Definition of Done

<!-- All must be checked before task is marked complete -->

- [ ] Implementation matches AFTER code block
- [ ] Git diff shows expected files modified
- [ ] For INTEGRATION: Git diff shows 2+ files
- [ ] All tests pass
- [ ] Tests would FAIL if implementation removed (delete-test verified)
- [ ] No "TODO" comments in production code
- [ ] Visual verification screenshot attached (if UI)
- [ ] All verification artifacts generated
- [ ] Ready for third-party verification

### Anti-Pattern Check

<!-- Verify NONE of these apply -->

- [ ] NOT creating "integration point" without actual integration
- [ ] NOT creating new file that just imports existing (wrong direction)
- [ ] NOT writing tests that only check widget exists
- [ ] NOT leaving new code unreachable (no callers)

---

<!--
VERIFIER NOTES:
- Reject if any Definition of Done unchecked
- Reject if Anti-Pattern Check has any checked items
- Reject if INTEGRATION type but only 1 file in git diff
- Reject if tests use banned assertion patterns
-->
