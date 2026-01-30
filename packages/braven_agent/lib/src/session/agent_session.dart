import 'package:flutter/foundation.dart';

import '../llm/models/message_content.dart';
import '../models/chart_configuration.dart';
import 'agent_events.dart';
import 'session_state.dart';

/// Abstract interface for agent-based chart conversations.
///
/// [AgentSession] is the core interface for interacting with an LLM-powered
/// chart creation assistant. It abstracts the underlying LLM provider, tools,
/// and conversation state management into a clean API for consumers.
///
/// ## Architecture
///
/// The session provides:
/// - **Reactive state** via [ValueListenable] for UI binding
/// - **Event stream** for side effects like persistence and notifications
/// - **Transform method** for sending prompts and processing responses
/// - **Chart synchronization** for UI-edited chart updates
/// - **Lifecycle management** for cancellation and cleanup
///
/// ## State Management
///
/// The [state] property exposes a [ValueListenable] that emits [SessionState]
/// updates. UI components can bind to this for reactive updates:
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
///
/// ## Event Handling
///
/// The [events] stream emits [AgentEvent]s for side effects that shouldn't
/// be handled in the UI layer:
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
///     case CancelledEvent():
///       showSnackbar('Request cancelled');
///     // Handle other events...
///   }
/// });
/// ```
///
/// ## Sending Prompts
///
/// Use [transform] to send user prompts and optionally attach binary content:
///
/// ```dart
/// // Simple text prompt
/// await session.transform('Create a line chart showing sales by month');
///
/// // Prompt with image attachment (for vision models)
/// await session.transform(
///   'Create a chart based on this data',
///   attachments: [
///     BinaryContent(
///       data: base64ImageData,
///       mimeType: 'image/png',
///       filename: 'data.png',
///     ),
///   ],
/// );
/// ```
///
/// ## Chart Synchronization
///
/// When users edit charts directly in the UI (e.g., drag to reorder series),
/// use [updateChart] to sync changes back to the session:
///
/// ```dart
/// // User reordered series in the UI
/// final updatedConfig = config.copyWith(
///   series: reorderedSeries,
/// );
/// session.updateChart(updatedConfig);
/// ```
///
/// ## Lifecycle
///
/// Always dispose of sessions when done to release resources:
///
/// ```dart
/// @override
/// void dispose() {
///   session.dispose();
///   super.dispose();
/// }
/// ```
///
/// ## Example: Complete Usage
///
/// ```dart
/// class ChartScreen extends StatefulWidget {
///   @override
///   _ChartScreenState createState() => _ChartScreenState();
/// }
///
/// class _ChartScreenState extends State<ChartScreen> {
///   late final AgentSession session;
///   late final StreamSubscription<AgentEvent> _eventSub;
///
///   @override
///   void initState() {
///     super.initState();
///     session = createSession(); // Implementation-specific
///     _eventSub = session.events.listen(_handleEvent);
///   }
///
///   void _handleEvent(AgentEvent event) {
///     if (event is ErrorEvent) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(event.message)),
///       );
///     }
///   }
///
///   Future<void> _sendMessage(String text) async {
///     await session.transform(text);
///   }
///
///   @override
///   void dispose() {
///     _eventSub.cancel();
///     session.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ValueListenableBuilder<SessionState>(
///       valueListenable: session.state,
///       builder: (context, state, _) {
///         return ChartView(state: state);
///       },
///     );
///   }
/// }
/// ```
abstract class AgentSession {
  /// Reactive state of the session.
  ///
  /// Returns a [ValueListenable] that emits [SessionState] updates whenever
  /// the session state changes. Use this with [ValueListenableBuilder] for
  /// reactive UI updates.
  ///
  /// The state includes:
  /// - [SessionState.history]: Complete conversation history
  /// - [SessionState.pendingResponse]: Message being streamed
  /// - [SessionState.activeTool]: Currently executing tool
  /// - [SessionState.status]: Current activity status
  /// - [SessionState.activeChart]: The chart relevant to the conversation
  /// - [SessionState.errorMessage]: Last error if status is error
  ///
  /// ## Example
  ///
  /// ```dart
  /// ValueListenableBuilder<SessionState>(
  ///   valueListenable: session.state,
  ///   builder: (context, state, _) {
  ///     return switch (state.status) {
  ///       ActivityStatus.idle => IdleView(),
  ///       ActivityStatus.thinking => LoadingView(),
  ///       ActivityStatus.calling_tool => ToolView(state.activeTool),
  ///       ActivityStatus.error => ErrorView(state.errorMessage),
  ///     };
  ///   },
  /// )
  /// ```
  ValueListenable<SessionState> get state;

