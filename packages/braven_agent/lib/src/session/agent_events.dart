import '../models/chart_configuration.dart';

/// Sealed class hierarchy for agent session events.
///
/// Events are discrete signals for side effects like persistence,
/// toast notifications, and navigation. Subscribe to these events
/// for business logic that shouldn't be in the UI layer.
///
/// ## Pattern Matching Example
///
/// ```dart
/// session.events.listen((event) {
///   switch (event) {
///     case ChartCreatedEvent(:final config):
///       database.insertChart(config);
///       showSnackbar('Chart created!');
///     case ChartUpdatedEvent(:final config):
///       database.updateChart(config.id!, config);
///     case ErrorEvent(:final message):
///       showErrorDialog(message);
///     case ThinkingEvent(:final description):
///       debugPrint('Agent: $description');
///     case ToolStartEvent(:final toolName):
///       debugPrint('Executing: $toolName');
///     case ToolEndEvent(:final toolName, :final success):
///       debugPrint('$toolName ${success ? 'succeeded' : 'failed'}');
///     case CancelledEvent():
///       showSnackbar('Request cancelled');
///   }
/// });
/// ```
sealed class AgentEvent {
  /// Base constructor for [AgentEvent].
  const AgentEvent();
}

/// Event emitted when a new chart is created.
///
/// Contains the complete [ChartConfiguration] for the newly created chart.
///
/// ## Example
///
/// ```dart
/// session.events.listen((event) {
///   if (event is ChartCreatedEvent) {
///     await database.insertChart(event.config);
///     showSnackbar('Chart "${event.config.title}" created!');
///   }
/// });
/// ```
final class ChartCreatedEvent extends AgentEvent {
  /// The configuration of the created chart.
  final ChartConfiguration config;

  /// Creates a [ChartCreatedEvent] with the given [config].
  const ChartCreatedEvent({required this.config});

  @override
  String toString() => 'ChartCreatedEvent(chartId: ${config.id})';
}

/// Event emitted when an existing chart is updated.
///
/// Contains the updated [ChartConfiguration] with all modifications applied.
///
/// ## Example
///
/// ```dart
/// session.events.listen((event) {
///   if (event is ChartUpdatedEvent) {
///     await database.updateChart(event.config.id!, event.config);
///   }
/// });
/// ```
final class ChartUpdatedEvent extends AgentEvent {
  /// The updated configuration of the chart.
  final ChartConfiguration config;

  /// Creates a [ChartUpdatedEvent] with the given [config].
  const ChartUpdatedEvent({required this.config});

  @override
  String toString() => 'ChartUpdatedEvent(chartId: ${config.id})';
}

/// Event emitted when an error occurs.
///
/// Contains a human-readable [message] and optionally the [originalError]
/// for debugging and logging purposes.
///
/// ## Example
///
/// ```dart
/// session.events.listen((event) {
///   if (event is ErrorEvent) {
///     showErrorDialog(event.message);
///     if (event.originalError != null) {
///       logger.error('Agent error', error: event.originalError);
///     }
///   }
/// });
/// ```
final class ErrorEvent extends AgentEvent {
  /// Human-readable error message.
  final String message;

  /// The original error object, if available.
  ///
  /// Useful for debugging and logging. May be an [Exception],
  /// [Error], or other error type.
  final Object? originalError;

  /// Creates an [ErrorEvent] with the given [message] and optional [originalError].
  const ErrorEvent({
    required this.message,
    this.originalError,
  });

  @override
  String toString() =>
      'ErrorEvent(message: $message, hasOriginal: ${originalError != null})';
}

/// Event emitted when the agent is thinking/processing.
///
/// Contains a [description] of what the agent is currently doing.
/// Useful for updating status indicators in the UI.
///
/// ## Example
///
/// ```dart
/// session.events.listen((event) {
///   if (event is ThinkingEvent) {
///     updateStatusBar(event.description);
///   }
/// });
/// ```
final class ThinkingEvent extends AgentEvent {
  /// Description of what the agent is processing.
  ///
  /// Examples: 'Processing your request...', 'Analyzing data...'
  final String description;

  /// Creates a [ThinkingEvent] with the given [description].
  const ThinkingEvent({required this.description});

  @override
  String toString() => 'ThinkingEvent(description: $description)';
}

/// Event emitted when a tool starts executing.
///
/// Marks the beginning of a tool execution lifecycle.
/// Paired with [ToolEndEvent] for tracking tool duration and success.
///
/// ## Example
///
/// ```dart
/// session.events.listen((event) {
///   if (event is ToolStartEvent) {
///     showToolIndicator(event.toolName);
///   }
/// });
/// ```
final class ToolStartEvent extends AgentEvent {
  /// Name of the tool that started executing.
  final String toolName;

  /// Creates a [ToolStartEvent] with the given [toolName].
  const ToolStartEvent({required this.toolName});

  @override
  String toString() => 'ToolStartEvent(toolName: $toolName)';
}

/// Event emitted when a tool finishes executing.
///
/// Marks the end of a tool execution lifecycle.
/// Contains whether the tool execution was successful.
///
/// ## Example
///
/// ```dart
/// session.events.listen((event) {
///   if (event is ToolEndEvent) {
///     hideToolIndicator();
///     if (!event.success) {
///       showWarning('Tool ${event.toolName} failed');
///     }
///   }
/// });
/// ```
final class ToolEndEvent extends AgentEvent {
  /// Name of the tool that finished executing.
  final String toolName;

  /// Whether the tool execution was successful.
  final bool success;

  /// Creates a [ToolEndEvent] with the given [toolName] and [success] status.
  const ToolEndEvent({
    required this.toolName,
    required this.success,
  });

  @override
  String toString() => 'ToolEndEvent(toolName: $toolName, success: $success)';
}

/// Event emitted when a request is cancelled.
///
/// Signals that an in-progress operation was cancelled by the user
/// or system. Used to update UI and clean up resources.
///
/// ## Example
///
/// ```dart
/// session.events.listen((event) {
///   if (event is CancelledEvent) {
///     showSnackbar('Request cancelled');
///     resetUI();
///   }
/// });
/// ```
final class CancelledEvent extends AgentEvent {
  /// Creates a [CancelledEvent].
  const CancelledEvent();

  @override
  String toString() => 'CancelledEvent()';
}
