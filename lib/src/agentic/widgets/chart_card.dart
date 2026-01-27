import 'package:flutter/material.dart';

import '../models/chart_configuration.dart';
import '../services/agent_service.dart';
import '../services/chart_renderer.dart';
import 'chart_widget.dart';
import 'config_panel.dart';
import 'inline_chat.dart';

/// Callback for adding a chart to the main chat context.
typedef AddToContextCallback = void Function(ChartConfiguration chart);

/// Card container for chart widgets with an action bar.
class ChartCard extends StatefulWidget {
  const ChartCard({
    super.key,
    required this.chartId,
    required this.child,
    required this.chartConfiguration,
    this.agentService,
    this.onRefresh,
    this.onShare,
    this.onEdit,
    this.onAddToContext,
  });

  final String chartId;
  final Widget child;
  final ChartConfiguration chartConfiguration;
  final AgentService? agentService;
  final VoidCallback? onRefresh;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;

  /// Callback when 'Add to Context' is pressed.
  /// Makes the chart available for cross-chart operations in main ChatInterface.
  final AddToContextCallback? onAddToContext;

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  bool _isPanelVisible = false;
  bool _isChatVisible = false;
  late ChartConfiguration _currentConfig;
  final ChartRenderer _chartRenderer = const ChartRenderer();

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.chartConfiguration;
  }

  @override
  void didUpdateWidget(ChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local config if parent provides a new one
    if (oldWidget.chartConfiguration != widget.chartConfiguration) {
      _currentConfig = widget.chartConfiguration;
    }
  }

  void _togglePanel() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
  }

  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
    });
  }

  void _addToContext() {
    widget.onAddToContext?.call(_currentConfig);
    // Also set currentChart in AgentService if available
    widget.agentService?.currentChart.value = _currentConfig;
  }

  void _onConfigurationChanged(ChartConfiguration newConfig) {
    setState(() {
      _currentConfig = newConfig;
    });
    // Update AgentService.currentChart for AI awareness
    widget.agentService?.currentChart.value = newConfig;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild chart widget when configuration changes
    final chartWidget = widget.child is ChartWidget
        ? ChartWidget(
            chart: _currentConfig.toJson(),
            renderer: _chartRenderer,
          )
        : widget.child;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      elevation: 2,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 1.2), // Debug border
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
                // Inline chat toggle
                if (widget.agentService != null)
                  IconButton(
                    icon: Icon(
                      _isChatVisible ? Icons.chat : Icons.chat_outlined,
                    ),
                    onPressed: _toggleChat,
                    tooltip: 'Inline Chat',
                  ),
                // Add to Context button
                if (widget.agentService != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addToContext,
                    tooltip: 'Add to Context',
                  ),
                IconButton(
                  icon: Icon(
                    _isPanelVisible ? Icons.settings : Icons.settings_outlined,
                  ),
                  onPressed: _togglePanel,
                  tooltip: 'Configuration Panel',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Update AgentService.currentChart to this chart's configuration
                    widget.agentService?.currentChart.value = _currentConfig;
                    // Call custom onEdit callback if provided
                    widget.onEdit?.call();
                  },
                  tooltip: 'Edit Chart',
                ),
                if (widget.onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: widget.onRefresh,
                    tooltip: 'Refresh',
                  ),
                if (widget.onShare != null)
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: widget.onShare,
                    tooltip: 'Share',
                  ),
              ],
            ),
            // Inline chat (conditionally visible)
            if (_isChatVisible && widget.agentService != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InlineChat(
                  chartId: widget.chartId,
                  chartConfiguration: _currentConfig,
                  agentService: widget.agentService!,
                  onClose: _toggleChat,
                ),
              ),
            // Config panel (conditionally visible)
            if (_isPanelVisible)
              ConfigPanel(
                configuration: _currentConfig,
                onConfigurationChanged: _onConfigurationChanged,
              ),
            // Chart content - use re-rendered chart when config changes
            chartWidget,
          ],
        ),
      ),
    );
  }
}
