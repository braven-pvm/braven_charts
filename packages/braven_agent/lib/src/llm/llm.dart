/// LLM layer exports for the braven_agent package.
///
/// This barrel file provides a single import for all LLM-related
/// components including configuration, providers, and models.
///
/// ## Usage
///
/// ```dart
/// import 'package:braven_agent/src/llm/llm.dart';
///
/// // Register providers
/// LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));
/// LLMRegistry.register('grok', (config) => GrokAdapter(config));
///
/// // Create a provider
/// final config = LLMConfig(apiKey: 'sk-...');
/// final provider = LLMRegistry.create('anthropic', config);
/// ```
library llm;

// Configuration
export 'llm_config.dart';
// Core interfaces
export 'llm_provider.dart';
export 'llm_registry.dart';
export 'llm_response.dart';
// Models
export 'models/agent_message.dart';
export 'models/message_content.dart';
// Providers
export 'providers/anthropic_adapter.dart';
export 'providers/gemini_adapter.dart';
export 'providers/grok_adapter.dart';
export 'providers/openai_adapter.dart';
