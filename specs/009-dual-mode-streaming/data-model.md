# Phase 1: Data Model & Design

**Feature**: Dual-Mode Streaming Chart  
**Date**: 2025-10-22  
**Status**: Complete

## Core Entities

### 1. ChartMode (Enum)

**Purpose**: Represents the current operating mode of the chart (streaming or interactive)

**Definition**:
```dart
/// Operating mode for BravenChart with streaming data support.
/// 
/// Chart operates in exactly ONE mode at any time (mutual exclusivity).
enum ChartMode {
  /// Streaming mode: Data updates freely, interaction handlers disabled,
  /// auto-scroll enabled. Optimized for real-time monitoring.
  streaming,
  
  /// Interactive mode: Streaming paused, data buffered, full interaction
  /// enabled (hover, zoom, pan, tap). Optimized for historical analysis.
  interactive,
}
```

**States**: Only 2 valid states (streaming or interactive)

**Validation Rules**:
- Chart MUST be in exactly one mode at any time (FR-001)
- Each chart instance manages mode independently (FR-001a per clarification Q3)
- No intermediate or transitional states (atomic transitions)

**State Transitions**:
```
streaming → interactive: Triggered by first user interaction (hover, click, zoom, pan, scroll, keyboard)
interactive → streaming: Triggered by auto-resume timeout OR manual resumeStreaming() call
```

**Relationships**:
- Used by: BravenChart widget (_chartMode ValueNotifier)
- Referenced by: StreamingConfig callbacks (onModeChanged parameter)
- Controls: Conditional rendering of interaction handlers

---

### 2. StreamingConfig (Configuration Class)

**Purpose**: Configuration object for dual-mode streaming behavior, callbacks, and constraints

**Definition**:
```dart
/// Configuration for dual-mode streaming behavior in BravenChart.
/// 
/// Controls mode transitions, buffer limits, and developer callbacks.
class StreamingConfig {
  /// Creates a streaming configuration.
  /// 
  /// All parameters optional with sensible defaults for common use cases.
  const StreamingConfig({
    this.autoResumeTimeout = const Duration(seconds: 10),
    this.maxBufferSize = 10000,
    this.pauseOnFirstInteraction = true,
    this.onModeChanged,
    this.onBufferUpdated,
    this.onReturnToLive,
    this.onStreamError,
  });
  
  /// Duration of inactivity before auto-resuming streaming mode.
  /// 
  /// Timer resets on ANY user interaction (FR-008).
  /// Default: 10 seconds (per requirement FR-007).
  final Duration autoResumeTimeout;
  
  /// Maximum number of data points to buffer during interactive mode.
  /// 
  /// When reached, chart forces immediate return to streaming mode
  /// to prevent data loss (FR-014, clarification Q5).
  /// Default: 10,000 points.
  final int maxBufferSize;
  
  /// Whether to pause streaming on first user interaction.
  /// 
  /// If false, chart starts in interactive mode and never auto-pauses.
  /// Default: true (FR-004).
  final bool pauseOnFirstInteraction;
  
  /// Callback invoked when chart mode changes.
  /// 
  /// Provides new mode for developer UI updates (FR-015).
  /// Example: Show "LIVE" indicator in streaming mode.
  final void Function(ChartMode newMode)? onModeChanged;
  
  /// Callback invoked when data is buffered in interactive mode.
  /// 
  /// Provides current buffer count (FR-016).
  /// Example: Display "142 new points" badge.
  final void Function(int bufferCount)? onBufferUpdated;
  
  /// Callback invoked to enable "Return to Live" UI.
  /// 
  /// Called when chart enters interactive mode (FR-017).
  /// Developer can show manual resume button.
  final VoidCallback? onReturnToLive;
  
  /// Callback invoked when stream errors occur.
  /// 
  /// Developer responsible for reconnection/retry logic (FR-017a, clarification Q2).
  /// Chart does NOT retry automatically.
  final void Function(Object error)? onStreamError;
}
```

**Validation Rules**:
- `autoResumeTimeout` MUST be positive duration (>0 seconds)
- `maxBufferSize` MUST be positive integer (>0 points)
- All callbacks optional (null allowed)

**Relationships**:
- Used by: BravenChart widget (constructor parameter)
- References: ChartMode enum (in onModeChanged callback)
- Controls: Timer behavior, buffer limits, developer integration

---

### 3. Buffer (Internal Implementation Detail)

**Purpose**: FIFO queue for data points that arrive during interactive mode

**Implementation**:
```dart
// Internal to BravenChart widget state
final Queue<DataPoint> _bufferedPoints = Queue<DataPoint>();
```

