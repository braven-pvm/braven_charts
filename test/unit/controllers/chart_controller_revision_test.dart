import 'package:braven_charts/src/controllers/chart_controller.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('revision advances only when controller state mutates', () {
    final controller = ChartController();
    addTearDown(controller.dispose);

    expect(controller.revision, 0);

    controller.addPoint('power', const ChartDataPoint(x: 1, y: 200));
    expect(controller.revision, 1);

    controller.removeOldestPoint('missing');
    expect(controller.revision, 1);

    controller.addAnnotation(
      ThresholdAnnotation(id: 'threshold', axis: AnnotationAxis.y, value: 250),
    );
    expect(controller.revision, 2);

    controller.clearAnnotations();
    expect(controller.revision, 3);

    controller.clearAnnotations();
    expect(controller.revision, 3);
  });
}
