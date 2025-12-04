# Orchestra Implementor Guide

## Your Role

You are an **Implementor Agent**.

Your job is to complete the task described in `current-task.md` following the requirements exactly.

---

## 📂 File Locations

### Files You Should Read

| File | Location | Purpose |
|------|----------|----------|
| **Your Task** | `.orchestra/current-task.md` | Complete task requirements, acceptance criteria |
| **This Guide** | `.orchestra/AGENT_README.md` | Workflow reference (this file - immutable) |

### Files You Should NOT Touch

| Location | Purpose | Who Manages |
|----------|---------|-------------|
| `.orchestra/.orchestrator-only/*` | Orchestrator workspace | Orchestrator only |
| `.orchestra/AGENT_README.md` | This guide | Immutable (do not edit) |
| `.orchestra/orchestra.yaml` | Project configuration | Orchestrator only |

---

## 🔄 Workflow

### Step 1: Read Your Task

Open and read: **`.orchestra/current-task.md`**

This file contains:
- Task objectives
- Acceptance criteria
- File operations required
- Verification steps
- SpecKit task references

### Step 2: Implement Requirements

- Follow ALL acceptance criteria exactly
- If TDD is required, write tests FIRST
- Use quality patterns from previous phases
- Stay focused on THIS task only

### Step 3: Verify Your Work

Run all verification steps listed in `current-task.md`.

### Step 4: Signal Completion

When implementation is complete and all tests pass:

1. **Copy the completion signal template**:
   ```powershell
   Copy-Item ".orchestra/common/templates/completion-signal.md.hbs" ".orchestra/completion-signal.yaml"
   ```

2. **Fill out the completion signal** with:
   - Task summary
   - Files created/modified
   - Test results
   - Any notes or concerns

3. **Save the file** as `.orchestra/completion-signal.yaml`

4. **Notify**: Say **"ready for review"** and STOP

---

## 🚫 Important Rules

1. **ONE task only** - Do not look at manifest or other tasks
2. **Follow the spec** - SpecKit references are in `current-task.md`
3. **No orchestrator files** - Stay out of `.orchestrator-only/`
4. **Signal when done** - Complete the signal file and notify
5. **Do not modify this file** - AGENT_README.md is immutable

**Ready to implement? Start with `.orchestra/current-task.md`** 🚀
