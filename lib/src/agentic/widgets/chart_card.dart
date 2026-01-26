import 'package:flutter/material.dart';

import '../models/chart_configuration.dart';
import '../services/agent_service.dart';

/// Card container for chart widgets with an action bar.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.chartId,
    required this.child,
    required this.chartConfiguration,
    this.agentService,
    this.onRefresh,
    this.onShare,
    this.onEdit,
  });

  final String chartId;
  final Widget child;
  final ChartConfiguration chartConfiguration;
  final AgentService? agentService;
  final VoidCallback? onRefresh;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2), // Debug border
        ),
        constraints:
            const BoxConstraints(minHeight: 200), // Ensure minimum height
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Update AgentService.currentChart to this chart's configuration
                    agentService?.currentChart.value = chartConfiguration;
                    // Call custom onEdit callback if provided
                    onEdit?.call();
                  },
                  tooltip: 'Edit Chart',
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Refresh',
                  ),
                if (onShare != null)
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: onShare,
                    tooltip: 'Share',
                  ),
              ],
            ),
            // Chart content
            child,
          ],
        ),
      ),
    );
  }
}