**Operations**:
- **Add**: `_bufferedPoints.addLast(point)` - O(1) complexity
- **Remove**: `_bufferedPoints.removeFirst()` - O(1) complexity (when applying buffer)
- **Clear**: `_bufferedPoints.clear()` - when resuming streaming
- **Size Check**: `_bufferedPoints.length` - for FR-013 enforcement

**Validation Rules**:
- MUST NOT exceed `streamingConfig.maxBufferSize` (FR-013)
- When full, MUST force return to streaming mode (FR-014, clarification Q5)
- MUST be cleared when transitioning to streaming mode (FR-011)

**Data Flow**:
```
[Streaming Data Source]
        ↓
[Chart in Interactive Mode?]
    Yes ↓           No ↓
[_bufferDataPoint]  [Apply Immediately]
        ↓
[_bufferedPoints Queue]
        ↓ (when full or timeout)
[_resumeStreaming]
        ↓
[Apply All Buffered + Clear]
```

---

### 4. Auto-Resume Timer (Internal Implementation Detail)

**Purpose**: Countdown mechanism that triggers automatic return to streaming mode

**Implementation**:
```dart
// Internal to BravenChart widget state
Timer? _autoResumeTimer;
```

**Operations**:
- **Start**: `Timer(duration, callback)` - when entering interactive mode
- **Reset**: `timer?.cancel()` + new Timer() - on ANY user interaction (FR-008)
- **Cancel**: `timer?.cancel()` - when manually resuming or entering streaming mode
- **Trigger**: Invokes `_resumeStreaming()` when timeout expires (FR-009)

**Lifecycle**:
```
[Enter Interactive Mode]
        ↓
[Start Timer: autoResumeTimeout]
        ↓
[User Interaction?]
    Yes → [Cancel + Restart Timer] → Loop
    No  ↓
[Timeout Expires]
        ↓
[Invoke _resumeStreaming()]
        ↓
[Enter Streaming Mode]
```

**Validation Rules**:
- MUST cancel on mode change (prevent stale timer callbacks)
- MUST reset on ANY interaction (hover, click, zoom, pan, scroll, keyboard per FR-004, FR-008)
- MUST NOT trigger if already in streaming mode (idempotent guard)

---

### 5. Mode Transition Event (Conceptual Entity)

**Purpose**: Represents the atomic state change between modes with cleanup and initialization

**Components**:
- **Old Mode**: ChartMode before transition
- **New Mode**: ChartMode after transition
- **Trigger**: User interaction, timeout, manual call, or buffer overflow
- **Side Effects**: Timer management, buffer application, callback invocation, viewport update

**Transition Matrix**:

| From         | To           | Trigger                     | Actions                                                      |
|--------------|--------------|----------------------------|--------------------------------------------------------------|
| streaming    | interactive  | First user interaction      | Start timer, enable interaction handlers, invoke callbacks    |
| interactive  | streaming    | Timeout expires             | Cancel timer, apply buffer, clear buffer, jump viewport       |
| interactive  | streaming    | Manual resumeStreaming()    | Cancel timer, apply buffer, clear buffer, jump viewport       |
| interactive  | streaming    | Buffer reaches maxBufferSize | Cancel timer, apply buffer, clear buffer, jump viewport       |
| streaming    | streaming    | Any call to _pauseStreaming when already streaming | No-op (idempotent guard) |
| interactive  | interactive  | Any call to _resumeStreaming when already interactive | No-op (idempotent guard) |

**State Invariants**:
- Chart MUST be in exactly one mode before and after transition
- Buffer MUST be empty in streaming mode
- Timer MUST be null in streaming mode
- Interaction handlers MUST be absent in streaming mode
- Viewport MUST show latest data after resuming streaming

---

## Entity Relationships

```
BravenChart Widget
    ├── Has: ValueNotifier<ChartMode> _chartMode
    ├── Has: StreamingConfig streamingConfig (constructor param)
    ├── Has: Queue<DataPoint> _bufferedPoints
    ├── Has: Timer? _autoResumeTimer
    │
    ├── Uses: ChartMode enum (streaming/interactive)
    ├── Uses: StreamingConfig class (configuration + callbacks)
    │
    └── Manages: Mode transitions (atomic state changes)

StreamingConfig
    ├── References: ChartMode (in onModeChanged callback)
    ├── Controls: autoResumeTimeout duration
    ├── Controls: maxBufferSize limit
    └── Provides: Developer callbacks (mode, buffer, error, return-to-live)

ChartMode enum
    ├── Used by: ValueNotifier<ChartMode>
    ├── Referenced by: onModeChanged callback
    └── Controls: Conditional rendering logic

Buffer (Queue<DataPoint>)
    ├── Populated: During interactive mode
    ├── Constrained by: streamingConfig.maxBufferSize
    ├── Applied: On transition to streaming mode
    └── Cleared: After application or on resume

Timer
    ├── Duration: streamingConfig.autoResumeTimeout
    ├── Reset by: User interactions
    ├── Triggers: _resumeStreaming() on expiration
    └── Cancelled: On manual resume or mode change
```

