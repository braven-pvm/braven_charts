// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_agent/braven_agent.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BravenAgentDemo());
}

class BravenAgentDemo extends StatelessWidget {
  const BravenAgentDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Braven Agent Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ApiKeyGateScreen(),
    );
  }
}

class ApiKeyGateScreen extends StatefulWidget {
  const ApiKeyGateScreen({super.key});

  @override
  State<ApiKeyGateScreen> createState() => _ApiKeyGateScreenState();
}

class _ApiKeyGateScreenState extends State<ApiKeyGateScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  String? _apiKey;
  AgentSession? _session;

  @override
  void initState() {
    super.initState();
    final envApiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
    if (envApiKey.isNotEmpty) {
      _setApiKey(envApiKey);
    }
  }

  void _setApiKey(String apiKey) {
    setState(() {
      _apiKey = apiKey;
      _session = null;
    });
  }

  void _handleApiKeySubmit() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid API key'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _setApiKey(apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_apiKey == null) {
      return _buildApiKeyInput();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Braven Agent Demo'),
      ),
      body: const Center(
        child: Text(
          'API key accepted. Chat UI will appear here in a later task.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildApiKeyInput() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Braven Agent Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.key,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Anthropic API Key Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your Anthropic API key to start the demo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-ant-...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                    onSubmitted: (_) => _handleApiKeySubmit(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleApiKeySubmit,
                    icon: const Icon(Icons.check),
                    label: const Text('Connect'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get a key at console.anthropic.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
