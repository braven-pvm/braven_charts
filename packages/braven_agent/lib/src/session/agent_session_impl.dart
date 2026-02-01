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

  /// Enable verbose debug logging for tracing agent behavior.
  final bool debugLogging;

  /// Creates an [AgentSessionImpl] with the required dependencies.
  ///
  /// - [llmProvider]: The LLM provider for API communication.
  /// - [tools]: List of tools available to the agent.
  /// - [systemPrompt]: Instructions for the LLM's behavior.
  /// - [debugLogging]: Enable verbose console logging for debugging.
  AgentSessionImpl({
    required LLMProvider llmProvider,
    required List<AgentTool> tools,
    required String systemPrompt,
    this.debugLogging = false,
  })  : _llmProvider = llmProvider,
        _tools = tools,
        _systemPrompt = systemPrompt;

  void _log(String message) {
    if (debugLogging) {
      debugPrint('[AgentSession] $message');
    }
  }

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

    _log('========================================');
    _log('TRANSFORM CALLED');
    _log('User prompt: $prompt');
    _log('Attachments: ${attachments?.length ?? 0}');
    _log('========================================');

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
      _log('Added user message to history. Total messages: ${_state.value.history.length}');

      // Start the agentic loop
      await _processLLMResponse();
    } catch (e) {
      // Handle errors gracefully - don't throw
      _handleError(e);
    }
  }

  /// Maximum iterations allowed in the agentic loop to prevent infinite loops.
  static const int _maxIterations = 10;

  /// Processes LLM responses in an agentic loop until completion.
  Future<void> _processLLMResponse() async {
    int loopIteration = 0;
    String? lastFailedToolInput;
    int consecutiveIdenticalFailures = 0;

    while (!_disposed) {
      loopIteration++;
      _log('--- LLM Loop Iteration $loopIteration ---');

      // Check for max iterations
      if (loopIteration > _maxIterations) {
        _log('ERROR: Max iterations ($_maxIterations) exceeded - breaking loop');
        _updateState(status: ActivityStatus.idle);
        _eventController.add(ErrorEvent(
          message:
              'The agent exceeded the maximum number of iterations ($_maxIterations). This usually indicates the model is not learning from errors.',
          originalError: Exception('Maximum iterations exceeded'),
        ));
        return;
      }

      try {
        // Call LLM with current history
        _log('Calling LLM with ${_state.value.history.length} messages in history');
        final response = await _llmProvider.generateResponse(
          systemPrompt: _systemPrompt,
          history: _state.value.history,
          tools: _tools.isNotEmpty ? _tools : null,
        );

        // Log the LLM response
        _log('LLM Response received:');
        _log('  Stop reason: ${response.stopReason}');
        _log('  Content items: ${response.message.content.length}');
        for (final content in response.message.content) {
          if (content is TextContent) {
            _log('  [TEXT]: ${content.text.length > 200 ? "${content.text.substring(0, 200)}..." : content.text}');
          } else if (content is ToolUseContent) {
            _log('  [TOOL_USE]: ${content.toolName}');
            _log('    ID: ${content.id}');
            _log('    Input: ${content.input}');
          } else {
            _log('  [OTHER]: ${content.runtimeType}');
          }
        }

        // Check for tool use in response
        final toolUseContents = response.message.content.whereType<ToolUseContent>().toList();

        if (toolUseContents.isNotEmpty) {
          _log('Found ${toolUseContents.length} tool use(s) - executing...');
          // Add assistant message with tool use to history
          _updateState(history: [..._state.value.history, response.message]);

          // Execute each tool and track repeated failures
          for (final toolUse in toolUseContents) {
            final inputSignature = '${toolUse.toolName}:${toolUse.input.toString()}';
            final result = await _executeToolWithResult(toolUse);

            if (result.isError) {
              if (inputSignature == lastFailedToolInput) {
                consecutiveIdenticalFailures++;
                _log('WARNING: Identical failure detected ($consecutiveIdenticalFailures consecutive)');

                if (consecutiveIdenticalFailures >= 3) {
                  _log('ERROR: 3 consecutive identical failures - breaking loop');
                  _updateState(status: ActivityStatus.idle);
                  _eventController.add(ErrorEvent(
                    message:
                        'The model made the same failing request 3 times without learning from the error. Please try rephrasing your request or providing more specific instructions.',
                    originalError: Exception('Agent stuck in loop'),
                  ));
                  return;
                }
              } else {
                lastFailedToolInput = inputSignature;
                consecutiveIdenticalFailures = 1;
              }
            } else {
              // Success - reset failure tracking
              lastFailedToolInput = null;
              consecutiveIdenticalFailures = 0;
            }
          }

          // Continue the loop for next LLM response
          _log('Continuing agentic loop...');
          continue;
        }

        // No tool use - add assistant message to history and complete
        _log('No tool use - completing response');
        _updateState(
          history: [..._state.value.history, response.message],
          status: ActivityStatus.idle,
        );
        _log('========================================');
        _log('TRANSFORM COMPLETE');
        _log('========================================');
        return;
      } catch (e) {
        _log('ERROR in LLM loop: $e');
        _handleError(e);
        return;
      }
    }
  }

  /// Executes a tool and handles the result. Returns whether it was an error.
  Future<({bool isError, String output})> _executeToolWithResult(ToolUseContent toolUse) async {
    _log('>>> TOOL EXECUTION START: ${toolUse.toolName}');
    _log('    Tool ID: ${toolUse.id}');
    _log('    Input: ${toolUse.input}');

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
    _log('    Found tool: ${tool.name}');

    bool success = true;
    String toolOutput = '';
    bool isError = false;

    try {
      // Execute the tool
      _log('    Executing tool...');
      final result = await tool.execute(toolUse.input);
      toolOutput = result.output;
      isError = result.isError;
      success = !isError;

      _log('    Tool result:');
      _log('      isError: $isError');
      _log('      output: ${toolOutput.length > 500 ? "${toolOutput.substring(0, 500)}..." : toolOutput}');
      _log('      data type: ${result.data?.runtimeType ?? "null"}');

      // Handle chart configuration in tool result
      if (!isError && result.data is ChartConfiguration) {
        final chart = result.data! as ChartConfiguration;
        _log('      Chart config received:');
        _log('        id: ${chart.id}');
        _log('        series: ${chart.series.length}');
        _log('        annotations: ${chart.annotations.length}');

        final existingChart = _state.value.activeChart;

        // Determine if this is a new chart or an update
        if (existingChart == null || existingChart.id != chart.id) {
          // New chart created
          _log('      Emitting ChartCreatedEvent');
          _eventController.add(ChartCreatedEvent(config: chart));
        } else {
          // Existing chart updated
          _log('      Emitting ChartUpdatedEvent');
          _eventController.add(ChartUpdatedEvent(config: chart));
        }

        // Update active chart
        _updateState(activeChart: chart);
      }
    } catch (e, stack) {
      _log('    TOOL ERROR: $e');
      _log('    Stack: $stack');
      success = false;
      toolOutput = 'Error: $e';
      isError = true;
    }

    _log('<<< TOOL EXECUTION END: ${toolUse.toolName} (success: $success)');

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
      toolName: toolUse.toolName,
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

    return (isError: isError, output: toolOutput);
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
