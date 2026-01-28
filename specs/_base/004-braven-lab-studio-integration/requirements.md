# Requirements: BravenLab Studio Integration (Spec 004)

**Status:** Draft
**Created:** 2026-01-28
**Updated:** 2026-01-28
**Priority:** High

## Overview

This specification outlines the requirements for the next major iteration of `braven_chart_plus`, focusing on transforming it from a standalone charting tool into the core engine for "BravenLab Studio". The goal is to support a professional-grade, agentic data analysis workflow for endurance athletes.

## Dedicated Specifications

For clarity and implementation focus, this requirement set is broken down into three detailed specifications:

- **[Spec 004.1: BravenAgent Package (The Brain)](004.1-braven-agent-extraction.md)** — **ACTIVE**
  - **NEW PACKAGE:** Creation of `braven_agent` as a standalone package.
  - **Decoupling:** Extracting AI/orchestration logic from `braven_chart_plus`.
  - **V1 Scope:** `create_chart`, `modify_chart` tools, `AgentSession`, `ChartRenderer`.
  - **Dependencies:** `braven_chart_plus` (for widget output), `anthropic_sdk_dart` (LLM).
  - **NOT in V1:** Data tools, athlete context, file handling (see 004.2/004.3).

- **[Spec 004.2: BravenLab Studio UI/UX (The App)](004.2-bls-ui-ux.md)** — FUTURE
  - The "Pro" application shell.
  - Workflow, Dashboards, and Inspector panels.
  - Consuming the `braven_agent` engine.
  - `SessionContext`, `AgentSessionFactory`, athlete identity injection.

- **[Spec 004.3: Athlete Datastore (The Memory)](004.3-athlete-datastore.md)** — FUTURE
  - Database schema and persistence (in BLS).
  - FIT file ingestion pipeline (using `braven_data`).
  - Athlete identity management.
  - `DataContext` interface and data-aware tools.
