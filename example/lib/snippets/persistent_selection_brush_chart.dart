import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

// docs:start
Widget persistentSelectionBrushChart({
  required BravenChartController controller,
  SelectionResultCallback? onSelectionChanged,
}) {
  return SizedBox(
    height: 280,
    child: BravenChartPlus(
      bravenChartController: controller,
      series: const [
        LineChartSeries(
          id: 'revenue',
          name: 'Revenue',
          points: [
            ChartDataPoint(x: 1, y: 42),
            ChartDataPoint(x: 2, y: 48),
            ChartDataPoint(x: 3, y: 45),
            ChartDataPoint(x: 4, y: 57),
            ChartDataPoint(x: 5, y: 63),
          ],
        ),
      ],
      interactionConfig: InteractionConfig(
        selection: const ChartSelectionConfig(
          acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
          brush: ChartSelectionBrushConfig(
            enabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(minimum: 1.5, maximum: 3.5),
            style: ChartSelectionBrushStyle(
              fillColor: Color(0xFF2563EB),
              borderColor: Color(0xFF1D4ED8),
              borderRadius: 6,
            ),
          ),
        ),
        onSelectionResultChanged: onSelectionChanged,
      ),
    ),
  );
}

// Move or resize the brush through the same public controller used for other
// chart commands. Each successful change publishes the normal selection
// callbacks configured above.
ChartArtifactResult<void> showLatestWindow(BravenChartController controller) {
  return controller.setSelectionBrush(minimum: 3, maximum: 5);
}

// docs:end