  /// Stream of discrete events for side effects.
  ///
  /// Events are emitted for actions that require handling outside the UI
  /// layer, such as:
  /// - Persisting charts to a database
  /// - Showing toast notifications
  /// - Logging and analytics
  /// - Navigation
  ///
  /// The stream is broadcast, allowing multiple listeners.
  ///
  /// ## Event Types
  ///
  /// - [ChartCreatedEvent]: New chart was created
  /// - [ChartUpdatedEvent]: Existing chart was modified
  /// - [ErrorEvent]: An error occurred
  /// - [ThinkingEvent]: Agent is processing
  /// - [ToolStartEvent]: Tool execution started
  /// - [ToolEndEvent]: Tool execution finished
  /// - [CancelledEvent]: Operation was cancelled
  ///
  /// ## Example
  ///
  /// ```dart
  /// final subscription = session.events.listen((event) {
  ///   switch (event) {
  ///     case ChartCreatedEvent(:final config):
  ///       database.insertChart(config);
  ///     case ErrorEvent(:final message, :final originalError):
  ///       logger.error(message, error: originalError);
  ///     // ...
  ///   }
  /// });
  ///
  /// // Remember to cancel when done
  /// subscription.cancel();
  /// ```
  Stream<AgentEvent> get events;

  /// Sends a user prompt to the agent for processing.
  ///
  /// This is the primary method for interacting with the agent. It:
  /// 1. Adds the user message to conversation history
  /// 2. Sends the prompt to the LLM
  /// 3. Processes the LLM response (including tool calls)
  /// 4. Updates state reactively throughout the process
  /// 5. Emits events for side effects
  ///
  /// The [prompt] is the user's natural language request, such as
  /// "Create a line chart showing temperature over time".
  ///
  /// The optional [attachments] parameter allows sending binary content
  /// like images for vision-capable LLMs. Each attachment should be a
  /// [BinaryContent] with the data, MIME type, and optional filename.
  ///
  /// The method completes when the entire request/response cycle is done,
  /// including any tool calls and their results.
  ///
  /// ## Parameters
  ///
  /// - [prompt]: The user's natural language request
  /// - [attachments]: Optional binary content (images, files) to include
  ///
  /// ## State Changes
  ///
  /// During execution, the state will transition through:
  /// 1. `ActivityStatus.thinking` - Processing the prompt
  /// 2. `ActivityStatus.calling_tool` - If tools are invoked
  /// 3. `ActivityStatus.idle` - When complete
  /// 4. `ActivityStatus.error` - If an error occurs
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Simple text prompt
  /// await session.transform('Create a bar chart of Q1 sales');
  ///
  /// // Prompt with image attachment
  /// final imageData = await file.readAsBytes();
  /// await session.transform(
  ///   'Create a chart from this screenshot',
  ///   attachments: [
  ///     BinaryContent(
  ///       data: base64Encode(imageData),
  ///       mimeType: 'image/png',
  ///       filename: 'screenshot.png',
  ///     ),
  ///   ],
  /// );
  /// ```
  ///
  /// ## Error Handling
  ///
  /// Errors are handled gracefully:
  /// - State transitions to `ActivityStatus.error`
  /// - `ErrorEvent` is emitted on the events stream
  /// - The error message is available in `state.errorMessage`
  ///
  /// The method itself does not throw; errors are communicated via
  /// state and events.
  Future<void> transform(
    String prompt, {
    List<BinaryContent>? attachments,
  });

