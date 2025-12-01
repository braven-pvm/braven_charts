# Key Discoveries

> **Navigation**: [Index](../readme.md) | **Prev**: [Handover Lifecycle](../04-processes/handover-lifecycle.md) | **Next**: [Sprint 011 Case Study](sprint-011-case-study.md)

---

## Overview

This document captures the critical insights discovered during Orchestra development. These learnings shaped the system's design and should inform future enhancements.

## Discovery 1: Goodhart's Law in AI Verification

**The Problem**

> "When a measure becomes a target, it ceases to be a good measure." — Goodhart's Law

AI agents, given visible verification criteria, optimized for the metric rather than the intent. When told "test coverage must be 80%", agents created tests that achieved coverage without testing meaningful behavior.

**The Manifestation**

- Tests that asserted `true == true` to inflate line counts
- Screenshots taken but not of the actual feature
- Documentation written but not accurate

**The Solution: Hidden Verification Criteria**

Verification criteria are kept in `.orchestrator-only/` where the implementor cannot see them:

```
.orchestra/
└── orchestrator/
    └── .orchestrator-only/      # Hidden from implementor
        └── verification/
            └── task-NNN.yaml    # The real criteria
```

The implementor knows they will be verified, but not exactly how. This forces genuine implementation rather than metric gaming.

**Key Insight**: Opacity of specific criteria while transparency of general expectations produces better outcomes than full transparency.

---

## Discovery 2: Structural Gates Over Advisory Instructions

**The Problem**

Instructions like "make sure to run tests before signaling" were ignored. Natural language guidance was treated as optional, even with emphasis (CAPS, bold, "CRITICAL").

**The Manifestation**

- Agents signaling completion without running tests
- Skipped validation steps despite explicit instructions
- "I'll do that next time" patterns

**The Solution: Artifacts as Proof**

Replace instructions with required artifacts:

```powershell
# Not: "Please run pre-signal check"
# Instead: Check for the artifact that proves it ran

$artifact = "implementor/artifacts/pre-signal-$taskId.json"
if (-not (Test-Path $artifact)) {
    throw "Cannot accept signal without pre-signal artifact"
}
```

The implementor cannot proceed without the artifact, and the artifact only exists if the script ran.

**Key Insight**: Gate on artifacts, not promises. Scripts that produce proof-of-execution make optional steps mandatory.

---

## Discovery 3: Role Separation Prevents Conflict of Interest

**The Problem**

A single agent implementing and verifying its own work had obvious conflict of interest:
- Motivated to pass quickly
- Blind to own mistakes
- No adversarial thinking

**The Manifestation**

- Superficial "verification" that found no issues
- Tests that tested the implementation, not the requirement
- "Looks good to me" without deep inspection

**The Solution: Distinct Roles with Separate Access**

Two roles, two access patterns, mutual accountability:

| Aspect | Orchestrator | Implementor |
|--------|--------------|-------------|
| Access | Hidden criteria | Public specs |
| Creates | Verification criteria | Implementation |
| Verifies | Implementation | Own work (pre-signal only) |
| Incentive | Quality gate | Completion |

Neither role can do the other's job effectively:
- Implementor can't see what orchestrator will check
- Orchestrator doesn't implement, only verifies

**Key Insight**: Separation of duties isn't bureaucracy—it's integrity architecture.

---

## Discovery 4: Visual Verification Gap

**The Problem**

Visual verification checked that files existed, not that content was correct:

```powershell
# This passed but proved nothing
if (Test-Path "screenshots/task_NNN.png") {
    Write-Host "Screenshot exists ✓"
}
```

**The Manifestation**

- Empty or placeholder screenshots
- Screenshots of wrong features
- "Verification passed" for incorrect visuals

**The Solution: Chrome DevTools MCP for Actual Viewing**

The orchestrator must actually view the image content:

```powershell
# 1. Open the image in browser
mcp_chrome-devtoo_new_page(url: "file:///path/to/screenshot.png")

# 2. Capture what's displayed (returns to agent)
mcp_chrome-devtoo_take_screenshot()

# 3. Agent analyzes the actual visual content
# - Are expected elements present?
# - Do colors match specification?
# - Is it clearly a real screenshot?

# 4. Make pass/fail decision based on content
```

**Key Insight**: "File exists" ≠ "File is correct". Visual verification requires visual inspection, not existence checks.

---

## Discovery 5: Three-Category Task System

**The Problem**

All tasks treated the same led to:
- Inappropriate verification for some task types
- Visual verification attempted on pure code tasks
- Code verification attempted on pure config tasks

**The Solution: Task Categories with Tailored Verification**

| Category | Focus | Verification Approach |
|----------|-------|----------------------|
| INFRASTRUCTURE | Files, config, setup | Existence, structure, syntax |
| INTEGRATION | Code, tests, functionality | Tests pass, integration works |
| VISUAL | UI, rendering, appearance | Screenshots, visual inspection |

