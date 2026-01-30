import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../llm/llm_provider.dart';
import '../llm/models/agent_message.dart';
import '../llm/models/message_content.dart';
import '../models/chart_configuration.dart';
import '../tools/agent_tool.dart';
import 'agent_events.dart';
import 'agent_session.dart';
import 'session_state.dart';

/// Concrete implementation of [AgentSession].
///
/// Orchestrates conversation state management, event emission, LLM
/// communication, and tool execution for the chart creation agent.
///
/// ## Architecture
///
/// This implementation:
/// - Manages state via `ValueNotifier<SessionState>`
/// - Emits events via `StreamController<AgentEvent>.broadcast()`
/// - Delegates LLM communication to the injected [LLMProvider]
/// - Executes tools from the provided [AgentTool] list
///
/// ## Dependencies
///
/// - [llmProvider]: Handles LLM API communication
/// - [tools]: Available tools for the agent to invoke
/// - [systemPrompt]: Instructions for the LLM's behavior
///
/// ## Example
///
/// ```dart
/// final session = AgentSessionImpl(
///   llmProvider: AnthropicAdapter(config),
///   tools: [createChartTool, modifyChartTool],
///   systemPrompt: defaultSystemPrompt,
/// );
///
/// // Listen to state changes
/// session.state.addListener(() {
///   print('Status: ${session.state.value.status}');
/// });
///
/// // Process a prompt
/// await session.transform('Create a line chart');
///
/// // Dispose when done
/// session.dispose();
/// ```
class AgentSessionImpl implements AgentSession {
  /// The LLM provider for API communication.
  final LLMProvider _llmProvider;

  /// Available tools for the agent.
  final List<AgentTool> _tools;

  /// System prompt for the LLM.
  final String _systemPrompt;

  /// State notifier for reactive UI updates.
  final ValueNotifier<SessionState> _state = ValueNotifier<SessionState>(const SessionState());

  /// Stream controller for emitting events.
  final StreamController<AgentEvent> _eventController = StreamController<AgentEvent>.broadcast();

  /// UUID generator for message IDs.
  static const Uuid _uuid = Uuid();

  /// Whether this session has been disposed.
  bool _disposed = false;

  /// Creates an [AgentSessionImpl] with the required dependencies.
  ///
  /// - [llmProvider]: The LLM provider for API communication.
  /// - [tools]: List of tools available to the agent.
  /// - [systemPrompt]: Instructions for the LLM's behavior.
  AgentSessionImpl({
    required LLMProvider llmProvider,
    required List<AgentTool> tools,
    required String systemPrompt,
  })  : _llmProvider = llmProvider,
        _tools = tools,
        _systemPrompt = systemPrompt;

  @override
  ValueListenable<SessionState> get state => _state;

  @override
  Stream<AgentEvent> get events => _eventController.stream;

  @override
  Future<void> transform(
    String prompt, {
    List<BinaryContent>? attachments,
  }) async {
    if (_disposed) return;

    try {
      // Set status to thinking and emit event
      _updateState(status: ActivityStatus.thinking);
      _eventController.add(const ThinkingEvent(
        description: 'Processing your request...',
      ));

      // Create user message with prompt and optional attachments
      final userContent = <MessageContent>[
        TextContent(text: prompt),
        if (attachments != null) ...attachments,
      ];

      final userMessage = AgentMessage(
        id: _uuid.v4(),
        role: MessageRole.user,
        content: userContent,
        timestamp: DateTime.now(),
      );

      // Add user message to history
      _updateState(history: [..._state.value.history, userMessage]);

      // Start the agentic loop
      await _processLLMResponse();
    } catch (e) {
      // Handle errors gracefully - don't throw
      _handleError(e);
    }
  }

  /// Processes LLM responses in an agentic loop until completion.
  Future<void> _processLLMResponse() async {
    while (!_disposed) {
      try {
        // Call LLM with current history
        final response = await _llmProvider.generateResponse(
          systemPrompt: _systemPrompt,
          history: _state.value.history,
          tools: _tools.isNotEmpty ? _tools : null,
        );

        // Check for tool use in response
        final toolUseContents = response.message.content.whereType<ToolUseContent>().toList();

        if (toolUseContents.isNotEmpty) {
          // Add assistant message with tool use to history
          _updateState(history: [..._state.value.history, response.message]);

          // Execute each tool
          for (final toolUse in toolUseContents) {
            await _executeTool(toolUse);
          }

          // Continue the loop for next LLM response
          continue;
        }

        // No tool use - add assistant message to history and complete
        _updateState(
          history: [..._state.value.history, response.message],
          status: ActivityStatus.idle,
        );
        return;
      } catch (e) {
        _handleError(e);
        return;
      }
    }
  }

