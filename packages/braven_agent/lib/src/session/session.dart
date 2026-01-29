/// Session layer exports for the braven_agent package.
///
/// This barrel file provides a single import for all session-related
/// components including state management, events, and the agent session
/// interface.
///
/// ## Usage
///
/// ```dart
/// import 'package:braven_agent/src/session/session.dart';
///
/// // Access session state
/// final state = SessionState();
/// print(state.status); // ActivityStatus.idle
///
/// // Listen to events
/// session.events.listen((event) {
///   switch (event) {
///     case ChartCreatedEvent(:final config):
///       print('Chart created: ${config.id}');
///     // ...
///   }
/// });
///
/// // Use the default system prompt
/// print(defaultSystemPrompt);
/// ```
///
/// ## Exports
///
/// - [AgentSession]: Abstract interface for agent conversations
/// - [SessionState]: Immutable snapshot of session state
/// - [ActivityStatus]: Session activity status enum
/// - [ToolCall]: In-progress tool execution model
/// - [AgentEvent]: Sealed class hierarchy for session events
/// - [defaultSystemPrompt]: Default LLM system prompt constant
library session;

// Events
export 'agent_events.dart';
// Agent session interface
export 'agent_session.dart';
// Agent session implementation
export 'agent_session_impl.dart';
// Default system prompt
export 'default_system_prompt.dart';
// State
export 'session_state.dart';
