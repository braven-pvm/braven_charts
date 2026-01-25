import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/src/agentic/models/conversation.dart';
import '../../../../lib/src/agentic/models/message.dart';
import '../../../../lib/src/agentic/models/tool_call.dart';
import '../../../../lib/src/agentic/models/tool_result.dart';
import '../../../../lib/src/agentic/providers/llm_provider.dart';
import '../../../../lib/src/agentic/services/agent_service.dart';
import '../../../../lib/src/agentic/tools/tool_registry.dart';

void main() {
  group('AgentService', () {
    test('processUserMessage appends user and assistant messages', () async {
      final provider = _FakeLLMProvider([
        Message(
          id: 'assistant-1',
          role: MessageRole.assistant,
          textContent: 'ok',
        ),
      ]);
      final registry = _FakeToolRegistry();
      final service = AgentService(provider: provider, toolRegistry: registry);

      await service.processUserMessage('hello');

      final conversation = service.conversation.value;
      expect(conversation, isA<Conversation>());
      expect(conversation.messages.first.role, MessageRole.user);
      expect(conversation.messages.last.role, MessageRole.assistant);
      expect(conversation.messages.last.textContent, equals('ok'));
      expect(provider.callCount, equals(1));
      expect(registry.executeCount, equals(0));
    });

    test('processUserMessage executes tool calls and loops', () async {
      final toolCall = ToolCall(
        id: 'tool-1',
        toolName: 'summarize',
        arguments: {'input': 'data'},
      );

      final provider = _FakeLLMProvider([
        Message(
          id: 'assistant-1',
          role: MessageRole.assistant,
          toolCalls: [toolCall],
        ),
        Message(
          id: 'assistant-2',
          role: MessageRole.assistant,
          textContent: 'done',
        ),
      ]);
      final registry = _FakeToolRegistry(result: {'summary': 'ok'});
      final service = AgentService(provider: provider, toolRegistry: registry);

      await service.processUserMessage('run tool');

      final conversation = service.conversation.value;
      final toolResultMessages = conversation.messages
          .where((message) => message.toolResults != null)
          .toList();

      expect(provider.callCount, equals(2));
      expect(registry.executeCount, equals(1));
      expect(registry.lastToolName, equals('summarize'));
      expect(toolResultMessages, isNotEmpty);
      expect(toolResultMessages.first.toolResults!.first.toolCallId, 'tool-1');
      expect(conversation.messages.last.textContent, equals('done'));
    });

    test('processUserMessage streams incremental assistant content', () async {
      final provider = _StreamingLLMProvider(
        _streamChunks(['hel', 'lo']),
        Message(
          id: 'assistant-final',
          role: MessageRole.assistant,
          textContent: 'hello world',
        ),
      );
      final registry = _FakeToolRegistry();
      final service = AgentService(provider: provider, toolRegistry: registry);

      final updates = <String>[];
      void listener() {
        final messages = service.conversation.value.messages;
        if (messages.isEmpty) {
          return;
        }
        final last = messages.last;
        final text = last.textContent;
        if (last.role == MessageRole.assistant && text != null) {
          updates.add(text);
        }
      }

      service.conversation.addListener(listener);
      try {
        await service.processUserMessage('hello');
      } finally {
        service.conversation.removeListener(listener);
      }

      expect(
        service.conversation.value.messages.last.textContent,
        equals('hello world'),
      );
      expect(updates, contains('hel'));
      expect(
        updates.any(
          (value) => value.startsWith('hello') && value.length >= 5,
        ),
        isTrue,
      );
    });
  });
}

Stream<String> _streamChunks(List<String> chunks) {
  return Stream<String>.fromIterable(chunks);
}

class _FakeLLMProvider implements LLMProvider {
  _FakeLLMProvider(this._responses);

  final List<Message> _responses;
  final List<Conversation> _receivedConversations = [];
  int callCount = 0;

  @override
  Future<Message> sendMessage(Conversation conversation) async {
    _receivedConversations.add(conversation);
    final response = _responses[callCount];
    callCount += 1;
    return response;
  }

  @override
  Stream<String> streamMessage(Conversation conversation) async* {
    _receivedConversations.add(conversation);
  }
}

class _StreamingLLMProvider implements LLMProvider {
  _StreamingLLMProvider(this._stream, this._response);

  final Stream<String> _stream;
  final Message _response;

  @override
  Future<Message> sendMessage(Conversation conversation) async {
    return _response;
  }

  @override
  Stream<String> streamMessage(Conversation conversation) {
    return _stream;
  }
}

class _FakeToolRegistry extends ToolRegistry {
  _FakeToolRegistry({this.result});

  int executeCount = 0;
  String? lastToolName;
  Map<String, dynamic>? lastArgs;
  final dynamic result;

  @override
  Future<dynamic> execute(String name, Map<String, dynamic> args) async {
    executeCount += 1;
    lastToolName = name;
    lastArgs = args;

    return result ??
        ToolResult(
          toolCallId: 'tool-1',
          result: {'ok': true},
        );
  }
}
