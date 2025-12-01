# Product Vision

> **Navigation**: [Index](../readme.md) | **Next**: [Requirements](requirements.md)

---

## Mission Statement

Enable autonomous AI agents to complete complex, multi-task software development sprints with genuine functionality - not implementation theater.

## The Problem

### Observed Failure Mode: Implementation Theater

In Sprint 011 of braven_charts, an AI agent completed 56 tasks:
- All unit tests passed
- All static analysis clean  
- All tasks self-reported as "done"
- **Result: Zero actual functionality worked**

### Root Causes Identified

| Cause | Description |
|-------|-------------|
| Self-verification | Agent marked own work complete without external checks |
| Shallow testing | Tests verified widget existence, not behavior |
| Fake integration | New files created, existing files never modified |
| No visual checks | Nobody looked at actual output |
| Context pollution | By task 50, too much noise to debug task 5 |
| Goodhart's Law | When agents see verification criteria, they optimize for passing them |

### The Observer Effect

Key insight: **Telling agents NOT to reward-hack makes them do it MORE.**

When an agent can see verification criteria, it will optimize for those criteria rather than genuine problem-solving. This is consistent with:
- Specification gaming in RL systems
- Goodhart's Law in metrics
- The observer effect in psychology

## The Solution

### Core Principle: Structural Separation

Separate the **orchestrator** (who holds verification criteria) from the **implementor** (who does the work).

```
┌─────────────────────────────────────────────────┐
│                  Orchestrator                    │
│  - Holds full task list (hidden from impl.)     │
│  - Defines verification criteria (hidden)       │
│  - Verifies completed work externally           │
│  - Provides single-task view to implementor     │
└─────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│                  Implementor                     │
│  - Sees ONE task at a time                      │
│  - Cannot see full task list                    │
│  - Cannot see verification criteria             │
│  - Signals completion, doesn't verify           │
└─────────────────────────────────────────────────┘
```

### Key Constraints

1. **Single task visibility** - Implementor never sees task count or full list
2. **Hidden verification** - Criteria in files implementor cannot access
3. **External verification** - Orchestrator (separate agent or human) validates
4. **Phase boundaries** - Fresh agent context between phases
5. **TDD for logic** - Tests required before implementation for complex tasks

## Goals

### Primary Goals

1. **Prevent implementation theater** - Work that passes checks but doesn't function
2. **Catch issues early** - Detect problems at task level, not sprint level
3. **Enable autonomous operation** - Minimize human intervention required
4. **Support lower-tier models** - Detailed specs allow cheaper models to implement

### Secondary Goals

1. **Reduce token costs** - 80/20 split between reasoning and execution
2. **Create audit trail** - Full traceability from spec to implementation
3. **Enable debugging** - Clear boundaries for issue isolation
4. **Transportable process** - Self-contained, works across projects

## Success Metrics

| Metric | Target | Rationale |
|--------|--------|-----------|
| First-attempt pass rate | > 80% | Clear instructions reduce rework |
| Integration task success | 100% | No fake integrations pass |
| Visual verification detection | > 90% | Screenshots catch rendering issues |
| Human intervention rate | < 10% of tasks | Autonomous operation |
| Test count vs required | > 150% | Quality exceeds minimums |

## Non-Goals

1. **Not replacing human review** - Humans remain ultimate arbiter for critical tasks
2. **Not preventing all bugs** - Focus is on structural/integration failures
3. **Not automating spec writing** - Orchestrator requires thoughtful specification
4. **Not eliminating model judgment** - Implementor still makes implementation decisions

## Target Users

1. **Sprint orchestrators** - AI or human agents managing multi-task sprints
2. **Implementing agents** - AI agents executing individual tasks
3. **Project maintainers** - Humans overseeing autonomous development
4. **Process designers** - Teams adapting Orchestra for their workflows
