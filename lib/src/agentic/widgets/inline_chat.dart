import 'package:flutter/material.dart';

import '../models/chart_configuration.dart';
import '../services/agent_service.dart';

/// Inline chat UI scoped to a specific chart.
///
/// NOTE: This is a minimal stub to allow red-phase tests to compile.
class InlineChat extends StatelessWidget {
  const InlineChat({
    super.key,
    required this.chartId,
    required this.agentService,
    this.chartConfiguration,
    this.onClose,
  });

  final String chartId;
  final AgentService agentService;
  final ChartConfiguration? chartConfiguration;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
