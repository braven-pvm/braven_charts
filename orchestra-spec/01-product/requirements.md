# Functional Requirements

> **Navigation**: [Index](../readme.md) | **Prev**: [Vision](vision.md) | **Next**: [Success Criteria](success-criteria.md)

---

## Overview

This document defines the functional requirements for the Orchestra pattern, organized by capability area.

## FR-100: Role Separation

### FR-101: Orchestrator Role

The system shall support an orchestrator role with the following capabilities:

- [ ] FR-101.1: Read and manage full task manifest
- [ ] FR-101.2: Create and maintain hidden verification criteria
- [ ] FR-101.3: Prepare single-task handover documents
- [ ] FR-101.4: Verify completed work against hidden criteria
- [ ] FR-101.5: Record verification results and archive completed tasks
- [ ] FR-101.6: Update progress tracking after each task
- [ ] FR-101.7: Maintain SpecKit traceability (if applicable)

### FR-102: Implementor Role

The system shall support an implementor role with the following capabilities:

- [ ] FR-102.1: Read single-task handover documents
- [ ] FR-102.2: Validate handover document completeness
- [ ] FR-102.3: Execute implementation per task specification
- [ ] FR-102.4: Create verification artifacts (screenshots, test output)
- [ ] FR-102.5: Signal task completion with summary
- [ ] FR-102.6: Run pre-completion validation checks

### FR-103: Role Isolation

The system shall enforce separation between roles:

- [ ] FR-103.1: Implementor cannot read orchestrator-only files (manifest, verification criteria)
- [ ] FR-103.2: Orchestrator should not read implementor-only files (validation rules)
- [ ] FR-103.3: Shared artifacts have defined access patterns
- [ ] FR-103.4: File structure enforces isolation (`.role-only/` folders)

## FR-200: Task Management

### FR-201: Task Definition

Each task shall include:

- [ ] FR-201.1: Unique task identifier
- [ ] FR-201.2: Clear objective statement
- [ ] FR-201.3: List of files to create/modify
- [ ] FR-201.4: Technical context and dependencies
- [ ] FR-201.5: TDD requirements (if applicable)
- [ ] FR-201.6: Visual verification requirements (if applicable)
- [ ] FR-201.7: Quality gate criteria
- [ ] FR-201.8: Completion signaling protocol

### FR-202: Task Lifecycle

The system shall support the following task states:

- [ ] FR-202.1: `pending` - Task defined but not started
- [ ] FR-202.2: `in-progress` - Task assigned to implementor
- [ ] FR-202.3: `awaiting-verification` - Implementation complete, awaiting review
- [ ] FR-202.4: `failed` - Verification failed, requires rework
- [ ] FR-202.5: `completed` - Verification passed, archived

### FR-203: Task Handover

Task handover documents shall:

- [ ] FR-203.1: Be created from standardized templates
- [ ] FR-203.2: Include all sections (filled or marked N/A with reason)
- [ ] FR-203.3: Contain no placeholder markers ([TODO], [TBD])
- [ ] FR-203.4: Specify task category (INFRASTRUCTURE, INTEGRATION, VISUAL)
- [ ] FR-203.5: Include complete implementation guidance for autonomous execution

## FR-300: Verification

### FR-301: Verification Criteria

Verification criteria shall:

- [ ] FR-301.1: Be defined before task implementation begins
- [ ] FR-301.2: Be hidden from implementor until after verification
- [ ] FR-301.3: Include severity levels (BLOCKING, MAJOR, MINOR, INFO)
- [ ] FR-301.4: Have immutable severity (cannot be downgraded during verification)
- [ ] FR-301.5: Include structural checks (files exist, exports added)
- [ ] FR-301.6: Include functional checks (tests pass, behavior correct)
- [ ] FR-301.7: Include adversarial checks for critical tasks

### FR-302: Visual Verification

For visual/integration tasks, the system shall:

