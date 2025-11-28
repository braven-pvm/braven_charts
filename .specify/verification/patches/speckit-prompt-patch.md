# Patch: speckit.tasks.prompt.md

## Target File
`.github/prompts/speckit.tasks.prompt.md`

## Patch Date
2025-01-XX (Update when applied)

**PATCH STATUS: ✅ APPLIED**
- Report Addition: Lines 53-56
- Task Type Classification: Lines 76-91
- Type Examples: Lines 117-124

## Patch Purpose
Adds verification enforcement to the task generation rules, ensuring generated tasks include type classification and verification requirements.

---

## Patch Location 1: After Checklist Format Section

### WHERE TO INSERT
After the "Checklist Format (REQUIRED)" section, before or within the "Format Components" subsection. Look for the "**Format Components**:" heading around line 35-40.

### ORIGINAL CONTENT (what comes before)
```markdown
### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
```

### PATCH CONTENT TO INSERT
Insert BEFORE the "**Format Components**:" line:

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

---

## Patch Location 2: After Examples Section

### WHERE TO INSERT
Add to the Examples section, after the existing correct/wrong examples. Look for around line 50-60.

### ORIGINAL CONTENT (what comes before)
```markdown
**Examples**:

- ✅ CORRECT: `- [ ] T001 Create project structure per implementation plan`
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Story label)
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)
```

### PATCH CONTENT TO INSERT
Insert AFTER the existing examples:

```markdown
<!-- VERIFICATION FRAMEWORK PATCH START - Type Examples -->
**Examples with Type Classification** (when verification framework is used):

- ✅ CORRECT: `- [ ] T012 [P] [US1] [NEW] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T015 [US1] [INT] Wire UserService into AuthController in src/controllers/auth.py`
- ✅ CORRECT: `- [ ] T018 [US1] [MOD] Add validation to existing User model in src/models/user.py`
- ❌ WRONG: `- [ ] T015 [US1] [INT] Create UserIntegration in src/integration/user.py` (INT but only creates new file)
<!-- VERIFICATION FRAMEWORK PATCH END -->
```

---

## Patch Location 3: Report Section Addition

### WHERE TO INSERT
In the "Report" section (step 5 of the Outline), add verification format check. Around line 25-30.

### ORIGINAL CONTENT
```markdown
5. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)
```

### PATCH CONTENT TO INSERT
Add after "Format validation" line:

```markdown
<!-- VERIFICATION FRAMEWORK PATCH START - Report Addition -->
   - Type classification validation: Confirm ALL tasks have type markers ([NEW], [MOD], [INT], [CFG], [TST], [DOC])
   - Integration task audit: List all [INT] tasks and confirm they will modify 2+ files
<!-- VERIFICATION FRAMEWORK PATCH END -->
```

---

## Full Diff Summary

When applied, the speckit.tasks.prompt.md will have three clearly marked additions:

1. **Task Type Classification** in format section (adds ~15 lines)
2. **Type Examples** after existing examples (adds ~6 lines)
3. **Report Additions** for type validation (adds ~3 lines)

## Verification That Patch Is Applied

Search for this marker in the file:
```
<!-- VERIFICATION FRAMEWORK PATCH START
```

If found: Patch is applied ✅
If not found: Patch needs to be reapplied ❌

## Reapplication Instructions

1. Open `.github/prompts/speckit.tasks.prompt.md`
2. Find "Checklist Format (REQUIRED)" section
3. Insert Patch Location 1 content before "**Format Components**:"
4. Find "**Examples**:" section
5. Insert Patch Location 2 content after existing examples
6. Find "**Report**:" section (step 5)
7. Insert Patch Location 3 content after "Format validation" line
8. Save file
9. Verify with search for patch marker

## Rollback Instructions

To remove the patch (if needed):
1. Search for `<!-- VERIFICATION FRAMEWORK PATCH START`
2. Delete from that line to the corresponding `<!-- VERIFICATION FRAMEWORK PATCH END -->`
3. Repeat for all three patch locations
