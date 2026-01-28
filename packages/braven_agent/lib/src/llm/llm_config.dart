import 'package:equatable/equatable.dart';

/// Configuration for connecting to an LLM provider.
///
/// Contains authentication, model selection, and generation parameters.
/// Provider-agnostic to support multiple LLM backends.
///
/// ## Example
///
/// ```dart
/// final config = LLMConfig(
///   apiKey: 'sk-...',
///   model: 'claude-sonnet-4-20250514',
///   temperature: 0.7,
///   maxTokens: 4096,
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = config.toJson();
/// final restored = LLMConfig.fromJson(json);
/// ```
///
/// ## Security Note
///
/// The [apiKey] is included in [toJson] output. Ensure JSON output
/// is not logged or exposed in insecure contexts.
class LLMConfig with EquatableMixin {
  /// API key for authenticating with the LLM provider.
  final String apiKey;

  /// Base URL for the LLM API.
  ///
  /// If null, the provider's default URL is used.
  final String? baseUrl;

  /// Model identifier to use for generation.
  ///
  /// Defaults to 'claude-sonnet-4-20250514'.
  final String model;

  /// Temperature for response generation (0.0 to 1.0+).
  ///
  /// Lower values produce more deterministic outputs.
  /// Defaults to 0.7.
  final double temperature;

  /// Maximum number of tokens to generate.
  ///
  /// Defaults to 4096.
  final int maxTokens;

  /// Provider-specific options not covered by standard fields.
  ///
  /// Passed through to the LLM provider adapter.
  final Map<String, dynamic>? providerOptions;

  /// Default model identifier.
  static const String defaultModel = 'claude-sonnet-4-20250514';

  /// Default temperature value.
  static const double defaultTemperature = 0.7;

  /// Default maximum tokens.
  static const int defaultMaxTokens = 4096;

  /// Creates an [LLMConfig] with the given parameters.
  ///
  /// [apiKey] is required. Other parameters have sensible defaults.
  const LLMConfig({
    required this.apiKey,
    this.baseUrl,
    this.model = defaultModel,
    this.temperature = defaultTemperature,
    this.maxTokens = defaultMaxTokens,
    this.providerOptions,
  });

  /// Creates an [LLMConfig] from a JSON map.
  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String?,
      model: json['model'] as String? ?? defaultModel,
      temperature:
          (json['temperature'] as num?)?.toDouble() ?? defaultTemperature,
      maxTokens: json['maxTokens'] as int? ?? defaultMaxTokens,
      providerOptions: json['providerOptions'] != null
          ? Map<String, dynamic>.from(json['providerOptions'] as Map)
          : null,
    );
  }

  /// Converts this [LLMConfig] to a JSON map.
  ///
  /// **Security Warning**: Includes [apiKey] in output.
  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      if (baseUrl != null) 'baseUrl': baseUrl,
      'model': model,
      'temperature': temperature,
      'maxTokens': maxTokens,
      if (providerOptions != null) 'providerOptions': providerOptions,
    };
  }

  /// Creates a copy of this [LLMConfig] with optionally overridden values.
  LLMConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? providerOptions,
  }) {
    return LLMConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      providerOptions: providerOptions ?? this.providerOptions,
    );
  }

  @override
  List<Object?> get props => [
        apiKey,
        baseUrl,
        model,
        temperature,
        maxTokens,
        providerOptions,
      ];

  @override
  String toString() =>
      'LLMConfig(model: $model, temperature: $temperature, maxTokens: $maxTokens)';
}
