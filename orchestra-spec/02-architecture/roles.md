# Role Definitions

> **Navigation**: [Index](../readme.md) | **Prev**: [Architecture Overview](overview.md) | **Next**: [Workflows](workflows.md)

---

## Overview

Orchestra defines two primary agent roles with distinct responsibilities, access rights, and failure modes.

## Role Summary

| Aspect | Orchestrator | Implementor |
|--------|--------------|-------------|
| Primary function | Plan, verify, coordinate | Execute, build, test |
| Task visibility | Full manifest (all tasks) | Single task only |
| Verification criteria | Creates and reads | Cannot access |
| Token cost | Higher (reasoning) | Lower (execution) |
| Model tier | High recommended | Medium acceptable |
| Trust level | Higher | Lower (verified externally) |

## Orchestrator Role

### Responsibilities

1. **Sprint Planning**
   - Translate specification artifacts into task manifest
   - Define verification criteria for each task
   - Establish task dependencies and phase boundaries
   - Consolidate granular spec tasks into orchestrator tasks

2. **Task Handover**
   - Prepare complete handover documents from templates
   - Fill all sections (content or N/A with reason)
   - Include sufficient context for autonomous execution
   - Run pre-handover validation scripts

3. **Verification**
   - Execute all verification checks against hidden criteria
   - View screenshots via Chrome DevTools MCP
   - Compare results against acceptance criteria
   - Document findings with evidence

4. **Progress Management**
   - Track task status in progress.yaml
   - Update SpecKit traceability (if applicable)
   - Archive completed tasks to results folder
   - Prepare next task handover

### Access Rights

| Resource | Access Level |
|----------|--------------|
| `manifest.yaml` | Read/Write |
| `progress.yaml` | Read/Write |
| `.orchestrator-only/` | Read/Write |
| `handover/` | Read/Write |
| `.implementor-only/` | Should not read |
| `common/` | Read |
| `docs/` | Read/Write |

### Prohibited Actions

- Reading implementor's validation rules (`.implementor-only/task-validator.md`)
- Signaling task completion on implementor's behalf
- Modifying codebase directly (orchestrator plans, doesn't implement)
- Downgrading severity during verification

### Failure Modes

| Failure | Detection | Prevention |
|---------|-----------|------------|
| Running verification from memory | Human audit | Read YAML before each check |
| Skipping visual verification | Missing screenshot view in log | Checklist enforcement |
| Incomplete handover | Implementor validation script | Template with mandatory sections |
| Severity downgrade | Human review of results | Immutable severity in YAML |

### Quality Standards

The orchestrator must:

1. **Read, don't remember** - Always read source files, never work from memory
2. **Template-first** - Use templates, never create documents from scratch
3. **Evidence-based** - Every check must have documented evidence
4. **No rationalization** - Failed is failed; don't explain why it's "okay"

## Implementor Role

### Responsibilities

1. **Handover Validation**
   - Read and understand task handover documents
   - Run validation script to confirm completeness
   - Flag defects in handover (stops work, reports to orchestrator)

2. **Implementation**
   - Execute implementation per task specification
   - Follow existing codebase patterns and conventions
   - Use existing utilities (don't duplicate logic)
   - Create tests as specified (TDD when required)

3. **Artifact Creation**
   - Run tests and capture output to file
   - Create screenshots for visual tasks
   - Write completion signal document
   - Run pre-signal check (creates proof artifact)

4. **Quality Assurance**
   - Zero static analysis issues in affected files
   - All sprint tests passing
   - Fix pre-existing issues in touched files

### Access Rights

| Resource | Access Level |
|----------|--------------|
| `handover/` | Read/Write |
| `.implementor-only/` | Read/Write |
| `implementor/artifacts/` | Read/Write |
| `common/` | Read |
| `docs/` (except research_log) | Read |
| `manifest.yaml` | Cannot access |
| `progress.yaml` | Cannot access |
| `.orchestrator-only/` | Cannot access |

### Prohibited Actions

- Reading manifest (full task list)
- Reading verification criteria
- Reading orchestrator's pre-flight checklists
- Signaling completion without pre-signal artifact
- Modifying files outside task scope

### Failure Modes

| Failure | Detection | Prevention |
|---------|-----------|------------|
| Skip pre-signal check | No artifact exists | Structural gate (orchestrator checks artifact) |
| Duplicate logic | Verification check fails | "MUST USE" section in handover |
| Shallow tests | Test count below minimum | Minimum test count in criteria |
| Fake integration | Git diff shows no existing file changes | Adversarial check |

### Quality Standards

The implementor must:

1. **Follow instructions exactly** - Don't innovate beyond spec
2. **Run all scripts** - Validation and pre-signal checks are mandatory
3. **Create artifacts** - Every claim must have proof
4. **Fix what you touch** - Pre-existing issues in modified files must be fixed

## Mutual Verification

Neither role trusts the other's claims without evidence.

```
┌─────────────────────────────────────────────────────────────┐
│                    MUTUAL VERIFICATION                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Orchestrator                         Implementor           │
│       │                                    │                 │
│       │ Verifies implementor via:          │ Verifies        │
│       │ - Hidden verification criteria     │ orchestrator:   │
│       │ - Pre-signal artifact check        │ - Handover      │
│       │ - Screenshot content view          │   validation    │
│       │ - Test output analysis             │   script        │
│       │                                    │                 │
│       ▼                                    ▼                 │
│   Creates: verification-results.md    Creates: pre-signal   │
│                                        artifact             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### What Orchestrator Verifies About Implementor

- Did implementor run pre-signal check? (artifact exists)
- Did implementation meet structural criteria? (files exist, exports added)
- Did implementation meet functional criteria? (tests pass)
- Did implementation meet visual criteria? (screenshot shows correct output)

### What Implementor Verifies About Orchestrator

- Is handover document complete? (validation script)
- Are all sections filled or marked N/A? (no TODOs)
- Is task category specified? (INFRASTRUCTURE/INTEGRATION/VISUAL)
- Are file paths unambiguous?
- Is TDD section complete for tasks requiring it?

## Human Overseer Role

The human serves as ultimate arbiter and process improver.

### Responsibilities

1. **Audit** - Review verification results, spot-check archives
2. **Intervene** - Handle edge cases, resolve disputes
3. **Improve** - Update templates, scripts, documentation based on findings
4. **Gate** - Approve major phase transitions or final merges

### When Human Intervenes

- Orchestrator or implementor is stuck
- Verification is ambiguous
- New failure mode discovered
- Process improvement needed
- Visual verification catches issue requiring interpretation

### Access Rights

Full access to all Orchestra artifacts and documentation.
