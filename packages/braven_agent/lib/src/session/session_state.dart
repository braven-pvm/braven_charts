import 'package:equatable/equatable.dart';

import '../llm/models/agent_message.dart';
import '../models/chart_configuration.dart';

/// Activity status of an agent session.
///
/// Used by UI to determine what to display:
/// - [idle]: Ready for user input
/// - [thinking]: Show loading spinner
/// - [calling_tool]: Show tool execution indicator
/// - [error]: Display error state
enum ActivityStatus {
  /// Session is ready for user input.
  idle,

  /// Agent is processing/thinking.
  thinking,

  /// Agent is executing a tool.
  // ignore: constant_identifier_names
  calling_tool,

  /// An error occurred.
  error,
}

/// Represents an in-progress tool execution.
///
/// Tracks the current tool being called by the LLM, including
/// the tool call ID (for correlation), name, and input parameters.
///
/// ## Example
///
/// ```dart
/// final toolCall = ToolCall(
///   id: 'toolu_123',
///   name: 'create_chart',
///   input: {'type': 'line', 'title': 'Sales'},
/// );
/// print(toolCall.name); // 'create_chart'
/// ```
class ToolCall with EquatableMixin {
  /// Unique identifier for this tool call from the LLM.
  final String id;

  /// Name of the tool being executed (e.g., 'create_chart').
  final String name;

  /// Input parameters for the tool as a JSON-compatible map.
  final Map<String, dynamic> input;

  /// Creates a [ToolCall] with the given [id], [name], and [input].
  const ToolCall({
    required this.id,
    required this.name,
    required this.input,
  });

  @override
  List<Object?> get props => [id, name, input];

  @override
  String toString() => 'ToolCall(id: $id, name: $name)';
}

/// Immutable snapshot of agent session state.
///
/// Represents the complete state of an agent session at a point in time.
/// Used with [ValueListenable] for reactive UI updates.
///
/// ## State Fields
///
/// - [history]: Complete conversation history
/// - [pendingResponse]: Message being streamed (for typing effect)
/// - [activeTool]: Currently executing tool
/// - [status]: Current activity status
/// - [activeChart]: The chart relevant to the conversation
/// - [errorMessage]: Last error message if status is error
///
/// ## Example
///
/// ```dart
/// // Initial state
/// final state = SessionState();
/// print(state.status); // ActivityStatus.idle
/// print(state.history); // []
///
/// // Update state immutably
/// final updated = state.copyWith(
///   status: ActivityStatus.thinking,
/// );
/// ```
///
/// ## UI Binding
///
/// ```dart
/// ValueListenableBuilder<SessionState>(
///   valueListenable: session.state,
///   builder: (context, state, _) {
///     if (state.status == ActivityStatus.thinking) {
///       return CircularProgressIndicator();
///     }
///     if (state.activeChart != null) {
///       return ChartRenderer().render(state.activeChart!);
///     }
///     return Text('Ask me to create a chart!');
///   },
/// )
/// ```
class SessionState with EquatableMixin {
  /// Complete conversation history.
  ///
  /// Contains all messages exchanged in this session.
  final List<AgentMessage> history;

  /// Message currently being streamed.
  ///
  /// Used for typing effect in UI. Null when not streaming.
  final AgentMessage? pendingResponse;

  /// Currently executing tool.
  ///
  /// Null when no tool is being executed.
  final ToolCall? activeTool;

  /// Current activity status.
  final ActivityStatus status;

  /// The chart relevant to the current conversation.
  ///
  /// Updated when charts are created or modified.
  final ChartConfiguration? activeChart;

  /// Last error message if status is [ActivityStatus.error].
  final String? errorMessage;

  /// Creates a [SessionState] with sensible defaults.
  ///
  /// Default state is idle with empty history and no active chart.
  const SessionState({
    this.history = const [],
    this.pendingResponse,
    this.activeTool,
    this.status = ActivityStatus.idle,
    this.activeChart,
    this.errorMessage,
  });

  /// Creates a copy of this [SessionState] with optionally overridden values.
  ///
  /// If a parameter is not provided, the original value is preserved.
  SessionState copyWith({
    List<AgentMessage>? history,
    AgentMessage? pendingResponse,
    ToolCall? activeTool,
    ActivityStatus? status,
    ChartConfiguration? activeChart,
    String? errorMessage,
  }) {
    return SessionState(
      history: history ?? this.history,
      pendingResponse: pendingResponse ?? this.pendingResponse,
      activeTool: activeTool ?? this.activeTool,
      status: status ?? this.status,
      activeChart: activeChart ?? this.activeChart,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Creates a copy with nullable fields explicitly cleared.
  ///
  /// Use this when you need to set nullable fields to null.
  ///
  /// ```dart
  /// final cleared = state.copyWithCleared(
  ///   clearPendingResponse: true,
  ///   clearActiveTool: true,
  ///   clearErrorMessage: true,
  /// );
  /// ```
  SessionState copyWithCleared({
    List<AgentMessage>? history,
    AgentMessage? pendingResponse,
    bool clearPendingResponse = false,
    ToolCall? activeTool,
    bool clearActiveTool = false,
    ActivityStatus? status,
    ChartConfiguration? activeChart,
    bool clearActiveChart = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SessionState(
      history: history ?? this.history,
      pendingResponse: clearPendingResponse
          ? null
          : (pendingResponse ?? this.pendingResponse),
      activeTool: clearActiveTool ? null : (activeTool ?? this.activeTool),
      status: status ?? this.status,
      activeChart: clearActiveChart ? null : (activeChart ?? this.activeChart),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        history,
        pendingResponse,
        activeTool,
        status,
        activeChart,
        errorMessage,
      ];

  @override
  String toString() =>
      'SessionState(status: $status, history: ${history.length} messages, activeChart: ${activeChart != null})';
}
