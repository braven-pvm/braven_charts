# Architecture Overview

> **Navigation**: [Index](../readme.md) | **Prev**: [Success Criteria](../01-product/success-criteria.md) | **Next**: [Roles](roles.md)

---

## System Context

Orchestra operates as a coordination layer for AI-assisted software development. It sits between:

- **Upstream**: Specification artifacts (e.g., SpecKit output, user stories, requirements)
- **Downstream**: Codebase being modified (source code, tests, configuration)
- **Actors**: Orchestrator agent, implementor agent, human overseer

```
┌─────────────────────────────────────────────────────────────────┐
│                     Specification Layer                          │
│  (SpecKit artifacts, user stories, requirements documents)       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Orchestra                                │
│  ┌───────────────────┐         ┌───────────────────┐            │
│  │   Orchestrator    │◄───────►│   Implementor     │            │
│  │   (plans, verifies)│        │   (executes)      │            │
│  └───────────────────┘         └───────────────────┘            │
│              │                          │                        │
│              ▼                          ▼                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              .orchestra/ folder structure                   │ │
│  │  (manifest, handover, templates, scripts, verification)    │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Codebase Layer                            │
│  (source files, test files, configuration, build artifacts)     │
└─────────────────────────────────────────────────────────────────┘
```

## Core Principles

### P1: Structural Separation Over Advisory Rules

Instructions that agents "should" follow will eventually be skipped. Enforcement must be structural:

| Advisory (Weak) | Structural (Strong) |
|-----------------|---------------------|
| "Run tests before signaling" | Script creates artifact; gate checks for artifact |
| "Don't read verification criteria" | Criteria in `.orchestrator-only/` folder |
| "Include all sections" | Template requires N/A with reason for empty sections |

### P2: Hidden Verification Criteria

Implementor cannot see the criteria they will be verified against. This prevents:
- Gaming metrics (Goodhart's Law)
- Optimizing for checks rather than correctness
- Shallow implementations that pass obvious tests

### P3: Single Task Visibility

Implementor sees only one task at a time. This prevents:
- Rushing to complete the queue
- Assuming previous tasks work (when they don't)
- Context pollution from many parallel concerns

### P4: External Verification

No actor verifies their own work. Orchestrator verifies implementor; human can verify orchestrator.

### P5: Artifacts Over Assertions

Claims must be backed by artifacts. "I ran the tests" requires test output file. "I ran pre-signal check" requires artifact file.

## Key Components

### Folder Structure

```
.orchestra/
├── orchestrator/           # Orchestrator's domain
│   ├── .orchestrator-only/ # Hidden: verification criteria, preflight checklists
│   ├── scripts/            # Orchestrator's tools
│   ├── results/            # Archived task results (audit trail)
│   ├── manifest.yaml       # Full task list (hidden from implementor)
│   └── progress.yaml       # Sprint progress tracking
│
├── implementor/            # Implementor's domain
│   ├── .implementor-only/  # Private: validation scripts, task validator
│   ├── artifacts/          # Pre-signal check proofs
│   └── readme.md           # Implementor quickstart
│
├── handover/               # Transient exchange zone
│   ├── current-task.md     # The single task being worked
│   ├── task-context.md     # Sprint context
│   └── verification/       # Screenshots, test output, completion signal
│
├── common/                 # Shared resources
│   ├── scripts/            # Environment setup, utilities
│   └── templates/          # Document templates
│
└── docs/                   # Documentation
    ├── readme.md           # Main documentation
    └── research_log.md     # Issue/learning log
```

### Data Flow

```
1. TASK PREPARATION (Orchestrator)
   ┌────────────────────────────────────────────────────────┐
   │  - Read manifest.yaml for next task                    │
   │  - Create verification criteria (hidden)               │
   │  - Populate handover/ from templates                   │
   │  - Fill current-task.md with instructions              │
   │  - Commit and invoke implementor                       │
   └────────────────────────────────────────────────────────┘
                              │
                              ▼
2. IMPLEMENTATION (Implementor)
   ┌────────────────────────────────────────────────────────┐
   │  - Read handover/current-task.md                       │
   │  - Run validation script (prove handover is complete)  │
   │  - Implement per specification                         │
   │  - Create artifacts (tests, screenshots)               │
   │  - Run pre-signal check (creates artifact)             │
   │  - Write completion-signal.md                          │
   │  - Signal "ready for review"                           │
   └────────────────────────────────────────────────────────┘
                              │
                              ▼
3. VERIFICATION (Orchestrator)
   ┌────────────────────────────────────────────────────────┐
   │  - Check pre-signal artifact exists                    │
   │  - Read completion signal                              │
   │  - Read hidden verification criteria                   │
   │  - Execute each check (tests, analysis, visual)        │
   │  - View screenshots via Chrome DevTools MCP            │
   │  - Document results                                    │
   │  - PASS: Archive to results/, prepare next task        │
   │  - FAIL: Provide feedback, implementor retries         │
   └────────────────────────────────────────────────────────┘
                              │
                              ▼
4. ARCHIVE (Orchestrator)
   ┌────────────────────────────────────────────────────────┐
   │  - Copy handover/ to results/task-NNN/                 │
   │  - Add metadata (timestamp, commit hash)               │
   │  - Update progress.yaml                                │
   │  - Update SpecKit tasks.md (if applicable)             │
   │  - Clear handover/ for next task                       │
   └────────────────────────────────────────────────────────┘
```

## Integration Points

### SpecKit Integration (Optional)

If using SpecKit for specification generation:

- SpecKit outputs `tasks.md` with granular tasks (e.g., 56 tasks)
- Orchestrator consolidates into manageable chunks (e.g., 16 tasks)
- `manifest.yaml` maps orchestrator tasks to SpecKit task IDs
- Completion updates both manifest and SpecKit tasks.md

### Visual Verification Integration

For tasks requiring visual verification:

1. **Implementor**: Uses `flutter_agent.py` to capture screenshots
2. **Orchestrator**: Uses Chrome DevTools MCP to view screenshots
3. **Verification**: Compare screenshot content against criteria

### Version Control Integration

- Orchestrator commits after preparing handover
- Implementor commits after implementation (staged by orchestrator)
- Verification results include commit hashes
- Archive preserves full audit trail

## Scalability Considerations

### Task Count

- **Tested**: 16 tasks (single sprint)
- **Expected**: Up to ~50 tasks per sprint
- **Challenge**: Context window limits with large task counts
- **Mitigation**: Single task visibility, phase boundaries

### Model Tiers

Orchestra supports different model tiers:

| Role | Recommended Tier | Rationale |
|------|------------------|-----------|
| Orchestrator | High (Opus, GPT-4) | Complex reasoning, verification |
| Implementor | Medium (Sonnet) | Code execution, following specs |
| Simple tasks | Low (Haiku) | Enum creation, simple models |

### Cost Model

```
Traditional (single high-tier agent):
  20 tasks × $0.50/task = $10.00

Orchestrator/Implementor split:
  Orchestrator: 1 spec session × $2.00 = $2.00
  Implementor:  20 tasks × $0.10/task = $2.00
  Total: $4.00 (60% savings!)
```

## Dependencies

### Required Tooling

- PowerShell (for scripts)
- Git (version control)
- Chrome DevTools MCP (visual verification)
- Flutter agent tools (for Flutter projects)

### Optional Integrations

- SpecKit (specification generation)
- CI/CD pipelines (automated checks)
- Test frameworks (project-specific)
