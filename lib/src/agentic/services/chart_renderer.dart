import 'package:flutter/material.dart';

import '../models/chart_configuration.dart';

/// Renders chart configurations into Flutter widgets.
class ChartRenderer {
  const ChartRenderer();

  /// Builds a widget for the provided chart configuration or raw chart data.
  Widget render(dynamic chart) {
    if (chart is ChartConfiguration) {
      return _renderConfiguration(chart);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: const Text(
        'Chart preview',
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _renderConfiguration(ChartConfiguration config) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Text(
        '${config.type.name} chart',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
