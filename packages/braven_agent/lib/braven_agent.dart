/// Braven Agent - Headless AI orchestration engine for chart generation.
///
/// This package manages chat conversation state, communicates with LLMs
/// (Anthropic initially, extensible to others), and executes tools that
/// produce `ChartConfiguration` objects for rendering.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:braven_agent/braven_agent.dart';
///
/// // 1. Create session
/// final session = AgentSessionImpl(
///   llmProvider: LLMRegistry.create('anthropic', config),
///   tools: [CreateChartTool(), ModifyChartTool(getActiveChart: () => session.state.value.activeChart)],
///   systemPrompt: defaultSystemPrompt,
/// );
///
/// // 2. Send prompt
/// await session.transform('Create a line chart with sales data');
///
/// // 3. Get chart
/// final chart = session.state.value.activeChart;
/// final widget = const ChartRenderer().render(chart!);
/// ```
///
/// ## Reactive UI (ValueListenableBuilder)
///
/// ```dart
/// ValueListenableBuilder<SessionState>(
///   valueListenable: session.state,
///   builder: (context, state, _) {
///     // Show loading spinner
///     if (state.status == ActivityStatus.thinking) {
///       return CircularProgressIndicator();
///     }
///
///     // Show chart when ready
///     if (state.activeChart != null) {
///       return ChartRenderer().render(state.activeChart!);
///     }
///
///     return Text('Ask me to create a chart!');
///   },
/// )
/// ```
///
/// ## Event Subscriptions (Persistence, Navigation, Toasts)
///
/// ```dart
/// // Subscribe to events for side effects
/// session.events.listen((event) {
///   switch (event) {
///     case ChartCreatedEvent(:final config):
///       // Save to database, show toast, navigate to chart tab
///       database.insertChart(config);
///       showSnackbar('Chart created!');
///
///     case ChartUpdatedEvent(:final config):
///       // Update existing record
///       database.updateChart(config.id!, config);
///
///     case ErrorEvent(:final message):
///       // Show error dialog
///       showErrorDialog(message);
///
///     case ThinkingEvent(:final description):
///       // Update status indicator
///       debugPrint('Agent: $description');
///
///     case ToolStartEvent(:final toolName):
///       debugPrint('Executing: $toolName');
///
///     case ToolEndEvent(:final toolName, :final success):
///       debugPrint('$toolName ${success ? 'succeeded' : 'failed'}');
///
///     case CancelledEvent():
///       showSnackbar('Request cancelled');
///   }
/// });
/// ```
///
/// ## User Edits Chart → Agent Awareness
///
/// ```dart
/// // User modifies chart in UI (e.g., color picker)
/// final updatedChart = currentChart.copyWith(
///   series: [currentChart.series.first.copyWith(color: '#FF0000')],
/// );
///
/// // Tell session about the change
/// session.updateChart(updatedChart);
///
/// // Next transform() will include this context automatically
/// await session.transform('Make the line thicker');
/// // Agent knows the current chart state!
/// ```
///
/// ## Cleanup
///
/// ```dart
/// @override
/// void dispose() {
///   session.dispose(); // Closes streams, cancels pending ops
///   super.dispose();
/// }
/// ```
library braven_agent;

export 'src/llm/llm_config.dart';
export 'src/llm/llm_response.dart';
export 'src/llm/models/agent_message.dart';
// LLM Layer - Message Models and Config
export 'src/llm/models/message_content.dart';
export 'src/session/agent_events.dart';
// Models - to be exported when implemented
// export 'src/models/chart_configuration.dart';
// export 'src/models/series_config.dart';
// export 'src/models/axis_config.dart';
// export 'src/models/annotation_config.dart';
// export 'src/models/chart_style_config.dart';

// Renderer - to be exported when implemented
// export 'src/renderer/chart_renderer.dart';

// Session - to be exported when implemented
// export 'src/session/agent_session.dart';
export 'src/session/session_state.dart';

// LLM Layer - to be exported when implemented
// export 'src/llm/llm_provider.dart';
// export 'src/llm/llm_registry.dart';

// Tools - to be exported when implemented
// export 'src/tools/agent_tool.dart';
// export 'src/tools/create_chart_tool.dart';
// export 'src/tools/modify_chart_tool.dart';

// Constants - to be exported when implemented
// export 'src/session/default_system_prompt.dart';
