import 'package:braven_charts/braven_charts.dart';

class RevenueSample {
  const RevenueSample(this.month, this.revenue);

  final double month;
  final double revenue;
}

double sampleMonth(RevenueSample sample) => sample.month;
double sampleRevenue(RevenueSample sample) => sample.revenue;

const revenueSamples = [
  RevenueSample(1, 42),
  RevenueSample(2, 48),
  RevenueSample(3, 45),
  RevenueSample(4, 57),
  RevenueSample(5, 63),
];

// docs:start
final basicGrammarChart = BravenChart.of(revenueSamples)
    .x(sampleMonth, label: 'Month')
    .y(sampleRevenue, label: 'Revenue')
    .geomLine(name: 'Revenue', showDataPointMarkers: true)
    .title('Monthly revenue')
    .build();
// docs:end
