import '../llm/models/message_content.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// A callback function that captures the current chart as an image.
///
/// Returns an [ImageContent] with the base64-encoded screenshot,
/// or `null` if capture fails.
typedef ChartCaptureCallback = Future<ImageContent?> Function();

/// Tool that captures a screenshot of the current chart and returns it
/// to the LLM for visual analysis.
///
/// This tool enables vision-capable models to "see" the actual chart
/// state, allowing for visual feedback, verification, or iteration
/// based on the chart's appearance.
///
/// ## Usage
///
/// The tool requires a capture callback that performs the actual
/// screenshot capture. This is typically provided by the UI layer:
///
/// ```dart
/// final snapshotKey = GlobalKey<ChartSnapshotWrapperState>();
///
/// // In your UI
/// ChartSnapshotWrapper(
///   key: snapshotKey,
///   child: ChartRenderer().render(config),
/// )
///
/// // Create the tool with the capture callback
/// final seeChartTool = SeeChartTool(
///   onCapture: () async => snapshotKey.currentState?.capture(),
/// );
///
/// // Register with session
/// session.registerTool(seeChartTool);
/// ```
///
/// ## LLM Provider Support
///
/// Image content in tool results is supported by:
/// - **Anthropic**: Full support via ToolResultBlockContent.blocks
/// - **OpenAI**: Not supported (image will be ignored)
/// - **Gemini**: Not supported (image will be ignored)
///
/// For providers that don't support images in tool results, the text
/// output will still be returned, but the image won't be visible to
/// the model.
class SeeChartTool extends AgentTool {
  /// Creates a [SeeChartTool] with the given capture callback.
  ///
  /// The [onCapture] callback is called when the tool is executed
  /// to capture the current chart state.
  SeeChartTool({
    required this.onCapture,
  });

  /// Callback that captures the current chart as an image.
  final ChartCaptureCallback onCapture;

  @override
  String get name => 'see_chart';

  @override
  String get description => 'Captures a screenshot of the current chart and returns it for visual '
      'analysis. Use this tool to see the actual rendered chart, verify visual '
      'appearance, check colors, labels, axis formatting, or any other visual '
      'aspects of the chart. The screenshot will be included in the response '
      'so you can analyze what the chart actually looks like.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'reason': {
            'type': 'string',
            'description': 'Optional reason for viewing the chart (e.g., "verify axis labels", "check colors")',
          },
        },
        'required': [],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    final reason = input['reason'] as String?;

    try {
      final imageContent = await onCapture();

      if (imageContent == null) {
        return const ToolResult(
          output: 'Failed to capture chart screenshot. The chart may not be '
              'rendered yet or the capture callback returned null.',
          isError: true,
        );
      }

      final reasonText = reason != null ? ' (Reason: $reason)' : '';
      return ToolResult(
        output: 'Chart screenshot captured successfully.$reasonText '
            'The image is included in this response for your analysis.',
        imageContent: imageContent,
      );
    } catch (e) {
      return ToolResult(
        output: 'Error capturing chart screenshot: $e',
        isError: true,
      );
    }
  }
}
