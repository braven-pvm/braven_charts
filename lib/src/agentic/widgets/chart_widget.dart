import 'package:flutter/material.dart';

import '../services/chart_renderer.dart';

/// Chart widget for agentic UI.
class ChartWidget extends StatelessWidget {
  const ChartWidget({super.key, this.chart, ChartRenderer? renderer})
      : _renderer = renderer ?? const ChartRenderer();

  final dynamic chart;
  final ChartRenderer _renderer;

  @override
  Widget build(BuildContext context) {
    return _renderer.render(chart);
  }
}
