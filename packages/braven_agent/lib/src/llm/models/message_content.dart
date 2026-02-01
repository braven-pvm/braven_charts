import 'package:equatable/equatable.dart';

/// Sealed class hierarchy for message content types.
///
/// Enables exhaustive pattern matching in Dart 3.0+ for handling
/// different content types in LLM messages. Each subclass represents
/// a specific type of content that can appear in agent messages.
///
/// ## Pattern Matching Example
///
/// ```dart
/// String describe(MessageContent content) {
///   return switch (content) {
///     TextContent(:final text) => 'Text: $text',
///     ImageContent() => 'Image content',
///     BinaryContent(:final filename) => 'Binary: $filename',
///     ToolUseContent(:final toolName) => 'Tool call: $toolName',
///     ToolResultContent(:final isError) => 'Tool result (error: $isError)',
///   };
/// }
/// ```
///
/// ## JSON Serialization
///
/// All subclasses support round-trip JSON serialization:
///
/// ```dart
/// final content = TextContent(text: 'Hello');
/// final json = content.toJson();
/// final restored = MessageContent.fromJson(json);
/// assert(content == restored);
/// ```
sealed class MessageContent with EquatableMixin {
  /// Base constructor for [MessageContent].
  const MessageContent();

  /// Creates a [MessageContent] from a JSON map.
  ///
  /// The map must contain a 'type' field to determine the content type.
  /// Throws [ArgumentError] if the type is unknown.
  factory MessageContent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'text' => TextContent.fromJson(json),
      'image' => ImageContent.fromJson(json),
      'binary' => BinaryContent.fromJson(json),
      'tool_use' => ToolUseContent.fromJson(json),
      'tool_result' => ToolResultContent.fromJson(json),
      _ => throw ArgumentError('Unknown MessageContent type: $type'),
    };
  }

  /// Converts this [MessageContent] to a JSON map.
  Map<String, dynamic> toJson();
}

/// Plain text content in a message.
///
/// Used for regular text messages from users or assistants.
///
/// ## Example
///
/// ```dart
/// final content = TextContent(text: 'Create a line chart');
/// print(content.text); // 'Create a line chart'
/// ```
final class TextContent extends MessageContent {
  /// The text content of the message.
  final String text;

  /// Creates a [TextContent] with the given [text].
  const TextContent({required this.text});

  /// Creates a [TextContent] from a JSON map.
  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(text: json['text'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'text',
      'text': text,
    };
  }

  @override
  List<Object?> get props => [text];

  @override
  String toString() => 'TextContent(text: $text)';
}

/// Base64-encoded image content for vision capabilities.
///
/// Used when sending images to LLMs that support vision.
///
/// ## Example
///
/// ```dart
/// final content = ImageContent(
///   data: 'iVBORw0KGgo...', // base64 encoded
///   mediaType: 'image/png',
/// );
/// ```
final class ImageContent extends MessageContent {
  /// Base64-encoded image data.
  final String data;

  /// MIME type of the image (e.g., 'image/png', 'image/jpeg').
  final String mediaType;

  /// Creates an [ImageContent] with the given [data] and [mediaType].
  const ImageContent({
    required this.data,
    required this.mediaType,
  });

  /// Creates an [ImageContent] from a JSON map.
  factory ImageContent.fromJson(Map<String, dynamic> json) {
    return ImageContent(
      data: json['data'] as String,
      mediaType: json['mediaType'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'image',
      'data': data,
      'mediaType': mediaType,
    };
  }

  @override
  List<Object?> get props => [data, mediaType];

  @override
  String toString() => 'ImageContent(mediaType: $mediaType, data: ${data.length} chars)';
}

/// Raw binary content with MIME type.
///
/// Used for non-image binary data that may be needed in future use cases.
///
/// ## Example
///
/// ```dart
/// final content = BinaryContent(
///   data: 'SGVsbG8gV29ybGQ=', // base64 encoded
///   mimeType: 'application/octet-stream',
///   filename: 'data.bin',
/// );
/// ```
final class BinaryContent extends MessageContent {
  /// Base64-encoded binary data.
  final String data;

  /// MIME type of the binary content.
  final String mimeType;

  /// Optional filename for the binary content.
  final String? filename;

  /// Creates a [BinaryContent] with the given [data], [mimeType], and optional [filename].
  const BinaryContent({
    required this.data,
    required this.mimeType,
    this.filename,
  });

