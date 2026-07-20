import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/candlestick_data_point.dart';
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

  test('publishes effective revisions with O(1) retained endpoints', () {
    final controller = LiveStreamController(seriesId: 'sensor', maxPoints: 2);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.dataRevision.addListener(() => notifications++);

    expect(controller.dataRevision.value, 0);
    expect(controller.oldestPoint, isNull);
    expect(controller.latestPoint, isNull);

    controller.addPoint(const ChartDataPoint(x: 1, y: 10));
    controller.addPoint(const ChartDataPoint(x: 2, y: 20));
    controller.addPoint(const ChartDataPoint(x: 3, y: 30));

    expect(notifications, 3);
    expect(controller.dataRevision.value, 3);
    expect(controller.oldestPoint, const ChartDataPoint(x: 2, y: 20));
    expect(controller.latestPoint, const ChartDataPoint(x: 3, y: 30));
  });

  test('revises the latest candle in place and rejects older samples', () {
    final controller = LiveStreamController(seriesId: 'price');
    addTearDown(controller.dispose);
    CandlestickDataPoint candle(double x, double close) => CandlestickDataPoint(
      x: x,
      open: 10,
      high: close > 10 ? close + 1 : 11,
      low: close < 10 ? close - 1 : 9,
      close: close,
    );

    expect(
      controller.upsertLatestCandlestick(candle(1, 12)),
      CandlestickUpsertResult.appended,
    );
    expect(
      controller.upsertLatestCandlestick(candle(1, 8)),
      CandlestickUpsertResult.revised,
    );
    expect(controller.pointCount, 1);
    expect((controller.latestPoint! as CandlestickDataPoint).close, 8);
    expect(controller.bounds.yMin, 7);
    expect(controller.bounds.yMax, 13);
    expect(
      controller.upsertLatestCandlestick(candle(0, 11)),
      CandlestickUpsertResult.rejectedOlder,
    );
    expect(controller.pointCount, 1);
  });

  test('coalesces paused revisions before resume', () {
    final controller = LiveStreamController(seriesId: 'price');
    addTearDown(controller.dispose);
    CandlestickDataPoint candle(double close) => CandlestickDataPoint(
      x: 1,
      open: 10,
      high: close > 10 ? close : 10,
      low: close < 10 ? close : 10,
      close: close,
    );

    controller.pause();
    controller.upsertLatestCandlestick(candle(11));
    controller.upsertLatestCandlestick(candle(12));
    expect(controller.bufferedCount, 1);

    controller.resume();
    expect(controller.pointCount, 1);
    expect((controller.latestPoint! as CandlestickDataPoint).close, 12);
  });
}
