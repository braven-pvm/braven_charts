# Requirements: BravenLab Studio Integration (Spec 004)

**Status:** Draft
**Created:** 2026-01-28
**Priority:** High

## Overview

This specification outlines the requirements for the next major iteration of `braven_chart_plus`, focusing on transforming it from a standalone charting tool into the core engine for "BravenLab Studio". The goal is to support a professional-grade, agentic data analysis workflow for endurance athletes.

## 1. Chat Flow & UI/UX Overhaul

The current chat interface is functional but visually cluttered and disjointed. The new experience must be seamless, professional, and intuitive.

### 1.1 Visual Hierarchy & Layout
- **Unified Theme:** The chat interface must match the BravenLab Studio aesthetic (dark mode optimization, consistent typography).
- **Reduced Clutter:** Message bubbles should be clean. Data attachments and chart previews should be collapsible or shown as rich cards, not raw text blocks.
- **Thinking Indicator:** Clear, non-intrusive animation when the agent is processing.

### 1.2 Inline Chat Experience
- **Context Awareness:** The inline chat must float or tile next to the chart without obscuring it.
- **Visual Feedback:** When the agent modifies a chart property (e.g., changing color), the change should animate or highlight to provide immediate feedback.
- **History Integration:** Inline commands must be logged in the global chat history with a reference to which chart was modified.

### 1.3 Interaction Design
- **Slash Commands:** Support for `/` commands (e.g., `/reset`, `/export`, `/compare`) for power users.
- **Quick Actions:** One-tap suggestions for common tasks (e.g., "Smooth this line", "Add moving average").

## 2. FIT File Data Pipeline

Implementing the "Smart Data Reduction" pipeline to allow agents to analyze massive FIT files without context overflow.

### 2.1 Ingestion & Reduction
- **Ingestion Layer:** Ability to parse `.fit` files (and potentially CSV/JSON).
- **Smart Reduction:** Automatically downsample high-frequency data (1Hz) into manageable chunks for visualization (e.g., ~1000-2000 points) using algorithms like LTTB (Largest Triangle Three Buckets).
- **Metric Extraction:** Extract key metrics (Max Power, Average HR, Normalized Power) and make them available as structured metadata to the LLM.

### 2.2 Agent Accessibility
- **Metadata Context:** The agent should see the *structure* `metadata` of the file (columns, duration, key stats) effectively.
- **Data Querying:** The agent must have a tool to "query" the raw data if needed (e.g., "Get max power for the 20-minute interval starting at 10:00"). It cannot consume the whole file, but it can ask specific questions about it.

## 3. Athlete & Session Management

Moving from a single-session, stateless experience to a persistent, multi-athlete ecosystem.

### 3.1 Data Model
- **Athlete Identity:** A new core entity representing a user.
- **Session:** A workout file or analysis session belonging to an athlete.
- **Chart Library:** Generated charts must be persisted and associated with a specific Athlete and Session, not lost when the app closes.

### 3.2 Datastore Integration
- **Persistent Storage Interface:** Define an abstract `BravenStore` interface. The package provides the definition; the Studio application implements it (e.g., using SQLite/Isar/Hive).
- **Context Loading:** When an athlete is selected:
    - Load their historical context (FTP, Max HR zones).
    - Load previous chat history relevant to the current session.
    - Make this context available to the agent for personalized insights (e.g., "This power is 20% above Hansie's FTP").

## 4. Architecture Refactor

- **Split of Concerns:**
    - `braven_chart_plus`: Core rendering, agent tools, data reduction algorithms, abstract storage interfaces.
    - `BravenLab Studio` (Application): UI chrome, concrete database implementation, user management, file I/O.
