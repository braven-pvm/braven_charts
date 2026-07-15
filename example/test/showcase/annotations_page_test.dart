import 'dart:ui' show PointerDeviceKind;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/annotations_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('annotations page teaches every public type and its variants', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AnnotationsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose an annotation'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('annotation-type-ribbon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('annotation-context-menu-guide')),
      findsOneWidget,
    );
    expect(find.textContaining('Right-click the plot'), findsOneWidget);
    expect(find.textContaining('Right-click an annotation'), findsOneWidget);
    expect(find.text('Threshold annotation playground'), findsOneWidget);
    expect(find.text('Threshold Options'), findsOneWidget);

    final thresholdChart = _mainChart(tester, 'threshold');
    expect(
      thresholdChart.annotations.whereType<ThresholdAnnotation>(),
      hasLength(3),
    );
    final threshold = _annotation<ThresholdAnnotation>(
      thresholdChart,
      'playground-threshold',
    );
    expect(threshold.axis, AnnotationAxis.y);
    expect(threshold.value, 65);
    expect(threshold.dashPattern, isNotNull);
    expect(threshold.elevation, greaterThan(0));

    await _selectAnnotation(tester, 'range');
    expect(find.text('Range Options'), findsOneWidget);
    expect(find.text('Snap to Value'), findsOneWidget);
    final rangeChart = _mainChart(tester, 'range');
    expect(rangeChart.annotations.whereType<RangeAnnotation>(), hasLength(3));
    final range = _annotation<RangeAnnotation>(rangeChart, 'playground-range');
    expect(range.startX, 7);
    expect(range.endX, 14);
    expect(range.seriesId, 'signal');

    await _selectAnnotation(tester, 'point');
    expect(find.text('Point Options'), findsOneWidget);
    final pointChart = _mainChart(tester, 'point');
    expect(pointChart.annotations.whereType<PointAnnotation>(), hasLength(3));
    final point = _annotation<PointAnnotation>(pointChart, 'playground-point');
    expect(point.seriesId, 'signal');
    expect(point.markerShape, MarkerShape.star);
    expect(point.offset, isNot(Offset.zero));

    await _selectAnnotation(tester, 'text');
    expect(find.text('Rich Text Delta'), findsOneWidget);
    final textChart = _mainChart(tester, 'text');
    expect(textChart.annotations.whereType<TextAnnotation>(), hasLength(2));
    final text = _annotation<TextAnnotation>(textChart, 'playground-text');
    expect(text.isRichText, isTrue);
    expect(text.anchor, AnnotationAnchor.topLeft);

    await _selectAnnotation(tester, 'pin');
    expect(find.text('Pin Options'), findsOneWidget);
    final pinChart = _mainChart(tester, 'pin');
    expect(pinChart.annotations.whereType<PinAnnotation>(), hasLength(3));
    final pin = _annotation<PinAnnotation>(pinChart, 'playground-pin');
    expect(pin.x, 16);
    expect(pin.y, 74);

    await _selectAnnotation(tester, 'trend');
    expect(find.text('Trend Options'), findsOneWidget);
    final trendChart = _mainChart(tester, 'trend');
    final trends = trendChart.annotations.whereType<TrendAnnotation>();
    expect(trends, hasLength(4));
    expect(
      trends.map((annotation) => annotation.trendType).toSet(),
      TrendType.values.toSet(),
    );
    final trend = _annotation<TrendAnnotation>(trendChart, 'playground-trend');
    expect(trend.trendType, TrendType.polynomial);
    final trendOption = tester.widget<EnumOption<TrendType>>(
      find.byType(EnumOption<TrendType>),
    );
    expect(trendOption.values, TrendType.values);

    await _selectAnnotation(tester, 'chord');
    expect(find.text('Perpendicular Drop-line'), findsOneWidget);
    expect(find.text('Independent Drop-line Style'), findsOneWidget);
    final chordChart = _mainChart(tester, 'chord');
    expect(chordChart.annotations.whereType<ChordAnnotation>(), hasLength(2));
    final chord = _annotation<ChordAnnotation>(chordChart, 'playground-chord');
    expect(chord.perpendicularIndex, 11);
    expect(chord.perpendicularLineColor, isNotNull);
    expect(chord.perpendicularDashPattern, isNotNull);

    await _selectAnnotation(tester, 'legend');
    expect(find.text('Legend Options'), findsOneWidget);
    expect(find.text('Hide Reference Series'), findsOneWidget);
    final legend =
        _mainChart(tester, 'legend').annotations.single as LegendAnnotation;
    expect(legend.series, hasLength(2));
    expect(legend.trendAnnotations, hasLength(1));
    expect(legend.legendStyle.position, LegendPosition.topRight);
    expect(legend.legendStyle.orientation, LegendOrientation.vertical);
    expect(legend.legendStyle.allowDragging, isTrue);
  });

  testWidgets('annotation controls update the selected primary model', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AnnotationsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final axisOption = tester.widget<EnumOption<AnnotationAxis>>(
      find.byType(EnumOption<AnnotationAxis>),
    );
    axisOption.onChanged(AnnotationAxis.x);
    await tester.pump();

    var threshold = _annotation<ThresholdAnnotation>(
      _mainChart(tester, 'threshold'),
      'playground-threshold',
    );
    expect(threshold.axis, AnnotationAxis.x);
    expect(threshold.value, 12);

    final showLabel = tester.widget<BoolOption>(
      find.widgetWithText(BoolOption, 'Show Label'),
    );
    showLabel.onChanged(false);
    await tester.pump();
    threshold = _annotation<ThresholdAnnotation>(
      _mainChart(tester, 'threshold'),
      'playground-threshold',
    );
    expect(threshold.label, isNull);

    await _selectAnnotation(tester, 'trend');
    final trendOption = tester.widget<EnumOption<TrendType>>(
      find.byType(EnumOption<TrendType>),
    );
    trendOption.onChanged(TrendType.exponentialMovingAverage);
    await tester.pump();
    final trend = _annotation<TrendAnnotation>(
      _mainChart(tester, 'trend'),
      'playground-trend',
    );
    expect(trend.trendType, TrendType.exponentialMovingAverage);
    expect(trend.windowSize, 5);
    expect(find.text('Window Size'), findsOneWidget);
  });

  testWidgets('right-click exposes annotation creation actions', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AnnotationsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final chart = find.byKey(const ValueKey('annotation-main-threshold'));
    final gesture = await tester.startGesture(
      tester.getCenter(chart),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Add Text Annotation'), findsOneWidget);
    expect(find.text('Add Pin Annotation'), findsOneWidget);
    expect(find.text('Add Range Annotation'), findsOneWidget);
    expect(find.text('Add Threshold Line'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    final chartRect = tester.getRect(chart);
    final annotationGesture = await tester.startGesture(
      Offset(
        chartRect.left + chartRect.width * 0.55,
        chartRect.top + chartRect.height * 0.35,
      ),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await annotationGesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}

BravenChartPlus _mainChart(WidgetTester tester, String kind) {
  return tester.widget<BravenChartPlus>(
    find.byKey(ValueKey('annotation-main-$kind')),
  );
}

T _annotation<T extends ChartAnnotation>(BravenChartPlus chart, String id) {
  return chart.annotations.whereType<T>().singleWhere(
    (annotation) => annotation.id == id,
  );
}

Future<void> _selectAnnotation(WidgetTester tester, String kind) async {
  final card = find.byKey(ValueKey('annotation-preview-$kind'));
  final ribbon = find.byKey(const ValueKey('annotation-type-ribbon'));

  for (var attempt = 0; attempt < 8 && card.evaluate().isEmpty; attempt++) {
    await tester.drag(ribbon, const Offset(-420, 0));
    await tester.pumpAndSettle();
  }

  expect(card, findsOneWidget);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}
