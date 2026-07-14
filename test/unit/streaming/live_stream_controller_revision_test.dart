import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/streaming/live_stream_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tracks committed and paused data revisions independently', () {
    final controller = LiveStreamController(seriesId: 'sensor');
    addTearDown(controller.dispose);

    expect(controller.committedDataRevision, 0);
    expect(controller.pendingDataRevision, 0);

    controller.addPoint(const ChartDataPoint(x: 1, y: 10));
    expect(controller.committedDataRevision, 1);
    expect(controller.pendingDataRevision, 0);

    controller.pause();
    controller.addPoint(const ChartDataPoint(x: 2, y: 11));
    expect(controller.committedDataRevision, 1);
    expect(controller.pendingDataRevision, 1);
    expect(controller.points, hasLength(1));
    expect(controller.bufferedCount, 1);

    controller.resume();
    expect(controller.committedDataRevision, 2);
    expect(controller.pendingDataRevision, 2);
    expect(controller.points, hasLength(2));
    expect(controller.bufferedCount, 0);
  });
}
