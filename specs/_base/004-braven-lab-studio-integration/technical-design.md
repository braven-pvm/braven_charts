# Technical Design: BravenLab Studio Integration (Spec 004)

## Architecture Overview

The system transitions to a layered architecture where `braven_chart_plus` provides the "Engine" and `BravenLab Studio` acts as the "Shell".

## 1. Data Pipeline Architecture (FIT Files)

To solve the context window limit, we implement a "Summary-Query" pattern.

### 1.1 The `SmartDataSource` Class

A wrapper around raw data files.

```dart
class SmartDataSource {
  final String id;
  final FitFile metadata; // Lightweight stats
  final List<DataPoint> _reducedData; // ~2000 points for rendering
  final List<DataPoint> _rawData; // Full resolution (kept in memory/disk, NOT sent to LLM)

  // Returns token-efficient summary for the System Prompt
  String get llmSummary => "...";
}
```

### 1.2 Agent Tools

The agent cannot see `_rawData`. Instead, it uses tools to ask questions:

- `analyze_segment(start, end)`: Returns stats for a specific time range.
- `find_peaks(metric, duration)`: Returns peak power/HR for given duration.
- `get_reduced_series()`: Returns the LTTB-downsampled series for rendering only.

## 2. Store & Athlete Management

We introduce a Repository pattern to abstract persistence.

### 2.1 Interfaces (in Package)

```dart
abstract class BravenStore {
  Future<Athlete?> getAthlete(String id);
  Future<void> saveChart(String athleteId, ChartConfiguration chart);
  Future<List<ChartConfiguration>> getCharts(String athleteId);
}

class Athlete {
  final String id;
  final String name;
  final AthleteMetrics metrics; // FTP, Zones, etc.
}
```

### 2.2 Integration

The `AgentService` will now require a `BravenStore` and a current `athleteId` context to function effectively.

## 3. UI/UX Component Library

The standard chat widgets will be refactored into a composable library:

- `BravenChatPanel`: The main container.
- `BravenMessageBubble`: Standardized bubble with support for "Rich Content" slots.
- `BravenInlineChat`: A floating/dockable version of the panel.

## 4. Architecture Refactor & Boundary Definition (CRITICAL)

Strict separation of concerns is required to keep `braven_chart_plus` a reusable package while enabling `BravenLab Studio` functionality.

### 4.1 BravenChartPlus Package (The "Engine")

**Responsibility:** "How to process data and render charts."

- **Components:**
  - `AgentService`: The core logic for talking to the LLM.
  - `SmartDataSource`: The logic for ingesting and reducing FIT/CSV files.
  - `BravenStore` (Abstract): Interface definitions for data access.
  - `ChartRenderer`: The Flutter widgets for drawing the charts.
  - `ChatWidgets`: Reusable UI components (bubbles, panels) but _styled_ generically.
- **Dependencies:** `dart:ui`, `flutter`, `llm_provider`, `fast_equatable`.
- **Forbidden:** Database implementations (Isar/Hive), User Auth logic, Specific file system paths.

### 4.2 BravenLab Studio (The "Application")

**Responsibility:** "Who analyzes what data."

- **Components:**
  - **Identity Management:** Selecting "Hansie Joubert", Auth.
  - **Concrete Store:** Implementation of `BravenStore` using Isar/SQLite.
  - **File Management:** Reading files from disk, passing file streams to `SmartDataSource`.
  - **App Shell:** Navigation, Settings, Theme configuration.
- **Dependencies:** `braven_chart_plus`, `isar`, `path_provider`, etc.

### 4.3 Integration Point

The Application initializes the Package by injecting dependencies:

```dart
// In BravenLab Studio (main.dart)
final store = IsarBravenStore(); // Implements abstract BravenStore
final agentService = AgentService(
  store: store,
  llmProvider: AnthropicProvider(apiKey: ...),
);
```

## 5. Migration Path

1. **Phase 1 (Data):** Implement `SmartDataSource` and LTTB reduction in `braven_chart_plus`.
2. **Phase 2 (Store):** Define `BravenStore` interfaces and mock implementation.
3. **Phase 3 (UI):** Refactor widgets to use the new unified design system.
4. **Phase 4 (Integration):** Wire it all up in the Example app (proto-Studio).
