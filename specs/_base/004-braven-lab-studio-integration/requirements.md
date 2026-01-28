# Requirements: BravenLab Studio Integration (Spec 004)

**Status:** Draft
**Created:** 2026-01-28
**Priority:** High

## Overview

This specification outlines the requirements for the next major iteration of `braven_chart_plus`, focusing on transforming it from a standalone charting tool into the core engine for "BravenLab Studio". The goal is to support a professional-grade, agentic data analysis workflow for endurance athletes.

## Dedicated Specifications

For clarity and implementation focus, this requirement set is broken down into three detailed specifications:

- **[Spec 004.1: BCP Refactor (Headless Engine)](004.1-bcp-refactor-headless.md)**
    - Removing chat UI from the package.
    - Exposing `AgentController` streams.
    - Keeping only `ChartRenderer` in the package.

- **[Spec 004.2: BravenLab Studio UI/UX](004.2-bls-ui-ux.md)**
    - The "Pro" application shell.
    - Workflow, Dashboards, and Inspector panels.
    - Consuming the headless BCP engine.

- **[Spec 004.3: Athlete Datastore](004.3-athlete-datastore.md)**
    - Database schema and persistence.
    - FIT file ingestion pipeline.
    - Athlete identity management.