  /// Creates a [BinaryContent] from a JSON map.
  factory BinaryContent.fromJson(Map<String, dynamic> json) {
    return BinaryContent(
      data: json['data'] as String,
      mimeType: json['mimeType'] as String,
      filename: json['filename'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'binary',
      'data': data,
      'mimeType': mimeType,
      if (filename != null) 'filename': filename,
    };
  }

  @override
  List<Object?> get props => [data, mimeType, filename];

  @override
  String toString() => 'BinaryContent(mimeType: $mimeType, filename: $filename, data: ${data.length} chars)';
}

/// LLM requesting to call a tool.
///
/// Represents a tool invocation request from the LLM. The [id] is used
/// to correlate the tool result back to this request.
///
/// ## Example
///
/// ```dart
/// final content = ToolUseContent(
///   id: 'toolu_123',
///   toolName: 'create_chart',
///   input: {'type': 'line', 'title': 'Sales'},
/// );
/// ```
final class ToolUseContent extends MessageContent {
  /// Unique identifier for this tool use request.
  ///
  /// Used to correlate [ToolResultContent] back to this request.
  final String id;

  /// Name of the tool to invoke.
  final String toolName;

  /// Input parameters for the tool as a JSON-compatible map.
  final Map<String, dynamic> input;

  /// Provider-specific metadata that must be preserved across turns.
  ///
  /// Used for features like Gemini 3's `thoughtSignature` which must be
  /// returned with function responses to maintain reasoning context.
  /// This field is optional and only populated by providers that require it.
  final Map<String, dynamic>? providerMetadata;

  /// Creates a [ToolUseContent] with the given [id], [toolName], and [input].
  const ToolUseContent({
    required this.id,
    required this.toolName,
    required this.input,
    this.providerMetadata,
  });

  /// Creates a [ToolUseContent] from a JSON map.
  factory ToolUseContent.fromJson(Map<String, dynamic> json) {
    return ToolUseContent(
      id: json['id'] as String,
      toolName: json['toolName'] as String,
      input: Map<String, dynamic>.from(json['input'] as Map),
      providerMetadata: json['providerMetadata'] != null ? Map<String, dynamic>.from(json['providerMetadata'] as Map) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'tool_use',
      'id': id,
      'toolName': toolName,
      'input': input,
      if (providerMetadata != null) 'providerMetadata': providerMetadata,
    };
  }

  @override
  List<Object?> get props => [id, toolName, input, providerMetadata];

  @override
  String toString() => 'ToolUseContent(id: $id, toolName: $toolName)';
}

/// Result of a tool execution.
///
/// Represents the output from executing a tool, returned to the LLM
/// to continue the conversation. The [toolUseId] correlates to the
/// original [ToolUseContent.id].
///
/// ## Example
///
/// ```dart
/// final content = ToolResultContent(
///   toolUseId: 'toolu_123',
///   output: '{"chartId": "chart_456", "type": "line"}',
///   isError: false,
/// );
/// ```
///
/// ## Returning Images
///
/// Tool results can include images for vision-capable models:
///
/// ```dart
/// final content = ToolResultContent(
///   toolUseId: 'toolu_123',
///   output: 'Here is the chart screenshot:',
///   imageContent: ImageContent(data: base64Data, mediaType: 'image/png'),
/// );
/// ```
final class ToolResultContent extends MessageContent {
  /// ID of the [ToolUseContent] this result corresponds to.
  final String toolUseId;

  /// Name of the tool that was executed.
  ///
  /// Required for some LLM APIs (e.g., Gemini) that need the function name
  /// in the response. Optional for OpenAI-compatible APIs that use tool_call_id.
  final String? toolName;

  /// String output from the tool execution.
  ///
  /// Typically JSON-encoded for structured data.
  final String output;

  /// Whether the tool execution resulted in an error.
  final bool isError;

  /// Optional image content to include in the tool result.
  ///
  /// When set, the image will be included in the tool result message
  /// sent to the LLM, enabling vision-capable models to "see" the result.
  ///
  /// Note: Not all LLM providers support images in tool results.
  /// - Anthropic: Supported via ToolResultBlockContent.blocks
  /// - OpenAI: Not supported in tool results (use follow-up user message)
  /// - Gemini: Not supported in function responses
  final ImageContent? imageContent;

  /// Creates a [ToolResultContent] with the given [toolUseId], [output], and [isError].
  const ToolResultContent({
    required this.toolUseId,
    required this.output,
    this.toolName,
    this.isError = false,
    this.imageContent,
  });

  /// Creates a [ToolResultContent] from a JSON map.
  factory ToolResultContent.fromJson(Map<String, dynamic> json) {
    final imageJson = json['imageContent'] as Map<String, dynamic>?;
    return ToolResultContent(
      toolUseId: json['toolUseId'] as String,
      output: json['output'] as String,
      toolName: json['toolName'] as String?,
      isError: json['isError'] as bool? ?? false,
      imageContent: imageJson != null ? ImageContent.fromJson(imageJson) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'tool_result',
      'toolUseId': toolUseId,
      if (toolName != null) 'toolName': toolName,
      'output': output,
      'isError': isError,
      if (imageContent != null) 'imageContent': imageContent!.toJson(),
    };
  }

  @override
  List<Object?> get props => [toolUseId, toolName, output, isError, imageContent];

  @override
  String toString() => 'ToolResultContent(toolUseId: $toolUseId, toolName: $toolName, isError: $isError, hasImage: ${imageContent != null})';
}
