# Verification Framework Index

> **WHY THIS EXISTS**: In the 011-multi-axis-normalization sprint, 56 tasks were completed with passing tests. But ZERO functionality worked—because none of the new code was connected to the application. This framework ensures that never happens again.

---

## 🚨 START HERE

If you're short on time, read these two documents:

1. **[anti-patterns-catalog.md](./anti-patterns-catalog.md)** - Every failure pattern that caused the sprint to fail
2. **[integration-checklist.md](./integration-checklist.md)** - Critical checklist for integration tasks

---

## Quick Reference

| I am a... | Start with... |
|-----------|---------------|
| **Task Creator** | [templates/task-template.md](./templates/task-template.md) |
| **Implementer** | [integration-checklist.md](./integration-checklist.md) |
| **Test Writer** | [templates/test-template.dart](./templates/test-template.dart) or [templates/widget-test-template.dart](./templates/widget-test-template.dart) |
| **Integration Test Writer** | [templates/integration-test-template.dart](./templates/integration-test-template.dart) + [screenshot-verification.md](./screenshot-verification.md) |
| **Verifier** | [verifier-quick-reference.md](./verifier-quick-reference.md) + [screenshot-verification.md](./screenshot-verification.md) |
| **Everyone** | [anti-patterns-catalog.md](./anti-patterns-catalog.md) |

---

## Complete Document List

### Core Framework

| Document | Lines | Purpose |
|----------|-------|---------|
| [verification-framework.md](./verification-framework.md) | 600+ | Complete guide: artifact creation + verification protocol |
| [screenshot-verification.md](./screenshot-verification.md) | 300+ | Screenshot naming, capture, and verification protocol |
| [anti-patterns-catalog.md](./anti-patterns-catalog.md) | 400+ | Catalog of every failure pattern with detection/prevention |
| [integration-checklist.md](./integration-checklist.md) | 200+ | Critical checklist for integration tasks |

### Quick References

| Document | Purpose |
|----------|---------|
| [verifier-quick-reference.md](./verifier-quick-reference.md) | 10-minute manual verification protocol |
| [automated-verification-workflow.md](./automated-verification-workflow.md) | Trigger-based autonomous verification |
| [verification-check.ps1](./verification-check.ps1) | Automated anti-pattern detection script |

### Templates

| Template | Use For |
|----------|---------|
| [templates/task-template.md](./templates/task-template.md) | Creating task specifications |
| [templates/test-template.dart](./templates/test-template.dart) | Writing unit tests |
| [templates/widget-test-template.dart](./templates/widget-test-template.dart) | Writing widget/UI tests |
| [templates/integration-test-template.dart](./templates/integration-test-template.dart) | Writing integration tests with screenshots |

### External References

| Document | Purpose |
|----------|---------|
| [integration-testing.md](../../integration-testing.md) | How to run Flutter integration tests with ChromeDriver |

### Artifact Storage

| Location | Purpose |
|----------|---------|
| [docs/verification/](../../docs/verification/) | Verification artifacts for completed tasks |

### Speckit Integration Patches

| Document | Purpose |
|----------|---------|
| [patches/readme.md](./patches/readme.md) | Overview of patches and reapplication workflow |
| [patches/tasks-template-patch.md](./patches/tasks-template-patch.md) | Patches for `.specify/templates/tasks-template.md` |
| [patches/speckit-prompt-patch.md](./patches/speckit-prompt-patch.md) | Patches for `.github/prompts/speckit.tasks.prompt.md` |

> **Note**: When speckit is updated, check if patches need to be reapplied. Search for `<!-- VERIFICATION FRAMEWORK PATCH` in target files.

---

## The Four Rules

These rules would have caught 100% of the failures in sprint 011:

### Rule 1: Integration = Modification

> **If your git diff only shows NEW files, you haven't integrated anything.**

Integration tasks MUST modify existing files to call new code. Creating new files is not integration.

### Rule 2: Tests Must Fail Without Implementation

> **If commenting out your implementation doesn't break the tests, the tests are worthless.**

Every test must verify specific behavior. `expect(find.byType(X), findsOneWidget)` by itself proves nothing.

### Rule 3: Visual Features Need Visual Verification

> **Canvas-drawn content cannot be found with find.text(). Use golden tests.**

For any feature that renders to Canvas, include golden tests or they're not tested at all.

### Rule 4: Trace the Call Chain

> **If you can't trace a path from app entry point to your new code, it's orphaned.**

Every new class/method must be reachable from the existing codebase. No gaps allowed.

---

## Verification Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      TASK CREATION                              │
├─────────────────────────────────────────────────────────────────┤
│ 1. Use task-template.md                                         │
│ 2. Specify Task Type: NEW_FILE | MODIFY_EXISTING | INTEGRATION  │
│ 3. For INTEGRATION: specify exact file+method to modify         │
│ 4. Include acceptance criteria with verification steps          │
└──────────────────────────────┬──────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      IMPLEMENTATION                             │
├─────────────────────────────────────────────────────────────────┤
│ 1. Complete integration-checklist.md                            │
│ 2. Identify entry point BEFORE writing code                     │
│ 3. Modify existing files to call new code                       │
│ 4. Run verification-check.ps1 after completion                  │
└──────────────────────────────┬──────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TEST CREATION                              │
├─────────────────────────────────────────────────────────────────┤
│ 1. Use test-template.dart or widget-test-template.dart          │
│ 2. Include 3+ meaningful assertions (not just findsOneWidget)   │
│ 3. Use golden tests for Canvas content                          │
│ 4. Perform delete test: comment out impl, verify test fails     │
└──────────────────────────────┬──────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      VERIFICATION                               │
├─────────────────────────────────────────────────────────────────┤
│ 1. Use verifier-quick-reference.md (10-minute protocol)         │
│ 2. Check Instant Rejection Criteria first                       │
│ 3. Verify: git diff shows entry point modified                  │
│ 4. Verify: feature visually works (not just tests pass)         │
│ 5. Verify: delete test passes                                   │
│ 6. Store artifacts in docs/verification/                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Running the Verification Script

```powershell
# From repository root
.\.specify\verification\verification-check.ps1

# Check only recent changes
.\.specify\verification\verification-check.ps1 -LastCommit

# Full analysis (slower)
.\.specify\verification\verification-check.ps1 -Full

# Verbose output
.\.specify\verification\verification-check.ps1 -Verbose
```

---

## Instant Rejection Criteria

These patterns are automatic task rejection:

| Pattern | Detection | Why It's Rejected |
|---------|-----------|-------------------|
| Integration task with only new files | git diff shows no modifications | New code isn't connected to anything |
| Test with only `findsOneWidget` | grep for expect pattern | Tests nothing meaningful |
| No visual verification for UI feature | Missing screenshots/goldens | Can't prove it works |
| Test passes with impl commented out | Delete test fails | Test doesn't verify implementation |

---

## Contact

This framework was created as part of the post-mortem for sprint 011-multi-axis-normalization.

For questions or updates, see the commit history of these documents.
