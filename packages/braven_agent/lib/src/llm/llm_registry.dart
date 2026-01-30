import 'llm_config.dart';
import 'llm_provider.dart';

/// Factory function type for creating [LLMProvider] instances.
///
/// Accepts an [LLMConfig] and returns a configured provider instance.
/// Used with [LLMRegistry.register] to register provider factories.
///
/// ## Example
///
/// ```dart
/// LLMProviderFactory anthropicFactory = (config) => AnthropicAdapter(config);
/// LLMRegistry.register('anthropic', anthropicFactory);
/// ```
typedef LLMProviderFactory = LLMProvider Function(LLMConfig config);

/// Factory registry for [LLMProvider] implementations.
///
/// Enables dynamic provider selection at runtime by maintaining a registry
/// of provider factories. This decouples provider instantiation from
/// business logic and supports multiple simultaneous provider registrations.
///
/// ## Registration Pattern
///
/// Provider factories are registered at app startup, typically in main():
///
/// ```dart
/// void main() {
///   // Register available providers
///   LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));
///   LLMRegistry.register('openai', (config) => OpenAIAdapter(config));
///
///   runApp(MyApp());
/// }
/// ```
///
/// ## Creating Providers
///
/// Once registered, providers can be created by ID:
///
/// ```dart
/// final config = LLMConfig(apiKey: 'sk-...');
/// final provider = LLMRegistry.create('anthropic', config);
/// ```
///
/// ## Error Handling
///
/// Attempting to create an unregistered provider throws [StateError]:
///
/// ```dart
/// try {
///   LLMRegistry.create('unknown', config);
/// } on StateError catch (e) {
///   print(e.message);
///   // "No LLM provider registered for 'unknown'. Did you forget to call LLMRegistry.register()?"
/// }
/// ```
///
/// ## Testing
///
/// Use [clearRegistrations] to reset state between tests:
///
/// ```dart
/// setUp(() {
///   LLMRegistry.clearRegistrations();
/// });
/// ```
class LLMRegistry {
  /// Internal map of registered provider factories.
  static final Map<String, LLMProviderFactory> _factories = {};

  /// Private constructor to prevent instantiation.
  LLMRegistry._();

  /// Registers a provider factory with the given identifier.
  ///
  /// The [providerId] should be a unique, lowercase identifier for the
  /// provider (e.g., 'anthropic', 'openai', 'gemini').
  ///
  /// The [factory] function is called by [create] to instantiate the
  /// provider with a given [LLMConfig].
  ///
  /// Registering with an existing [providerId] will overwrite the
  /// previous factory.
  ///
  /// ## Example
  ///
  /// ```dart
  /// LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));
  /// ```
  static void register(String providerId, LLMProviderFactory factory) {
    _factories[providerId] = factory;
  }

  /// Creates a provider instance from a registered factory.
  ///
  /// Looks up the factory registered with [providerId] and invokes it
  /// with the given [config] to create a new provider instance.
  ///
  /// Returns the configured [LLMProvider] instance.
  ///
  /// Throws [StateError] if no factory is registered for [providerId].
  ///
  /// ## Example
  ///
  /// ```dart
  /// final config = LLMConfig(apiKey: 'sk-...');
  /// final provider = LLMRegistry.create('anthropic', config);
  /// ```
  static LLMProvider create(String providerId, LLMConfig config) {
    final factory = _factories[providerId];
    if (factory == null) {
      throw StateError(
        "No LLM provider registered for '$providerId'. "
        'Did you forget to call LLMRegistry.register()?',
      );
    }
    return factory(config);
  }

  /// Checks if a provider is registered with the given identifier.
  ///
  /// Returns `true` if a factory is registered for [providerId],
  /// `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (LLMRegistry.isRegistered('anthropic')) {
  ///   final provider = LLMRegistry.create('anthropic', config);
  /// }
  /// ```
  static bool isRegistered(String providerId) {
    return _factories.containsKey(providerId);
  }

  /// Returns a list of all registered provider identifiers.
  ///
  /// Useful for debugging or displaying available providers to users.
  ///
  /// ## Example
  ///
  /// ```dart
  /// print('Available providers: ${LLMRegistry.registeredProviders}');
  /// // Output: Available providers: [anthropic, openai]
  /// ```
  static List<String> get registeredProviders => _factories.keys.toList();

  /// Clears all registered provider factories.
  ///
  /// Use this in test setup/teardown to ensure a clean state between tests.
  /// Should NOT be used in production code.
  ///
  /// ## Example
  ///
  /// ```dart
  /// tearDown(() {
  ///   LLMRegistry.clearRegistrations();
  /// });
  /// ```
  static void clearRegistrations() {
    _factories.clear();
  }
}
