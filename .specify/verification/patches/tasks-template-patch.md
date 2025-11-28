# Patch: tasks-template.md

## Target File
`.specify/templates/tasks-template.md`

## Patch Date
2025-01-XX (Update when applied)

**PATCH STATUS: ✅ APPLIED**
- Task Type Classification: Lines 25-45
- Verification Requirements: Lines 262-301

## Patch Purpose
Adds Task Type Classification and Verification Artifacts requirements to the task template to prevent "implementation theater" where tasks are marked complete but code is never integrated.

---

## Patch Location 1: After Task Format Section

### WHERE TO INSERT
After the "Task Format" section (around line 30-35), before the "## Phases" section.

### ORIGINAL CONTENT (what comes before)
```markdown
**Task Format**:
- [ ] [ID] [P?] [Story?] Task description with file path
  - ID: Sequential number (T001, T002, ...)
  - [P]: Optional parallel execution marker
  - [Story]: User story reference (e.g., [US1], [US2])
```

### PATCH CONTENT TO INSERT
```markdown
<!-- VERIFICATION FRAMEWORK PATCH START - Task Type Classification -->
### Task Type Classification (REQUIRED)

Each task MUST be classified by type. This determines verification requirements:

| Type | Marker | Description | Verification Requirement |
|------|--------|-------------|-------------------------|
| NEW_FILE | `[NEW]` | Creates a new file that didn't exist | File exists, compiles, exports used |
| MODIFY_EXISTING | `[MOD]` | Changes existing code | Git diff shows changes to existing file |
| INTEGRATION | `[INT]` | Connects components together | Git diff shows 2+ files changed, usage proven |
| CONFIG | `[CFG]` | Configuration/setup only | Config file updated, settings applied |
| TEST | `[TST]` | Test file creation/modification | Tests run and fail appropriately |
| DOCS | `[DOC]` | Documentation only | Docs updated, links work |

**Examples with Type Classification**:
- ✅ `- [ ] T012 [P] [US1] [NEW] Create NormalizationConfig in lib/src/config.dart`
- ✅ `- [ ] T015 [US1] [INT] Wire NormalizationConfig into BravenChartPlus widget`
- ✅ `- [ ] T018 [US1] [MOD] Add normalization parameters to ChartThemeData`

**CRITICAL**: `[INT]` (Integration) tasks MUST show changes to 2+ existing files in git diff. If only one new file is created, it's `[NEW]`, not `[INT]`.
<!-- VERIFICATION FRAMEWORK PATCH END -->
```

---

## Patch Location 2: After Dependencies Section

### WHERE TO INSERT
After the "## Dependencies" section (around line 150-160), before any closing sections.

### ORIGINAL CONTENT (what comes before)
```markdown
## Dependencies

Task dependencies ensure correct execution order:

- T001 ← T002: T002 depends on T001
- T005 ← T010 + T011: T005 depends on both T010 and T011
```

### PATCH CONTENT TO INSERT
```markdown
<!-- VERIFICATION FRAMEWORK PATCH START - Verification Requirements -->
## Verification Requirements

⚠️ **CRITICAL**: Tasks are NOT complete until verification passes. "Tests pass" is insufficient.

### Verification Artifacts Required

Each task type requires specific verification artifacts:

| Task Type | Required Verification |
|-----------|----------------------|
| `[NEW]` | • File exists at specified path<br>• File compiles without errors<br>• Export is used somewhere (or explicitly noted as future use) |
| `[MOD]` | • Git diff shows changes to the specified file<br>• Existing tests still pass<br>• New behavior is testable |
| `[INT]` | • **Git diff shows 2+ files changed**<br>• Calling code uses the new integration<br>• End-to-end behavior works (not just unit test) |
| `[TST]` | • Test file runs<br>• **Tests FAIL when implementation is removed** (delete-test rule) |

### Integration Task Checklist

For ANY task marked `[INT]`:

- [ ] Does git diff show changes to 2+ existing files?
- [ ] Is the new code CALLED from existing code?
- [ ] Can you trace execution from entry point to new code?
- [ ] Does removing the new code break existing functionality?

If ANY answer is NO, the task is NOT complete.

### Anti-Patterns to Avoid

❌ **The Phantom Integration**: Task says "integrate X" but only creates new file without modifying existing code
❌ **The Optimistic Export**: Creates `export 'file.dart'` but nothing imports or uses it  
❌ **The Widget Exists Test**: Test only checks `findsOneWidget` - proves nothing about integration
❌ **The Premature Checkoff**: Marking task complete before visual/runtime verification

### Verification Framework Reference

See full verification guidelines: `.specify/verification/verification-framework.md`
Quick reference: `.specify/verification/verifier-quick-reference.md`
Anti-patterns catalog: `.specify/verification/anti-patterns-catalog.md`
<!-- VERIFICATION FRAMEWORK PATCH END -->
```

---

## Full Diff Preview

When applied, the tasks-template.md will have two clearly marked sections added:

1. **Task Type Classification** section after Task Format (adds ~25 lines)
2. **Verification Requirements** section after Dependencies (adds ~45 lines)

## Verification That Patch Is Applied

Search for this marker in the file:
```
<!-- VERIFICATION FRAMEWORK PATCH START
```

If found: Patch is applied ✅
If not found: Patch needs to be reapplied ❌

## Reapplication Instructions

1. Open `.specify/templates/tasks-template.md`
2. Find the "Task Format" section
3. Insert Patch Location 1 content after it
4. Find the "Dependencies" section  
5. Insert Patch Location 2 content after it
6. Save file
7. Verify with search for patch marker

## Rollback Instructions

To remove the patch (if needed):
1. Search for `<!-- VERIFICATION FRAMEWORK PATCH START`
2. Delete from that line to the corresponding `<!-- VERIFICATION FRAMEWORK PATCH END -->`
3. Repeat for both patch locations
