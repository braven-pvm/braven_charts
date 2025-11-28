# Automated Verification Workflow

**Purpose**: Define clear triggers and checkpoints for autonomous verification agents

---

## Verification Triggers

### When to Trigger Verification

| Trigger | Action | Verification Scope |
|---------|--------|-------------------|
| Task checkbox marked `[x]` | Immediate verification | Single task |
| Commit message contains `T###` | Verify referenced tasks | Tasks in commit |
| PR opened/updated | Verify all tasks in PR | All changed tasks |
| Integration test run complete | Verify screenshots | Screenshot manifest |
| Sprint milestone | Full sprint verification | All tasks in milestone |

---

## Verification Stages

### Stage 1: Pre-Commit Checks (Implementer)

**Trigger**: Before `git commit`

```powershell
# Run from repo root
.\.specify\verification\verification-check.ps1 -LastCommit
```

**Checks**:
- [ ] Task type marker present (`[NEW]`, `[MOD]`, `[INT]`, etc.)
- [ ] Files in commit match task description
- [ ] No `findsOneWidget`-only assertions
- [ ] Integration tasks modify 2+ files

**Pass**: Proceed to commit
**Fail**: Fix issues before committing

---

### Stage 2: Post-Commit Verification (Verifier Agent)

**Trigger**: New commit pushed OR task marked complete

**Input**: Task ID (e.g., `T015`)

**Workflow**:

```
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: Locate Task                                          │
├──────────────────────────────────────────────────────────────┤
│ 1. Find task in tasks.md by ID                               │
│ 2. Extract: Type marker, file paths, acceptance criteria     │
│ 3. If task not found → ERROR                                 │
└──────────────────────────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 2: Git Diff Analysis                                    │
├──────────────────────────────────────────────────────────────┤
│ Command: git diff HEAD~1 --name-only                         │
│                                                              │
│ Check by task type:                                          │
│ • [NEW]: New file(s) at specified path(s)                    │
│ • [MOD]: Specified file(s) show modifications                │
│ • [INT]: 2+ existing files modified                          │
│ • [TST]: Test file(s) created/modified                       │
│                                                              │
│ If mismatch → REJECT with reason                             │
└──────────────────────────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 3: Test Quality Check                                   │
├──────────────────────────────────────────────────────────────┤
│ Command: grep -n "expect(" <test_file>                       │
│                                                              │
│ REJECT if ALL assertions are:                                │
│ • findsOneWidget (alone)                                     │
│ • isNotNull (alone)                                          │
│ • isTrue/isFalse without specific condition                  │
│                                                              │
│ ACCEPT if at least one assertion checks:                     │
│ • Specific text/value                                        │
│ • Numeric comparison                                         │
│ • Golden file match                                          │
│ • State property value                                       │
└──────────────────────────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 4: Test Execution                                       │
├──────────────────────────────────────────────────────────────┤
│ Command: flutter test <test_file> --reporter=expanded        │
│                                                              │
│ • All tests must pass                                        │
│ • Save output to docs/verification/T###/test_output.txt      │
│                                                              │
│ If any fail → REJECT                                         │
└──────────────────────────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 5: Screenshot Verification (if UI task)                 │
├──────────────────────────────────────────────────────────────┤
│ 1. Check for screenshots matching: T###_*.png                │
│    Location: example/screenshots/                            │
│                                                              │
│ 2. Verify screenshot manifest in test file                   │
│    Look for: /// SCREENSHOT MANIFEST for Task T###           │
│                                                              │
│ 3. Compare actual screenshots to manifest                    │
│    All listed screenshots must exist                         │
│                                                              │
│ 4. Visual inspection (if human) or pixel check (if auto)     │
│    Does screenshot show feature working?                     │
│                                                              │
│ If missing/mismatch → REJECT                                 │
└──────────────────────────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 6: Create Verification Artifacts                        │
├──────────────────────────────────────────────────────────────┤
│ Create folder: docs/verification/T###/                       │
│                                                              │
│ Required files:                                              │
│ • verification.md - Verification report                      │
│ • git_diff.txt - Output of git diff for this task            │
│ • test_output.txt - Test run output                          │
│ • screenshots/ - Copy of verified screenshots (if UI)        │
│                                                              │
│ Commit artifacts with message:                               │
│ "docs: Add verification artifacts for T###"                  │
└──────────────────────────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 7: Update Task Status                                   │
├──────────────────────────────────────────────────────────────┤
│ In tasks.md, update task line:                               │
│                                                              │
│ APPROVED:                                                    │
│ - [x] T### ... ✅ Verified YYYY-MM-DD                        │
│                                                              │
│ REJECTED:                                                    │
│ - [ ] T### ... ❌ Rejected: <reason>                         │
└──────────────────────────────────────────────────────────────┘
```