---

## Data Validation Rules

### ChartMode
- ✅ Only 2 valid enum values (streaming, interactive)
- ✅ No null allowed (always has value)

### StreamingConfig
- ✅ `autoResumeTimeout` > Duration.zero
- ✅ `maxBufferSize` > 0
- ✅ Callbacks nullable (optional)

### Buffer
- ✅ Length ≤ `maxBufferSize` at all times
- ✅ Empty when in streaming mode
- ✅ Contains only valid DataPoint objects (no validation per clarification Q1)

### Timer
- ✅ Null OR active (never stale)
- ✅ Null when in streaming mode
- ✅ Non-null when in interactive mode (unless manually paused)

---

## Memory Management

### Buffer Size Limits
- **Maximum**: Configurable via `maxBufferSize` (default 10,000 points)
- **Overflow Behavior**: Force resume to streaming mode (FR-014)
- **Cleanup**: Clear buffer on resume (FR-011)

### Timer Lifecycle
- **Creation**: On transition to interactive mode
- **Cancellation**: On resume, manual pause, or mode change
- **No Leaks**: Always cancelled before disposal

### ValueNotifier
- **Listeners**: ValueListenableBuilder automatically manages subscription
- **Disposal**: Dispose in BravenChart.dispose()

---

## Performance Characteristics

### Mode Transitions
- **Complexity**: O(1) for state change
- **Latency**: <50ms target (SC-002)
- **Overhead**: Callback invocation only

### Buffer Operations
- **Add**: O(1) using Queue.addLast()
- **Apply**: O(n) where n = buffer size (max 10K points)
- **Clear**: O(1) using Queue.clear()

### Timer Operations
- **Start**: O(1)
- **Cancel**: O(1)
- **Reset**: O(1) (cancel + start)

---

## State Machine Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    BravenChart State                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐                ┌──────────────────┐   │
│  │   STREAMING     │                │   INTERACTIVE    │   │
│  │                 │                │                  │   │
│  │ - Auto-scroll   │                │ - Timer active   │   │
│  │ - No handlers   │                │ - Full interact  │   │
│  │ - No buffer     │                │ - Data buffered  │   │
│  └────────┬────────┘                └────────┬─────────┘   │
│           │                                  │             │
│           │  [User Interaction]              │             │
│           │  (hover/click/zoom/pan/scroll)   │             │
│           └──────────────────►───────────────┘             │
│                                                             │
│           ┌──────────────────◄───────────────┐             │
│           │  [Timeout OR Manual Resume       │             │
│           │   OR Buffer Full]                │             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**State Invariants**:
- Exactly one mode active at any time
- Transitions are atomic (no intermediate states)
- Side effects complete before mode change

---

## API Surface (Public vs Internal)

### Public API (Exposed to Developers)

**StreamingConfig class**:
- Constructor with all parameters
- Public fields (all final, immutable)

**ChartMode enum**:
- Public values: `streaming`, `interactive`
- Exposed in callbacks only (not directly manipulated by developer)

**BravenChart widget**:
- Constructor parameter: `StreamingConfig? streamingConfig`
- Public method: `void resumeStreaming()` (FR-010)

### Internal API (Private to BravenChart)

**State management**:
- `ValueNotifier<ChartMode> _chartMode`
- `Queue<DataPoint> _bufferedPoints`
- `Timer? _autoResumeTimer`

**Methods**:
- `void _pauseStreaming()`
- `void _resumeStreaming()`
- `void _resetAutoResumeTimer()`
- `void _bufferDataPoint(DataPoint point)`
- `void _applyBufferedData()`
- `void _jumpToLatestData()`
- `void _handleInteraction()`

---

## Migration Impact

### Backward Compatibility Strategy

**Non-streaming charts** (existing behavior):
```dart
BravenChart(
  data: staticData,
  chartType: ChartType.line,
)
// No streamingConfig needed
// Chart operates in traditional mode (always interactive)
```

**Streaming charts** (new feature):
```dart
BravenChart(
  data: streamController.stream,
  chartType: ChartType.line,
  streamingConfig: StreamingConfig(), // Required for streaming
)
```

**Detection Logic**:
```dart
// In BravenChart.initState()
if (widget.data is Stream && widget.streamingConfig == null) {
  throw ArgumentError(
    'streamingConfig required when data is a Stream. '
    'Provide StreamingConfig to enable dual-mode behavior.'
  );
}

final initialMode = widget.streamingConfig != null
    ? ChartMode.streaming  // Start in streaming if configured
    : ChartMode.interactive; // Traditional mode if not configured
```

---

**Status**: ✅ Data model complete. Ready for contract generation and quickstart documentation.
