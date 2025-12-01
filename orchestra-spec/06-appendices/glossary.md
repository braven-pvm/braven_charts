# Glossary

> **Navigation**: [Index](../readme.md) | **Prev**: [Sprint 011 Case Study](../05-research/sprint-011-case-study.md) | **Next**: [Checklist Templates](checklist-templates.md)

---

## Terms

### Artifact
A file that proves an action occurred. Artifacts serve as structural gates—their existence is required to proceed, and they can only be created by running specific scripts.

**Example**: `pre-signal-001.json` proves the pre-signal check was run for task 1.

### BLOCKING (Severity)
The highest severity level for verification checks. Any BLOCKING check failure immediately fails the task. Cannot be downgraded after task definition.

**Example**: "Unit tests must pass" - if tests fail, task fails regardless of other factors.

### Closeout Check
A verification script run by the orchestrator to confirm a task is truly complete before proceeding to the next task. Validates artifacts, git state, and traceability.

**Script**: `task-closeout-check.ps1`

### Completion Signal
The formal indication from implementor to orchestrator that work is finished and ready for verification. Consists of:
1. Pre-signal artifact (proving checks ran)
2. Filled completion-signal.md
3. Verbal/written "ready for review"

### Context Pollution
The degradation of AI agent understanding over long sessions. Old assumptions conflict with new information, leading to errors. Mitigated by fresh sessions with explicit handovers.

### Deliverable
A specific output required by a task. Listed explicitly in the handover to set clear expectations.

**Example**: "Create `y_axis_config.dart` with YAxisConfig class"

### Escalation
The process of raising a task to human review when:
- 3 attempts have failed
- Specification is unclear or impossible
- Agent cannot complete the work

### Fresh Context
Starting a new agent session with explicit handover rather than continuing from accumulated context. Prevents context pollution.

### Gate (Structural Gate)
A checkpoint that cannot be passed without a required artifact. Unlike advisory instructions, gates are enforced by scripts checking for proof-of-execution.

**Example**: Verification cannot start without pre-signal artifact existing.

### Goodhart's Law
"When a measure becomes a target, it ceases to be a good measure." The principle explaining why visible verification criteria get gamed. Orchestra addresses this with hidden criteria.

### Handover
The formal package of documents provided when starting a new task or session. Contains everything needed for cold start without prior context.

**Contents**: current-task.md, task-context.md, completion-signal.md template

### Handover Zone
The `.orchestra/handover/` folder serving as the transient exchange between orchestrator and implementor. Empty at rest, populated during active work.

### Hidden Verification
Verification criteria kept in `.orchestrator-only/` where the implementor cannot see them. Prevents gaming by maintaining uncertainty about specific checks.

### Implementor
The AI agent role responsible for:
- Executing tasks per specification
- Writing code and tests
- Creating artifacts
- Signaling completion

**Access**: Public specifications, cannot see hidden verification criteria.

### INFO (Severity)
The lowest severity level. Suggestions only, no effect on pass/fail. Used for style preferences or minor improvements.

### INFRASTRUCTURE (Task Category)
Tasks focused on files, configuration, and setup rather than code functionality. Verification emphasizes existence, structure, and syntax correctness.

**Example**: "Create manifest.yaml with sprint configuration"

### INTEGRATION (Task Category)
Tasks focused on code, tests, and functional integration. Verification emphasizes test passage and API correctness.

**Example**: "Create YAxisConfig model with validation"

### MAJOR (Severity)
Second-highest severity. Multiple MAJOR failures (2+) fail the task. Single MAJOR failures may pass with notes.

### Manifest
The `manifest.yaml` file defining sprint configuration including:
- Sprint metadata
- Task definitions with dependencies
- Phase organization
- SpecKit traceability links

### MINOR (Severity)
Third-highest severity. Noted in verification but does not cause failure. Should be addressed but not required.

### Mutual Verification
The pattern where orchestrator verifies implementor's work AND implementor's artifacts verify to orchestrator that processes were followed. Neither role trusts the other without proof.

### Orchestrator
The AI agent role responsible for:
- Preparing handovers
- Verifying implementations
- Managing task flow
- Providing feedback on failures

**Access**: Full access including hidden verification criteria.

### Phase
A grouping of related tasks within a sprint. Phase boundaries are good points for fresh context.

**Example**: "Phase 2: Normalization" containing tasks 6-8.

### Pre-Signal Check
A script run by implementor before signaling completion. Creates an artifact proving tests passed and requirements verified.

**Script**: `pre-signal-check.ps1`

### Progress Tracking
The `progress.yaml` file tracking:
- Task completion status
- Attempt counts
- Timestamps
- Commit references

### Results Archive
The `.orchestra/orchestrator/results/` folder containing archived completed tasks. Immutable after archival for audit trail.

### Role Separation
The deliberate division of implementation and verification into distinct roles (implementor and orchestrator) to prevent conflict of interest.

### Severity Level
The classification of verification check importance:
- BLOCKING: Must pass
- MAJOR: Accumulate; 2+ fail
- MINOR: Noted, doesn't fail
- INFO: Suggestions only

### Signal
See "Completion Signal"

### SpecKit
The specification toolkit used to define requirements. Tasks link to SpecKit items for traceability.

**Location**: `specs/*/tasks.md`

### Sprint
A time-bounded effort to complete a set of related tasks. Typically 1-4 weeks.

### Task
A discrete unit of work with:
- Clear objective
- Defined deliverables
- Verification criteria
- Dependencies

### Task Category
Classification determining verification approach:
- INFRASTRUCTURE: File/config focused
- INTEGRATION: Code/test focused
- VISUAL: Appearance focused

### Task Lifecycle
The states a task passes through:
PENDING → IN-PROGRESS → AWAITING-VERIFICATION → COMPLETED/FAILED

### Three-Strike Rule
Maximum 3 attempts per task before escalation to human. Prevents infinite loops and forces quality feedback.

### Traceability
The linking between:
- Tasks and specification items
- Implementation and requirements
- Verification and criteria

Bidirectional traceability ensures completeness.

### Transient
Temporary, not persisted. The handover folder is transient—empty at rest, populated only during active work.

### Verification
The process of checking implementation against criteria. Performed by orchestrator after implementor signals completion.

### Verification Criteria
The specific checks used to verify task completion. Hidden from implementor to prevent gaming.

**Location**: `.orchestrator-only/verification/task-NNN.yaml`

### VISUAL (Task Category)
Tasks focused on UI, rendering, and appearance. Verification requires actual visual inspection via Chrome DevTools MCP.

**Example**: "Create demo showing multi-axis chart rendering"

### Visual Verification
The process of actually viewing screenshots/visual artifacts to verify content correctness, not just file existence.

**Tool**: Chrome DevTools MCP with `file://` URLs

## Abbreviations

| Abbr | Meaning |
|------|---------|
| ADR | Architecture Decision Record |
| MCP | Model Context Protocol |
| PR | Pull Request |
| SpecKit | Specification Toolkit |
| yaml | YAML Ain't Markup Language |

## File Extensions

| Extension | Usage |
|-----------|-------|
| `.md` | Documentation, handover templates |
| `.yaml` | Configuration, manifest, criteria |
| `.json` | Artifacts, metadata |
| `.ps1` | PowerShell scripts |
| `.dart` | Dart source code |
