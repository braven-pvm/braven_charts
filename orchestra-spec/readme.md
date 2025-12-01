# Orchestra: Agent Orchestration Pattern Specification

A structured methodology for autonomous AI agent coordination in software development workflows.

## Overview

Orchestra is a file-based orchestrator/implementor pattern designed to prevent "implementation theater" - the failure mode where AI agents complete tasks without genuine functionality.

## Problem Statement

Observed in Sprint 011: 56 tasks completed, all tests passing, zero actual functionality working.

**Root causes:**
- Self-reported completion without external verification
- Shallow tests (checked existence, not behavior)
- Integration tasks that created new files without modifying existing ones
- No visual/functional verification between tasks
- Context pollution over long task sequences

## Solution Summary

Separate the **orchestrator** (who holds verification criteria) from the **implementor** (who does the work), with verification criteria hidden from the implementor.

## Documentation Structure

```
orchestra-spec/
├── readme.md                       # This file
├── 01-product/                     # Product requirements
│   ├── vision.md                   # Product vision and goals
│   ├── requirements.md             # Functional requirements
│   └── success-criteria.md         # Measurable success criteria
├── 02-architecture/                # System architecture
│   ├── overview.md                 # Architecture overview
│   ├── roles.md                    # Role definitions (orchestrator/implementor)
│   ├── workflows.md                # Core workflows
│   └── decisions/                  # Architecture Decision Records (ADRs)
│       └── adr-001-translation-layer.md
├── 03-components/                  # Component specifications
│   ├── folder-structure.md         # Canonical folder structure
│   ├── file-specifications.md      # File formats and schemas
│   ├── scripts.md                  # Script inventory and purpose
│   └── templates.md                # Template definitions
├── 04-processes/                   # Process documentation
│   ├── task-lifecycle.md           # Full task lifecycle
│   ├── verification-protocol.md    # Verification procedures
│   ├── visual-verification.md      # Screenshot verification
│   ├── failure-handling.md         # Failure feedback and retry
│   └── handover-lifecycle.md       # Handover folder states
├── 05-research/                    # Research findings
│   ├── key-discoveries.md          # Critical insights from development
│   └── sprint-011-case-study.md    # Before/after case study
└── 06-appendices/                  # Reference materials
    ├── glossary.md                 # Terms and definitions
    ├── checklist-templates.md      # Ready-to-use checklists
    └── example-files.md            # Example manifest, progress, etc.
```

## Status

**Current Version**: 0.1.0 (Draft)
**Based On**: `.orchestra/` implementation in braven_charts_v2.0
**Files**: 17 specification documents

---

## Document Index

### 01 - Product
| # | Document | Description |
|---|----------|-------------|
| 1 | [vision.md](01-product/vision.md) | Mission, principles, and anti-patterns |
| 2 | [requirements.md](01-product/requirements.md) | 40+ functional requirements |
| 3 | [success-criteria.md](01-product/success-criteria.md) | Measurable success metrics |

### 02 - Architecture
| # | Document | Description |
|---|----------|-------------|
| 4 | [overview.md](02-architecture/overview.md) | System context and principles |
| 5 | [roles.md](02-architecture/roles.md) | Orchestrator and implementor definitions |
| 6 | [workflows.md](02-architecture/workflows.md) | Core workflow steps |
| 7 | [adr-001-translation-layer.md](02-architecture/decisions/adr-001-translation-layer.md) | Architecture decision record |

### 03 - Components
| # | Document | Description |
|---|----------|-------------|
| 8 | [folder-structure.md](03-components/folder-structure.md) | The .orchestra folder layout |
| 9 | [file-specifications.md](03-components/file-specifications.md) | File formats and schemas |
| 10 | [scripts.md](03-components/scripts.md) | Script inventory and purpose |
| 11 | [templates.md](03-components/templates.md) | Template definitions |

### 04 - Processes
| # | Document | Description |
|---|----------|-------------|
| 12 | [task-lifecycle.md](04-processes/task-lifecycle.md) | Task states and transitions |
| 13 | [verification-protocol.md](04-processes/verification-protocol.md) | Severity levels and checks |
| 14 | [visual-verification.md](04-processes/visual-verification.md) | Screenshot verification workflow |
| 15 | [failure-handling.md](04-processes/failure-handling.md) | Retry mechanism and escalation |
| 16 | [handover-lifecycle.md](04-processes/handover-lifecycle.md) | Handover folder states |

### 05 - Research
| # | Document | Description |
|---|----------|-------------|
| 17 | [key-discoveries.md](05-research/key-discoveries.md) | 10 critical insights from development |
| 18 | [sprint-011-case-study.md](05-research/sprint-011-case-study.md) | Before/after comparison |

### 06 - Appendices
| # | Document | Description |
|---|----------|-------------|
| 19 | [glossary.md](06-appendices/glossary.md) | 50+ terms defined |
| 20 | [checklist-templates.md](06-appendices/checklist-templates.md) | Ready-to-use checklists |
| 21 | [example-files.md](06-appendices/example-files.md) | Example manifest, progress, etc. |

### Implementation
| # | Document | Description |
|---|----------|-------------|
| 22 | [implementation-plan.md](implementation-plan.md) | Phased implementation roadmap |

---

## Reading Paths

### Quick Read (~15 min)
1. [Vision](01-product/vision.md) - Understand the problem
2. [Roles](02-architecture/roles.md) - Understand the solution
3. [Key Discoveries](05-research/key-discoveries.md) - Understand the insights

### Full Read (~45 min)
Follow documents 1-21 in order above.

### Reference Only
- [Glossary](06-appendices/glossary.md) - Look up terms
- [Checklists](06-appendices/checklist-templates.md) - Copy-paste checklists
- [Examples](06-appendices/example-files.md) - Copy-paste file examples