---

## Verification Artifacts Structure

```
docs/verification/
├── README.md                     # Overview of all verified tasks
├── T015/                         # Per-task folder
│   ├── verification.md           # Verification report
│   ├── git_diff.txt              # Git diff output
│   ├── test_output.txt           # Test run output
│   └── screenshots/              # Verified screenshots
│       ├── T015_zoom_test_01_initial_state.png
│       └── T015_zoom_test_02_after_keyboard_zoom.png
└── T016/
    └── ...
```

---

## Verification Report Template

```markdown
# Verification Report: T###

## Task Information
- **Task ID**: T###
- **Description**: [From tasks.md]
- **Type**: [NEW/MOD/INT/TST/CFG/DOC]
- **Files**: [List of files involved]

## Verification Date
- **Date**: YYYY-MM-DD HH:MM
- **Verifier**: [Agent ID or Human Name]
- **Commit**: [SHA]

## Checks Performed

### 1. Git Diff Analysis
- **Expected files**: [list]
- **Actual files changed**: [list]
- **Result**: ✅ PASS / ❌ FAIL
- **Notes**: [any observations]

### 2. Test Quality
- **Test file**: [path]
- **Assertion count**: [N]
- **Meaningful assertions**: [N]
- **Result**: ✅ PASS / ❌ FAIL
- **Notes**: [any observations]

### 3. Test Execution
- **Command**: `flutter test [path]`
- **Tests run**: [N]
- **Tests passed**: [N]
- **Result**: ✅ PASS / ❌ FAIL
- **Output**: See test_output.txt

### 4. Screenshot Verification (if applicable)
- **Screenshots expected**: [N]
- **Screenshots found**: [N]
- **Visual check**: ✅ Feature visible / ❌ Not visible
- **Result**: ✅ PASS / ❌ FAIL

## Final Verdict

- [ ] ✅ **APPROVED** - Task meets all verification criteria
- [ ] ❌ **REJECTED** - Task fails verification (see notes)
- [ ] ⚠️ **NEEDS WORK** - Minor issues to address

## Rejection Reasons (if applicable)
1. [Specific reason]
2. [Specific reason]

## Recommendations
[Any suggestions for the implementer]
```

---

## Automated Commands Reference

### For Implementer

```powershell
# Pre-commit check
.\.specify\verification\verification-check.ps1

# Run integration test with screenshots
cd example
flutter drive --driver=test_driver/integration_test.dart `
  --target=integration_test/T###_test.dart `
  --dart-define=PROOF_PAUSES=false `
  -d web-server --browser-name=chrome

# Check screenshot output
ls example/screenshots/T###_*.png
```

### For Verifier

```powershell
# Get task info
Select-String -Path "specs/*/tasks.md" -Pattern "T###"

# Get git diff for task
git log --oneline --all --grep="T###" | Select-Object -First 1
git show <commit> --name-only

# Check test assertions
Select-String -Path "test/**/T###*.dart" -Pattern "expect\("

# Run tests
flutter test test/**/T###*.dart --reporter=expanded

# Check screenshots exist
Get-ChildItem -Path "example/screenshots" -Filter "T###_*.png"

# Create verification folder
New-Item -ItemType Directory -Path "docs/verification/T###" -Force
```

---

## Integration with CI/CD

### GitHub Actions Trigger

```yaml
name: Task Verification

on:
  push:
    paths:
      - 'specs/**/tasks.md'
  pull_request:
    types: [opened, synchronize]

jobs:
  verify-tasks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Extract changed tasks
        id: tasks
        run: |
          # Find task IDs in commit messages or changed files
          TASKS=$(git log --oneline -1 | grep -oE 'T[0-9]{3}' | sort -u)
          echo "tasks=$TASKS" >> $GITHUB_OUTPUT
      
      - name: Verify each task
        run: |
          for TASK in ${{ steps.tasks.outputs.tasks }}; do
            echo "Verifying $TASK..."
            # Run verification checks
          done
```

---

## Quick Trigger Reference

| Event | Verification Type | Scope |
|-------|------------------|-------|
| `git commit -m "T015: ..."` | Auto-trigger post-commit | T015 only |
| `- [x] T015 ...` in tasks.md | Trigger full verification | T015 only |
| PR opened | Verify all tasks in PR | All modified tasks |
| `flutter drive` completes | Screenshot manifest check | Test file tasks |
| Daily cron | Stale task check | Incomplete tasks |

---

## See Also

- [Verifier Quick Reference](./verifier-quick-reference.md) - 10-minute manual verification
- [Screenshot Verification](./screenshot-verification.md) - Screenshot naming and validation
- [Anti-Patterns Catalog](./anti-patterns-catalog.md) - What to reject