  /// Executes a tool and handles the result.
  Future<void> _executeTool(ToolUseContent toolUse) async {
    // Set status to calling_tool
    _updateState(
      status: ActivityStatus.calling_tool,
      activeTool: ToolCall(
        id: toolUse.id,
        name: toolUse.toolName,
        input: toolUse.input,
      ),
    );

    // Emit tool start event
    _eventController.add(ToolStartEvent(toolName: toolUse.toolName));

    // Find the tool
    final tool = _tools.firstWhere(
      (t) => t.name == toolUse.toolName,
      orElse: () => throw StateError('Tool not found: ${toolUse.toolName}'),
    );

    bool success = true;
    String toolOutput = '';
    bool isError = false;

    try {
      // Execute the tool
      final result = await tool.execute(toolUse.input);
      toolOutput = result.output;
      isError = result.isError;
      success = !isError;

      // Handle chart configuration in tool result
      if (!isError && result.data is ChartConfiguration) {
        final chart = result.data! as ChartConfiguration;
        final existingChart = _state.value.activeChart;

        // Determine if this is a new chart or an update
        if (existingChart == null || existingChart.id != chart.id) {
          // New chart created
          _eventController.add(ChartCreatedEvent(config: chart));
        } else {
          // Existing chart updated
          _eventController.add(ChartUpdatedEvent(config: chart));
        }

        // Update active chart
        _updateState(activeChart: chart);
      }
    } catch (e) {
      success = false;
      toolOutput = 'Error: $e';
      isError = true;
    }

    // Emit tool end event
    _eventController.add(ToolEndEvent(
      toolName: toolUse.toolName,
      success: success,
    ));

    // Clear active tool
    _updateStateClearingActiveTool();

    // Create tool result message and add to history
    final toolResultContent = ToolResultContent(
      toolUseId: toolUse.id,
      output: toolOutput,
      isError: isError,
    );

    final toolResultMessage = AgentMessage(
      id: _uuid.v4(),
      role: MessageRole.tool,
      content: [toolResultContent],
      timestamp: DateTime.now(),
    );

    _updateState(history: [..._state.value.history, toolResultMessage]);
  }

  /// Adds a chart snapshot to the message history.
  ///
  /// Call this method from your UI after capturing a chart image using
  /// [ChartSnapshotService.captureFromBoundary] or [ChartSnapshotWrapper].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // In your chart widget
  /// final _snapshotKey = GlobalKey<ChartSnapshotWrapperState>();
  ///
  /// ChartSnapshotWrapper(
  ///   key: _snapshotKey,
  ///   child: ChartRenderer().render(config),
  /// )
  ///
  /// // After chart is rendered, capture and add to history
  /// final imageContent = await _snapshotKey.currentState?.capture();
  /// if (imageContent != null) {
  ///   session.addChartSnapshot(imageContent);
  /// }
  /// ```
  @override
  void addChartSnapshot(ImageContent imageContent, {String? title}) {
    if (_disposed) return;

    final chart = _state.value.activeChart;
    final snapshotTitle = title ?? chart?.title ?? chart?.id ?? 'Chart';

    final snapshotMessage = AgentMessage(
      id: _uuid.v4(),
      role: MessageRole.system,
      content: [
        TextContent(text: '📊 $snapshotTitle'),
        imageContent,
      ],
      timestamp: DateTime.now(),
      metadata: {
        if (chart?.id != null) 'chartId': chart!.id,
        'snapshotType': 'chart_preview',
      },
    );

    _updateState(history: [..._state.value.history, snapshotMessage]);
  }

  /// Handles errors by setting state and emitting events.
  void _handleError(Object error) {
    final message = error is Exception ? error.toString().replaceFirst('Exception: ', '') : error.toString();

    _state.value = _state.value.copyWithCleared(
      status: ActivityStatus.error,
      errorMessage: message,
      clearActiveTool: true,
    );

    _eventController.add(ErrorEvent(
      message: message,
      originalError: error,
    ));
  }

  /// Updates state immutably.
  void _updateState({
    List<AgentMessage>? history,
    AgentMessage? pendingResponse,
    ToolCall? activeTool,
    ActivityStatus? status,
    ChartConfiguration? activeChart,
    String? errorMessage,
  }) {
    _state.value = _state.value.copyWith(
      history: history,
      pendingResponse: pendingResponse,
      activeTool: activeTool,
      status: status,
      activeChart: activeChart,
      errorMessage: errorMessage,
    );
  }

  /// Updates state while clearing activeTool.
  void _updateStateClearingActiveTool({
    List<AgentMessage>? history,
    ActivityStatus? status,
    ChartConfiguration? activeChart,
  }) {
    _state.value = _state.value.copyWithCleared(
      history: history,
      status: status,
      activeChart: activeChart,
      clearActiveTool: true,
    );
  }

  @override
  void updateChart(ChartConfiguration newConfig) {
    if (_disposed) return;

    _updateState(activeChart: newConfig);
    _eventController.add(ChartUpdatedEvent(config: newConfig));
  }

  @override
  Future<void> cancel() async {
    if (_disposed) return;

    _state.value = _state.value.copyWithCleared(
      status: ActivityStatus.idle,
      clearActiveTool: true,
    );

    _eventController.add(const CancelledEvent());
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _eventController.close();
    _state.dispose();
  }
}
