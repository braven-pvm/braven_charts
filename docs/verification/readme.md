# Verification Artifacts Directory

This directory contains verification proof for each completed sprint task.

## ⚠️ CRITICAL: Origin of This Framework

This verification framework was created after the **011-multi-axis-normalization sprint failure** where 56 tasks were marked complete with passing tests, but **ZERO functionality actually worked** because none of the new code was connected to the application.

Every document in this framework exists to prevent that specific failure from recurring.

## Framework Documents

Located in `.specify/verification/`:

| Document | Purpose |
|----------|---------|
| `verification-framework.md` | Complete 600+ line guide covering artifact creation and verification |
| `verifier-quick-reference.md` | 10-minute protocol for third-party verifiers |
| `integration-checklist.md` | Specific checklist for integration tasks |
| `anti-patterns-catalog.md` | Catalog of every failure pattern with detection/prevention |
| `verification-check.ps1` | PowerShell script to auto-detect anti-patterns |
| `templates/task-template.md` | Required template for task specifications |
| `templates/test-template.dart` | Required template for unit tests |
| `templates/widget-test-template.dart` | Required template for widget tests |

## Structure

```
docs/verification/
├── README.md                    # This file
├── PHASE_SUMMARY.md            # Overall phase verification status
└── T###/                        # One folder per task
    ├── README.md               # Task summary
    ├── git_diff.txt            # Git diff output
    ├── test_output.txt         # Test run output
    ├── screenshot.png          # Visual proof (if UI)
    ├── checklist.md            # Completed checklist
    └── verification_report.md  # Third-party verification report
```

## Required Artifacts Per Task

| Task Type | git_diff | test_output | screenshot | checklist |
|-----------|----------|-------------|------------|-----------|
| NEW_FILE | ✅ | ✅ | ❌ | ✅ |
| MODIFY_EXISTING | ✅ | ✅ | If UI | ✅ |
| INTEGRATION | ✅ | ✅ | ✅ | ✅ |
| TEST_ONLY | ✅ | ✅ | ❌ | ✅ |

## Verification Workflow

1. **Implementer** generates artifacts after task completion
2. **Implementer** fills out checklist.md
3. **Verifier** reviews artifacts and fills verification_report.md
4. **Verifier** marks APPROVED/REJECTED/NEEDS WORK
5. Only APPROVED tasks count as complete

## Commands

Generate verification package:
```bash
# After completing task
mkdir -p docs/verification/T###
git diff HEAD~1 > docs/verification/T###/git_diff.txt
flutter test path/to/test.dart > docs/verification/T###/test_output.txt 2>&1
# Take screenshot if UI task
cp checklist_template.md docs/verification/T###/checklist.md
```

---

*See `.specify/VERIFICATION_FRAMEWORK.md` for complete guidelines.*