- [ ] FR-302.1: Require screenshot artifacts
- [ ] FR-302.2: Define specific visual criteria to verify
- [ ] FR-302.3: Support screenshot viewing by orchestrator (Chrome DevTools MCP)
- [ ] FR-302.4: Verify each visual criterion against actual screenshot content
- [ ] FR-302.5: Distinguish between screenshot existence and correctness

### FR-303: Verification Results

Verification results shall:

- [ ] FR-303.1: Document all checks performed
- [ ] FR-303.2: Record PASS/FAIL for each check with evidence
- [ ] FR-303.3: Include overall task status
- [ ] FR-303.4: Be archived with completed task artifacts

## FR-400: Quality Gates

### FR-401: Static Analysis

Every task completion shall require:

- [ ] FR-401.1: Zero static analysis errors in affected files
- [ ] FR-401.2: Zero static analysis warnings in affected files
- [ ] FR-401.3: Pre-existing issues in touched files must be fixed

### FR-402: Test Suite

Every task completion shall require:

- [ ] FR-402.1: Task-specific tests pass
- [ ] FR-402.2: All sprint tests pass (regression check)
- [ ] FR-402.3: Minimum test count met (where specified)
- [ ] FR-402.4: Integration tests pass (for integration tasks)

### FR-403: Code Quality

Every task shall:

- [ ] FR-403.1: Follow existing codebase conventions
- [ ] FR-403.2: Use existing utilities (not duplicate logic)
- [ ] FR-403.3: Include proper documentation
- [ ] FR-403.4: Export from appropriate barrel files

## FR-500: Artifacts and Audit Trail

### FR-501: Pre-Signal Artifacts

Implementor shall create:

- [ ] FR-501.1: Pre-signal check artifact proving validation script was run
- [ ] FR-501.2: Test output captured to file
- [ ] FR-501.3: Screenshots (for visual tasks)
- [ ] FR-501.4: Completion signal document

### FR-502: Task Archive

After verification, orchestrator shall archive:

- [ ] FR-502.1: Complete handover folder copy
- [ ] FR-502.2: All verification artifacts
- [ ] FR-502.3: Verification results summary
- [ ] FR-502.4: Metadata (timestamps, commit hash)

### FR-503: Traceability

The system shall maintain:

- [ ] FR-503.1: Mapping from orchestrator tasks to source spec tasks
- [ ] FR-503.2: Checkmarks on source spec tasks when completed
- [ ] FR-503.3: Commit references for each completed task
- [ ] FR-503.4: Progress tracking across sprint

## FR-600: Scripts and Automation

### FR-601: Environment Setup

The system shall provide:

- [ ] FR-601.1: Environment variable configuration script
- [ ] FR-601.2: Path variables for all key locations
- [ ] FR-601.3: Sprint-specific configuration

### FR-602: Orchestrator Scripts

The system shall provide:

- [ ] FR-602.1: Task closeout check (verify previous task complete)
- [ ] FR-602.2: Handover preparation (populate from templates)
- [ ] FR-602.3: Handover validation (check completeness)
- [ ] FR-602.4: Accept signal check (verify implementor's artifact)
- [ ] FR-602.5: Archive and close (copy to results, clear handover)
- [ ] FR-602.6: SpecKit coverage check (bidirectional sync)

### FR-603: Implementor Scripts

The system shall provide:

- [ ] FR-603.1: Handover validation (check task document quality)
- [ ] FR-603.2: Pre-signal check (verify work before signaling)
- [ ] FR-603.3: Scripts create artifacts proving execution

## FR-700: Templates

### FR-701: Required Templates

The system shall provide templates for:

- [ ] FR-701.1: Task handover document (`current-task.md`)
- [ ] FR-701.2: Task context document (`task-context.md`)
- [ ] FR-701.3: Completion signal document
- [ ] FR-701.4: Verification criteria YAML
- [ ] FR-701.5: Verification results document

### FR-702: Template Enforcement

Templates shall:

- [ ] FR-702.1: Include all possible sections
- [ ] FR-702.2: Require explicit N/A with reason (not empty sections)
- [ ] FR-702.3: Be validated by scripts before use
