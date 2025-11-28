# Agent Instructions: Apply Verification Framework to Speckit

**Purpose**: Step-by-step instructions for an AI agent to apply the verification framework patches to speckit templates.

---

## Pre-Conditions

Before applying patches, verify:

```powershell
# Check if patches are already applied
Select-String -Path ".specify/templates/tasks-template.md" -Pattern "VERIFICATION FRAMEWORK PATCH"
Select-String -Path ".github/prompts/speckit.tasks.prompt.md" -Pattern "VERIFICATION FRAMEWORK PATCH"
```

- If matches found → Patches already applied, skip to verification
- If no matches → Proceed with patch application

---

## Step 1: Apply tasks-template.md Patches

### 1.1 Read the patch documentation

```
Read file: .specify/verification/patches/tasks-template-patch.md
```

### 1.2 Apply Patch Location 1 (Task Type Classification)

**Find this section** in `.specify/templates/tasks-template.md`:
```markdown
## Path Conventions
```

**Insert BEFORE** the `<!-- ` comment that follows Path Conventions:

```markdown
<!-- VERIFICATION FRAMEWORK PATCH START - Task Type Classification -->
## Task Type Classification (REQUIRED)

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

### 1.3 Apply Patch Location 2 (Verification Requirements)

**Find this section**:
```markdown
3. Stories complete and integrate independently

---

## Notes
```

**Insert BEFORE** `## Notes`:

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

---
```

---

## Step 2: Apply speckit.tasks.prompt.md Patches

### 2.1 Read the patch documentation

```
Read file: .specify/verification/patches/speckit-prompt-patch.md
```

### 2.2 Apply Patch Location 1 (Task Type Classification)

**Find this line**:
```markdown
**Format Components**:
```

**Insert BEFORE** that line:

```markdown
<!-- VERIFICATION FRAMEWORK PATCH START - Task Type Classification -->
**Task Type Classification (REQUIRED)**:

Every task MUST also include a type marker after Story label:

| Marker | When to Use | Verification Requirement |
|--------|-------------|-------------------------|
| `[NEW]` | Creating a new file | File exists, compiles, exports used |
| `[MOD]` | Modifying existing code | Git diff shows file changed |
| `[INT]` | Connecting components | Git diff shows 2+ files, usage proven |
| `[CFG]` | Configuration only | Config applied |
| `[TST]` | Test file | Tests fail when impl removed |
| `[DOC]` | Documentation | Docs updated |

**Extended Format**: `- [ ] [TaskID] [P?] [Story?] [TYPE] Description with file path`
<!-- VERIFICATION FRAMEWORK PATCH END -->

```

### 2.3 Apply Patch Location 2 (Type Examples)

**Find this line**:
```markdown
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)
```

**Insert AFTER** that line:

```markdown

<!-- VERIFICATION FRAMEWORK PATCH START - Type Examples -->
**Examples with Type Classification** (when verification framework is used):

- ✅ CORRECT: `- [ ] T012 [P] [US1] [NEW] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T015 [US1] [INT] Wire UserService into AuthController in src/controllers/auth.py`
- ✅ CORRECT: `- [ ] T018 [US1] [MOD] Add validation to existing User model in src/models/user.py`
- ❌ WRONG: `- [ ] T015 [US1] [INT] Create UserIntegration in src/integration/user.py` (INT but only creates new file)
<!-- VERIFICATION FRAMEWORK PATCH END -->
```

### 2.4 Apply Patch Location 3 (Report Addition)

**Find this line**:
```markdown
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)
```

**Insert AFTER** that line:

```markdown
<!-- VERIFICATION FRAMEWORK PATCH START - Report Addition -->
   - Type classification validation: Confirm ALL tasks have type markers ([NEW], [MOD], [INT], [CFG], [TST], [DOC])
   - Integration task audit: List all [INT] tasks and confirm they will modify 2+ files
<!-- VERIFICATION FRAMEWORK PATCH END -->
```

---

## Step 3: Verify Patches Applied

```powershell
# Should return 4 matches for tasks-template.md (2 START, 2 END)
(Select-String -Path ".specify/templates/tasks-template.md" -Pattern "VERIFICATION FRAMEWORK PATCH").Count

# Should return 6 matches for speckit prompt (3 START, 3 END)
(Select-String -Path ".github/prompts/speckit.tasks.prompt.md" -Pattern "VERIFICATION FRAMEWORK PATCH").Count
```

**Expected**:
- tasks-template.md: 4 matches
- speckit.tasks.prompt.md: 6 matches

---

## Step 4: Stage and Commit Patches

```powershell
git add ".specify/templates/tasks-template.md" ".github/prompts/speckit.tasks.prompt.md"
git commit -m "feat: Apply verification framework patches to speckit templates

- Add Task Type Classification ([NEW], [MOD], [INT], [CFG], [TST], [DOC])
- Add Verification Requirements section
- Add type examples and validation to task generation

Patches from: .specify/verification/patches/"
```

---

## Troubleshooting

### Patches don't apply cleanly

If the target files have been modified, manually locate the insertion points:

1. **tasks-template.md**:
   - Patch 1: After `## Path Conventions` section, before the big `<!-- IMPORTANT -->` comment
   - Patch 2: After the Implementation Strategy section, before `## Notes`

2. **speckit.tasks.prompt.md**:
   - Patch 1: In the "Checklist Format" section, before "Format Components"
   - Patch 2: After the WRONG examples in "Examples" section
   - Patch 3: In step 5 "Report", after "Format validation" line

### Verify functionality

After patching, run `/speckit-tasks` on a test feature and verify:
- Tasks have type markers
- Report includes type validation
- Integration tasks are flagged for 2+ file requirement