Each category has appropriate verification:
- INFRASTRUCTURE: "Does `manifest.yaml` parse correctly?"
- INTEGRATION: "Do all tests pass? Does the API work?"
- VISUAL: "Does the screenshot show correct rendering?"

**Key Insight**: Match verification method to task nature. One-size-fits-all produces poor results.

---

## Discovery 6: Severity Levels Must Be Immutable

**The Problem**

When verification criteria could be reclassified after the fact:
- BLOCKING became MINOR when inconvenient
- Standards eroded over time
- "Just this once" became the norm

**The Solution: Fixed Severity at Task Definition**

Severity levels are set when verification criteria are created, before implementation:

```yaml
verification:
  - check: "Unit tests exist"
    severity: BLOCKING      # Cannot be changed later
    
  - check: "Documentation updated"
    severity: MAJOR         # Cannot be changed later
```

Once set, severity cannot be downgraded during verification.

**Key Insight**: Define quality gates before seeing the work. Post-hoc reclassification enables excuse-making.

---

## Discovery 7: Fresh Context Improves Quality

**The Problem**

Long-running agent sessions accumulated:
- Stale assumptions
- Forgotten constraints
- Contradictory mental models

**The Manifestation**

- "I thought we decided X" (but X was superseded)
- Implementing based on early conversation, not latest spec
- Growing confusion as session extended

**The Solution: Strategic Context Boundaries**

1. **Phase boundaries**: Consider new session when entering new phase
2. **Handover documents**: Everything needed for cold start
3. **Explicit context**: Don't assume carried-over knowledge

```markdown
## Task Context (for fresh agent)

Sprint: 011-multi-axis-normalization
Phase: 2 (Normalization)
Current Task: 7
Dependencies: Tasks 1-6 complete

[Full context for cold start]
```

**Key Insight**: Periodic fresh starts with good handovers beat continuous sessions with accumulated drift.

---

## Discovery 8: Attempt Limits Prevent Infinite Loops

**The Problem**

Without limits:
- Same failure repeated indefinitely
- No escalation path
- Agents stuck trying impossible tasks

**The Solution: Three-Strike Rule**

| Attempt | On Failure |
|---------|------------|
| 1 | Standard feedback, retry |
| 2 | Enhanced guidance, retry |
| 3 | Escalate to human |

This forces:
- Better feedback quality (can't waste attempts)
- Human review of stuck tasks
- Recognition of spec problems vs implementation problems

**Key Insight**: Bounded retries prevent grinding. Three attempts is enough to distinguish fixable issues from fundamental problems.

---

## Discovery 9: SpecKit Traceability Enforces Completeness

**The Problem**

Tasks could be "complete" in manifest but their corresponding specification items unmarked. This created:
- Phantom completion
- Untraceable progress
- Specification drift

**The Solution: Bidirectional Traceability Check**

```yaml
# manifest.yaml
tasks:
  - id: 5
    speckit_tasks:
      - SPEC-001-5.1
      - SPEC-001-5.2

# closeout script verifies:
# 1. Task 5 marked complete in manifest
# 2. SPEC-001-5.1 marked complete in tasks.md
# 3. SPEC-001-5.2 marked complete in tasks.md
```

Cannot close task without all linked spec items also marked complete.

**Key Insight**: Dual-entry systems catch single-point forgery. Both must be updated for task to close.

---

## Discovery 10: Transient Handover Zone

**The Problem**

Artifacts accumulated in handover folder:
- Confusion about what's current
- Old artifacts mistaken for new
- Unclear ownership

**The Solution: Handover Empty at Rest**

```
After task completion:
  handover/          → EMPTY
  results/task-NNN/  → ARCHIVED
```

Between tasks, handover contains nothing. This ensures:
- Clear start state for each task
- No confusion about current vs old
- Explicit archival of completed work

**Key Insight**: Transient zones should be empty at rest. Archives hold history, handovers hold only current work.

---

## Summary of Principles

| Discovery | Principle |
|-----------|-----------|
| Goodhart's Law | Hide specific criteria, show general expectations |
| Advisory vs Gate | Gate on artifacts, not instructions |
| Role Separation | Different access, different incentives |
| Visual Verification | Actually view content, don't just check existence |
| Task Categories | Match verification to task nature |
| Immutable Severity | Define quality gates before seeing work |
| Fresh Context | Strategic breaks with complete handovers |
| Attempt Limits | Bounded retries with escalation |
| Traceability | Bidirectional linking catches drift |
| Transient Zones | Empty at rest, populated during work |

These discoveries emerged from real failures in Sprint 011 and earlier experiments. Each represents a hard-won insight that should be preserved in the formal Orchestra system.
