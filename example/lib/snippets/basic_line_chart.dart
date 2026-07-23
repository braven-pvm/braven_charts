import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

// docs:start
class BasicLineChart extends StatelessWidget {
  const BasicLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: BravenChartPlus(
        title: 'Monthly revenue',
        series: [
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
      ),
    );
  }
}

// docs:end
