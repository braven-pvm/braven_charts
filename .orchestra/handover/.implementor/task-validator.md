# Task Structure Validator

⚠️ **FOR IMPLEMENTOR EYES ONLY** ⚠️

This file contains validation rules for `current-task.md`. The orchestrator
should NOT read this file - it exists to catch orchestrator mistakes before
you waste time on a poorly-specified task.

---

## Pre-Work Validation Protocol

**BEFORE starting any implementation work**, validate that `current-task.md` 
meets minimum structural requirements. This catches orchestrator errors early.

---

## Required Sections Checklist

Verify `current-task.md` contains ALL of the following sections.
Each section must have EITHER real content OR an explicit `[N/A - Reason: ...]` marker.

### Structural Requirements

- [ ] **Section 1: Task Overview** - Must describe what the task accomplishes
- [ ] **Section 2: SpecKit Traceability** - Must list T0XX task references
- [ ] **Section 3: Deliverables** - Must list files to CREATE and/or MODIFY
- [ ] **Section 4: Technical Context** - Must list dependencies/imports
- [ ] **Section 5: TDD Requirements** - Must specify test file path OR `[N/A - Reason]`
- [ ] **Section 6: Code Scaffolds** - May be `[N/A]` if not needed
- [ ] **Section 7: Visual Verification** - REQUIRED if task mentions "render", "paint", "display", "visual", "UI", OR `[N/A - Reason]` if pure logic
- [ ] **Section 8: Quality Gates** - Must specify linting and test commands
- [ ] **Section 9: Completion Protocol** - Must describe how to signal completion

### Content Quality Checks

- [ ] **No [TODO] markers** - Search for `[TODO` - none should remain
- [ ] **No placeholder text** - No `<insert X here>` or similar
- [ ] **Test baseline specified** - Quality gates must state current test count
- [ ] **File paths are absolute or relative to repo root** - Not ambiguous

### Visual Task Detection

**Task Categories** (Section 7 must specify one):
- `INFRASTRUCTURE` - Creates classes/logic NOT wired into main widget yet
- `INTEGRATION` - Wires existing components into BravenChartPlus
- `VISUAL` - Modifies rendering output that can be seen

#### If Category is INFRASTRUCTURE:
Section 7 MUST contain:
- [ ] `[N/A - Reason: Infrastructure task...]` explaining why no visual verification
- [ ] Reference to which future integration task will verify visually

#### If Category is INTEGRATION or VISUAL:
Section 7 MUST contain:
- [ ] **Standalone demo file path** in `example/lib/demos/task_NNN_*.dart`
- [ ] **Demo code scaffold** showing minimal self-contained example
- [ ] Flutter Agent workflow commands (Start-Process, wait, screenshot, stop)
- [ ] Expected visual output description (specific elements to verify)

**RED FLAG**: If Section 7 asks you to modify `example/lib/main.dart` directly,
this is INCORRECT. Visual verification should use **standalone demo files** 
that can run independently. Flag this as a validation error.

#### Keyword Detection (helps identify miscategorization):
If ANY of these keywords appear in Task Overview or Deliverables:
- `render`, `paint`, `draw`, `canvas`
- `visual`, `display`, `UI`, `widget`
- `axis`, `chart`, `graph`, `plot`
- `layout`, `position`, `coordinate`

But the task is marked INFRASTRUCTURE with `[N/A]`, verify:
- [ ] The task truly creates INFRASTRUCTURE (classes not yet integrated)
- [ ] The task does NOT wire anything into BravenChartPlus
- [ ] A future integration task is mentioned for visual verification

---

## Validation Failed - What To Do

If ANY check above fails, **DO NOT proceed with implementation**.

Instead, write to `completion-signal.md`:

```markdown
# Validation Failed

**Status**: BLOCKED - Task handover incomplete

## Missing/Invalid Sections:
- [ ] Section N: [What's wrong]
- [ ] Section M: [What's wrong]

## Specific Issues:
1. [Detailed description of problem]
2. [Detailed description of problem]

## Required Fix:
The orchestrator must fix these issues before implementation can begin.

---

**Implementor Note**: I have validated current-task.md against the task 
structure requirements and found deficiencies. Please correct and re-issue.
```

Then say: **"Task validation failed - see completion-signal.md for required fixes"**

---

## Validation Passed - Proceed

If ALL checks pass, you may proceed with implementation.

Do NOT write anything to completion-signal.md until work is complete.

---

## Why This Exists

The orchestrator has their own process to create well-formed tasks, but mistakes
happen. This validator catches those mistakes BEFORE you spend hours implementing
the wrong thing or missing critical requirements.

Think of it as a compiler for task specifications - catch errors early!