  /// Updates the session's active chart with a user-edited configuration.
  ///
  /// Call this method when the user modifies the chart directly in the UI,
  /// such as:
  /// - Reordering series via drag-and-drop
  /// - Toggling series visibility
  /// - Adjusting axis ranges manually
  /// - Moving annotations
  ///
  /// This ensures the session state stays synchronized with the UI state,
  /// so subsequent LLM interactions have the correct context.
  ///
  /// The [newConfig] should be the complete updated [ChartConfiguration].
  /// It will replace the current [SessionState.activeChart].
  ///
  /// ## State Changes
  ///
  /// This method immediately updates [state] with the new chart and
  /// emits a [ChartUpdatedEvent] on the [events] stream.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // User reordered series in the UI
  /// void onSeriesReordered(List<SeriesConfig> newOrder) {
  ///   final updated = currentChart.copyWith(series: newOrder);
  ///   session.updateChart(updated);
  /// }
  ///
  /// // User toggled a series visibility
  /// void onSeriesToggled(String seriesId, bool visible) {
  ///   final updated = currentChart.copyWith(
  ///     series: currentChart.series.map((s) {
  ///       if (s.id == seriesId) {
  ///         return s.copyWith(visible: visible);
  ///       }
  ///       return s;
  ///     }).toList(),
  ///   );
  ///   session.updateChart(updated);
  /// }
  /// ```
  void updateChart(ChartConfiguration newConfig);

  /// Adds a chart snapshot image to the message history.
  ///
  /// Use this method to store a visual snapshot of a chart in the
  /// conversation history. This is useful for:
  /// - Visual history tracking
  /// - Comparing chart versions
  /// - Exporting conversation with embedded charts
  ///
  /// The [imageContent] should be captured using [ChartSnapshotService]
  /// or [ChartSnapshotWrapper] from the renderer layer.
  ///
  /// The optional [title] provides a label for the snapshot message.
  /// If not provided, the active chart's title or ID is used.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Using ChartSnapshotWrapper in your UI
  /// final _snapshotKey = GlobalKey<ChartSnapshotWrapperState>();
  ///
  /// ChartSnapshotWrapper(
  ///   key: _snapshotKey,
  ///   child: ChartRenderer().render(config),
  /// )
  ///
  /// // After chart renders, capture and add to history
  /// final imageContent = await _snapshotKey.currentState?.capture();
  /// if (imageContent != null) {
  ///   session.addChartSnapshot(imageContent, title: 'Sales Chart');
  /// }
  /// ```
  void addChartSnapshot(ImageContent imageContent, {String? title});

  /// Cancels the current in-progress operation.
  ///
  /// If an operation is in progress (e.g., waiting for LLM response,
  /// executing a tool), this method will attempt to cancel it gracefully.
  ///
  /// After cancellation:
  /// - State transitions to `ActivityStatus.idle`
  /// - [CancelledEvent] is emitted on the [events] stream
  /// - Any pending responses are discarded
  ///
  /// If no operation is in progress, this method has no effect.
  ///
  /// The returned [Future] completes when cancellation is complete.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // User pressed cancel button
  /// ElevatedButton(
  ///   onPressed: () => session.cancel(),
  ///   child: Text('Cancel'),
  /// )
  /// ```
  ///
  /// ## Notes
  ///
  /// - Cancellation is best-effort; some operations may not be cancellable
  /// - The conversation history up to the cancellation point is preserved
  /// - The active chart is preserved in its last known state
  Future<void> cancel();

  /// Disposes of the session and releases all resources.
  ///
  /// Call this method when the session is no longer needed, typically in
  /// the `dispose` method of a widget or when navigating away from a screen.
  ///
  /// After disposal:
  /// - The [state] ValueListenable stops emitting
  /// - The [events] stream is closed
  /// - Any in-progress operations are cancelled
  /// - Internal resources (HTTP clients, timers, etc.) are released
  ///
  /// **Important**: Do not use the session after calling dispose.
  /// Any method calls after dispose may throw or have undefined behavior.
  ///
  /// ## Example
  ///
  /// ```dart
  /// class _ChartScreenState extends State<ChartScreen> {
  ///   late final AgentSession session;
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     session = createSession();
  ///   }
  ///
  ///   @override
  ///   void dispose() {
  ///     session.dispose();
  ///     super.dispose();
  ///   }
  /// }
  /// ```
  void dispose();
}
