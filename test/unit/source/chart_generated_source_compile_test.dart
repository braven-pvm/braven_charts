import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'representative generated Dart formats and analyzes',
    () async {
      final series = const LineChartSeries(
        id: 'power',
        name: 'Power',
        points: [ChartDataPoint(x: 0, y: 148), ChartDataPoint(x: 1, y: 162)],
      );
      final scatter = const ScatterChartSeries(
        id: 'risk',
        name: 'Assets',
        points: [ChartDataPoint(x: 1, y: 2, colorValue: 80, opacityValue: 92)],
        colorEncoding: ScatterColorEncoding(
          colors: [Color(0xFF16A34A), Color(0xFFDC2626)],
          scaleType: ScatterColorScaleType.piecewise,
          thresholds: [60],
          bandLabels: ['Normal', 'Critical'],
        ),
        opacityEncoding: ScatterOpacityEncoding(
          minimumOpacity: 0.15,
          maximumOpacity: 0.95,
          label: 'Confidence',
          unit: '%',
        ),
        jitter: ScatterJitterConfig(xAmplitude: 9, yAmplitude: 5, seed: 31),
        dataPointLabels: DataPointLabelConfig(
          show: true,
          content: DataPointLabelContent.pointLabel,
          collisionPolicy: DataPointLabelCollisionPolicy.reposition,
          markerGap: 6,
        ),
      );
      final candles = CandlestickChartSeries(
        id: 'price',
        unit: 'USD',
        points: [
          CandlestickDataPoint(
            x: 0,
            open: 146,
            high: 153,
            low: 144,
            close: 151,
          ),
          CandlestickDataPoint(
            x: 1,
            open: 151,
            high: 164,
            low: 149,
            close: 158,
          ),
        ],
        candlestickStyle: const CandlestickChartStyle(
          bodyFillMode: CandlestickBodyFillMode.filled,
          bodyCornerRadius: 2,
        ),
      );
      final range = RangeAreaChartSeries(
        id: 'forecast',
        unit: 'W',
        points: [
          RangeAreaDataPoint(x: 0, low: 142, high: 156),
          RangeAreaDataPoint.gap(x: .5),
          RangeAreaDataPoint(x: 1, low: 154, high: 169),
        ],
        fillGradient: const AreaGradient(
          colors: [Color(0x332563EB), Color(0x992563EB)],
        ),
        upperBoundaryStyle: const RangeAreaBoundaryStyle(dashPattern: [4, 2]),
        pathAnimation: const PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
        ),
      );
      final snapshot = ChartDocumentSnapshot(
        document: ChartDocument(
          documentId: 'generated-source-compile',
          revision: 4,
          series: [
            _success(ChartSeriesDocumentCodec.encode(candles)).value,
            _success(ChartSeriesDocumentCodec.encode(series)).value,
            _success(ChartSeriesDocumentCodec.encode(scatter)).value,
            _success(ChartSeriesDocumentCodec.encode(range)).value,
          ],
          annotations: [
            _success(
              ChartAnnotationDocumentCodec.encode(
                LegendAnnotation(
                  id: 'legend',
                  series: [series],
                  legendStyle: const LegendStyle(
                    position: LegendPosition.bottomLeft,
                  ),
                ),
              ),
            ).value,
            _success(
              ChartAnnotationDocumentCodec.encode(
                LegendAnnotation(
                  id: 'confidence-key',
                  opacityScale: const LegendOpacityScale(
                    label: 'Confidence',
                    color: Color(0xFF2563EB),
                    minimumOpacity: 0.15,
                    maximumOpacity: 0.95,
                    minimumLabel: '40 %',
                    midpointLabel: '70 %',
                    maximumLabel: '100 %',
                  ),
                ),
              ),
            ).value,
            _success(
              ChartAnnotationDocumentCodec.encode(
                LegendAnnotation(
                  id: 'risk-key',
                  colorScale: const LegendColorScale(
                    label: 'Risk score',
                    colors: [Color(0xFF16A34A), Color(0xFFDC2626)],
                    minimumLabel: '0',
                    maximumLabel: '100',
                    type: LegendColorScaleType.piecewise,
                    segmentLabels: ['Normal', 'Critical'],
                  ),
                ),
              ),
            ).value,
          ],
          xAxis: _success(
            ChartAxisDocumentCodec.encodeXAxis(
              const XAxisConfig(label: 'Elapsed interval'),
            ),
          ).value,
          axes: [
            _success(
              ChartAxisDocumentCodec.encodeYAxis(
                YAxisConfig(position: YAxisPosition.left, label: 'Power'),
              ),
            ).value,
          ],
          theme: _success(
            ChartThemeDocumentCodec.encode(
              ChartTheme.dark.copyWith(
                backgroundColor: const Color(0xFF08111F),
                pieChartTheme: const PieChartTheme(
                  cornerRadius: 5,
                  gradient: PieGradientStyle(type: PieGradientType.radial),
                ),
              ),
            ),
          ).value,
          interaction: _success(
            ChartInteractionDocumentCodec.encode(
              const InteractionConfig(
                selection: ChartSelectionConfig(
                  operation: ChartSelectionOperation.toggle,
                  clearOnBackgroundTap: false,
                ),
              ),
            ),
          ).value,
        ),
        viewState: ChartViewState(
          visibleBounds: const ChartBoundsDocument(
            xMin: 0,
            xMax: 1,
            yMin: 140,
            yMax: 170,
          ),
          selectedSeriesId: 'power',
          selectedPointRefs: const [
            ChartPointRef(seriesId: 'power', pointIndex: 1),
          ],
          selectionExpression: ChartSelectionExpressionDocument(
            clauses: [
              ChartSelectionClauseDocument.xInterval(
                minimumInclusive: 0.25,
                maximumInclusive: 0.75,
                seriesIds: const {'power'},
              ),
              ChartSelectionClauseDocument.rectangle(
                minimumXInclusive: 0.35,
                maximumXInclusive: 0.65,
                minimumYInclusive: 145,
                maximumYInclusive: 165,
                seriesIds: const {'power'},
              ),
            ],
          ),
        ),
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(
          snapshot,
          options: const ChartDartSourceOptions(includeViewState: true),
        ),
      ).value;

      final fixture = File(
        '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
        '${Platform.pathSeparator}chart_generated_source_compile_test.dart',
      );
      await fixture.writeAsString(
        '// ignore_for_file: prefer_const_constructors\n${generated.source}',
      );
      try {
        final format = await Process.run(
          'dart',
          ['format', '--output=none', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          format.exitCode,
          0,
          reason: '${format.stdout}\n${format.stderr}',
        );

        final analyze = await Process.run(
          'dart',
          ['analyze', '--no-fatal-warnings', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          analyze.exitCode,
          0,
          reason: '${analyze.stdout}\n${analyze.stderr}',
        );
      } finally {
        if (await fixture.exists()) await fixture.delete();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'generated stacked Polar Column Dart formats and analyzes',
    () async {
      final series = <PolarColumnChartSeries>[
        PolarColumnChartSeries.fromMap(
          id: 'new',
          unit: 'orders',
          values: const {'North': 45, 'East': 38, 'South': 41},
          polarStyle: const PolarColumnStyle(
            cornerRadius: 8,
            opacity: 0.3,
            borderColor: Color(0xFF102030),
            borderWidth: 2,
            dataLabelRadialPosition: 0.68,
            dataLabelStyle: PolarLabelStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            gradient: PolarColumnGradientStyle(
              startColor: Color(0xFF38BDF8),
              endColor: Color(0xFF1D4ED8),
            ),
            shadow: PolarColumnShadowStyle(
              color: Color(0xFF172554),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 3),
              opacity: 0.28,
            ),
            animationMode: PolarColumnAnimationMode.sweep,
          ),
        ),
        PolarColumnChartSeries.fromMap(
          id: 'churn',
          unit: 'orders',
          values: const {'North': -12, 'East': -18, 'South': -9},
          polarStyle: const PolarColumnStyle(
            cornerRadius: 8,
            opacity: 0.85,
            borderColor: Color(0xFF102030),
            borderWidth: 2,
            showDataLabels: false,
          ),
        ),
      ];
      const polarConfig = PolarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: 15,
          sweepAngleDegrees: 270,
          innerRadiusFactor: 0.2,
          outerRadiusFactor: 0.9,
        ),
        angularAxis: PolarCategoryAxisConfig(
          labelOffset: 12,
          labelStyle: PolarLabelStyle(
            color: Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        radialAxis: PolarNumericAxisConfig(
          minimum: -40,
          maximum: 80,
          scaleMode: PolarRadialScaleMode.linear,
          tickCount: 6,
          labelPosition: PolarRadialLabelPosition.end,
          labelAngleOffsetDegrees: 20,
          labelOffset: 6,
          labelStyle: PolarLabelStyle(color: Color(0xFF0F766E), fontSize: 10),
        ),
        composition: PolarColumnCompositionConfig(
          mode: PolarColumnCompositionMode.stacked,
        ),
      );
      final configuration = _success(
        ChartConfigurationDocumentCodec.encodePolarChart(polarConfig),
      ).value;
      final snapshot = ChartDocumentSnapshot(
        document: ChartDocument(
          documentId: 'generated-polar-compile',
          revision: 1,
          series: [
            for (final item in series)
              _success(ChartSeriesDocumentCodec.encode(item)).value,
          ],
          xAxis: _success(
            ChartAxisDocumentCodec.encodeXAxis(const XAxisConfig()),
          ).value,
          axes: [
            _success(
              ChartAxisDocumentCodec.encodeYAxis(
                YAxisConfig(position: YAxisPosition.left),
              ),
            ).value,
          ],
          theme: _success(
            ChartThemeDocumentCodec.encode(ChartTheme.light),
          ).value,
          interaction: _success(
            ChartInteractionDocumentCodec.encode(const InteractionConfig()),
          ).value,
          configuration: configuration,
          requiredCapabilities: const {
            'chart.polar.config.v1',
            'chart.polar.multiple-series.v1',
            'chart.polar.stacked-series.v1',
            PolarChartConfig.labelAppearanceCapability,
            PolarColumnChartSeries.appearanceCapability,
          },
        ),
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(snapshot),
      ).value;

      final fixture = File(
        '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
        '${Platform.pathSeparator}polar_generated_source_compile_test.dart',
      );
      await fixture.writeAsString(
        '// ignore_for_file: prefer_const_constructors\n${generated.source}',
      );
      try {
        final format = await Process.run(
          'dart',
          ['format', '--output=none', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          format.exitCode,
          0,
          reason: '${format.stdout}\n${format.stderr}',
        );

        final analyze = await Process.run(
          'dart',
          ['analyze', '--no-fatal-warnings', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          analyze.exitCode,
          0,
          reason: '${analyze.stdout}\n${analyze.stderr}',
        );
      } finally {
        if (await fixture.exists()) await fixture.delete();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
  test('generated value summary Dart formats, analyzes, and reconstructs a '
      'value-equal config', () async {
    const valueSummary = CartesianValueSummaryConfig(
      enabled: true,
      presentation: CartesianValueSummaryPresentation.annotation(
        placement: ChartOverlayPlacement(
          anchor: Alignment.bottomLeft,
          offset: Offset(18, -30),
        ),
        draggable: true,
      ),
      valuePolicy:
          CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
      content: CartesianValueSummaryContent.automatic(
        includeTrends: true,
        includeHiddenSeries: true,
      ),
      style: CartesianValueSummaryStyle(
        backgroundColor: ChartStyleValue.none(),
        borderColor: ChartStyleValue.value(Color(0xFF334155)),
        borderWidth: ChartStyleValue.value(1.5),
        padding: ChartStyleValue.value(EdgeInsets.fromLTRB(12, 8, 12, 8)),
        textStyle: ChartStyleValue.value(
          TextStyle(color: Color(0xFF0F172A), fontSize: 12),
        ),
        shadow: ChartStyleValue.none(),
        maxWidth: ChartStyleValue.value(240),
      ),
      showSeriesAccent: false,
      announceChanges: true,
    );
    final interactionDocument = _success(
      ChartInteractionDocumentCodec.encode(
        const InteractionConfig(valueSummary: valueSummary),
      ),
    ).value;
    final snapshot = ChartDocumentSnapshot(
      document: ChartDocument(
        documentId: 'generated-value-summary-compile',
        revision: 1,
        series: [
          _success(
            ChartSeriesDocumentCodec.encode(
              const LineChartSeries(
                id: 'power',
                name: 'Power',
                points: [
                  ChartDataPoint(x: 0, y: 148),
                  ChartDataPoint(x: 1, y: 162),
                ],
              ),
            ),
          ).value,
        ],
        xAxis: _success(
          ChartAxisDocumentCodec.encodeXAxis(
            const XAxisConfig(label: 'Elapsed interval'),
          ),
        ).value,
        axes: [
          _success(
            ChartAxisDocumentCodec.encodeYAxis(
              YAxisConfig(position: YAxisPosition.left, label: 'Power'),
            ),
          ).value,
        ],
        theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
        interaction: interactionDocument,
        requiredCapabilities: const {'chart.cartesian.value-summary.v1'},
      ),
    );
    final generated = _success(
      ChartDartSourceGenerator.generate(snapshot),
    ).value;
    expect(generated.source, contains('CartesianValueSummaryConfig('));
    expect(
      generated.source,
      contains('backgroundColor: ChartStyleValue<Color>.none(),'),
    );
    expect(
      generated.source,
      contains('shadow: ChartStyleValue<BoxShadow>.none(),'),
    );
    expect(generated.warnings, isEmpty);

    // The consumed document reconstructs a value-equal config, including
    // the explicit .none() fields.
    final decoded = _success(
      ChartInteractionDocumentCodec.decode(interactionDocument),
    ).value;
    expect(decoded.valueSummary, valueSummary);
    expect(decoded.valueSummary.style.backgroundColor.isNone, isTrue);
    expect(decoded.valueSummary.style.shadow.isNone, isTrue);

    final fixture = File(
      '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
      '${Platform.pathSeparator}value_summary_generated_source_compile_test.dart',
    );
    await fixture.writeAsString(
      '// ignore_for_file: prefer_const_constructors\n${generated.source}',
    );
    try {
      final format = await Process.run(
        'dart',
        ['format', '--output=none', fixture.path],
        workingDirectory: Directory.current.path,
        runInShell: Platform.isWindows,
      );
      expect(format.exitCode, 0, reason: '${format.stdout}\n${format.stderr}');

      final analyze = await Process.run(
        'dart',
        ['analyze', '--no-fatal-warnings', fixture.path],
        workingDirectory: Directory.current.path,
        runInShell: Platform.isWindows,
      );
      expect(
        analyze.exitCode,
        0,
        reason: '${analyze.stdout}\n${analyze.stderr}',
      );
    } finally {
      if (await fixture.exists()) await fixture.delete();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'generated bar-style Dart (slice-3b emitter blocks) formats and analyzes',
    () async {
      // Series A exercises barStyle.pattern, barStyle.motion, all 10
      // previously-dropped BarLabelStyle fields (incl. nested callout), and
      // divergingRole/divergingStyle. divergingStacked layout is required for
      // the codec to preserve the diverging fields; baseline is 0 so every
      // point magnitude stays at/above the baseline.
      final diverging = const BarChartSeries(
        id: 'diverging',
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.divergingStacked,
        points: [ChartDataPoint(x: 0, y: 42), ChartDataPoint(x: 1, y: 58)],
        barStyle: BarChartStyle(
          cornerRadius: 6,
          pattern: BarPatternStyle(
            pattern: BarFillPattern.crosshatch,
            spacing: 10,
          ),
          motion: BarMotionStyle(
            order: BarAnimationOrder.centerOut,
            staggerFraction: 0.2,
          ),
        ),
        divergingRole: BarDivergingRole.negative,
        divergingStyle: BarDivergingStyle(
          showCenterLine: false,
          centerLineWidth: 2,
        ),
        labelStyle: BarLabelStyle(
          show: true,
          collisionPolicy: BarLabelCollisionPolicy.hide,
          plotEdgeAware: false,
          collisionPadding: 5,
          backgroundColor: Color(0xFF102030),
          borderColor: Color(0xFF405060),
          borderWidth: 2,
          borderRadius: 8,
          backgroundPadding: 6,
          callout: BarLabelCalloutStyle(show: true, minimumLength: 9),
          showStackTotal: true,
        ),
      );
      // Series B exercises lollipopStyle (incl. nested headBorder). Lollipop
      // marks require grouped/overlaid layout (grouped is the default).
      final lollipop = const BarChartSeries(
        id: 'lollipop',
        barWidthPercent: 0.7,
        points: [ChartDataPoint(x: 0, y: 12), ChartDataPoint(x: 1, y: 19)],
        lollipopStyle: BarLollipopStyle(
          stemWidth: 4,
          headRadius: 9,
          headBorder: BarBorderStyle(color: Color(0xFF010203), width: 2),
        ),
      );
      // Series C exercises bulletStyle (incl. the BarBulletRange list).
      // Bullet ranges require grouped layout and cannot combine with
      // lollipop/track/range values, so it lives on its own series.
      final bullet = const BarChartSeries(
        id: 'bullet',
        barWidthPercent: 0.7,
        points: [ChartDataPoint(x: 0, y: 8), ChartDataPoint(x: 1, y: 4)],
        bulletStyle: BarBulletStyle(
          cornerRadius: 4,
          ranges: [
            BarBulletRange(endValue: 5, color: Color(0xFFAA0000), label: 'low'),
            BarBulletRange(endValue: 10, color: Color(0xFF00AA00)),
          ],
        ),
      );
      final snapshot = ChartDocumentSnapshot(
        document: ChartDocument(
          documentId: 'generated-bar-style-compile',
          revision: 1,
          series: [
            _success(ChartSeriesDocumentCodec.encode(diverging)).value,
            _success(ChartSeriesDocumentCodec.encode(lollipop)).value,
            _success(ChartSeriesDocumentCodec.encode(bullet)).value,
          ],
          xAxis: _success(
            ChartAxisDocumentCodec.encodeXAxis(
              const XAxisConfig(label: 'Category'),
            ),
          ).value,
          axes: [
            _success(
              ChartAxisDocumentCodec.encodeYAxis(
                YAxisConfig(position: YAxisPosition.left, label: 'Value'),
              ),
            ).value,
          ],
          theme: _success(
            ChartThemeDocumentCodec.encode(ChartTheme.light),
          ).value,
          interaction: _success(
            ChartInteractionDocumentCodec.encode(const InteractionConfig()),
          ).value,
        ),
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(snapshot),
      ).value;

      // Confirm each of the six slice-3b blocks is genuinely emitted (i.e. not
      // silently defaulted away) so format+analyze truly covers them.
      for (final needle in const [
        'pattern: BarPatternStyle(',
        'motion: BarMotionStyle(',
        'callout: BarLabelCalloutStyle(',
        'divergingRole: BarDivergingRole.negative,',
        'divergingStyle: BarDivergingStyle(',
        'lollipopStyle: BarLollipopStyle(',
        'headBorder: BarBorderStyle(',
        'bulletStyle: BarBulletStyle(',
        'BarBulletRange(',
      ]) {
        expect(generated.source, contains(needle), reason: 'missing $needle');
      }

      final fixture = File(
        '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
        '${Platform.pathSeparator}bar_style_generated_source_compile_test.dart',
      );
      await fixture.writeAsString(
        '// ignore_for_file: prefer_const_constructors\n${generated.source}',
      );
      try {
        final format = await Process.run(
          'dart',
          ['format', '--output=none', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          format.exitCode,
          0,
          reason: '${format.stdout}\n${format.stderr}',
        );

        final analyze = await Process.run(
          'dart',
          ['analyze', '--no-fatal-warnings', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          analyze.exitCode,
          0,
          reason: '${analyze.stdout}\n${analyze.stderr}',
        );
      } finally {
        if (await fixture.exists()) await fixture.delete();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'generated rich-TextStyle annotation Dart (slice-3f) formats and analyzes',
    () async {
      // Exercises the full TextStyle field set now emitted for annotation label
      // styles (Fix A): shadows, fontFamilyFallback, textBaseline,
      // leadingDistribution, locale, fontFeatures, fontVariations, a combined
      // decoration, debugLabel, overflow, and inherit:false. Proves the emitted
      // Dart for every one of these is valid (formats + analyzes clean).
      final richStyle = AnnotationStyle(
        textStyle: TextStyle(
          inherit: false,
          color: const Color(0xFF102030),
          fontFamily: 'Inter',
          fontFamilyFallback: const ['Roboto', 'Arial'],
          letterSpacing: 0.4,
          textBaseline: TextBaseline.alphabetic,
          leadingDistribution: TextLeadingDistribution.even,
          locale: const Locale.fromSubtags(
            languageCode: 'en',
            countryCode: 'ZA',
          ),
          shadows: const [
            Shadow(
              color: Color(0x55000000),
              offset: Offset(1, 2),
              blurRadius: 3,
            ),
          ],
          fontFeatures: const [FontFeature('smcp')],
          fontVariations: const [FontVariation('wght', 650)],
          decoration: TextDecoration.combine(const [
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ]),
          decorationStyle: TextDecorationStyle.dashed,
          debugLabel: 'label-test',
          overflow: TextOverflow.fade,
        ),
      );
      final snapshot = ChartDocumentSnapshot(
        document: ChartDocument(
          documentId: 'generated-rich-textstyle-compile',
          revision: 1,
          series: [
            _success(
              ChartSeriesDocumentCodec.encode(
                const LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 148),
                    ChartDataPoint(x: 1, y: 162),
                  ],
                ),
              ),
            ).value,
          ],
          annotations: [
            _success(
              ChartAnnotationDocumentCodec.encode(
                RangeAnnotation(
                  id: 'window',
                  label: 'Target window',
                  startX: 0.5,
                  endX: 1.5,
                  style: richStyle,
                ),
              ),
            ).value,
          ],
          xAxis: _success(
            ChartAxisDocumentCodec.encodeXAxis(
              const XAxisConfig(label: 'Elapsed interval'),
            ),
          ).value,
          axes: [
            _success(
              ChartAxisDocumentCodec.encodeYAxis(
                YAxisConfig(position: YAxisPosition.left, label: 'Power'),
              ),
            ).value,
          ],
          theme: _success(
            ChartThemeDocumentCodec.encode(ChartTheme.light),
          ).value,
          interaction: _success(
            ChartInteractionDocumentCodec.encode(const InteractionConfig()),
          ).value,
        ),
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(snapshot),
      ).value;

      for (final needle in const [
        'inherit: false,',
        'shadows: [Shadow(',
        "fontFamilyFallback: ['Roboto', 'Arial'],",
        'locale: Locale.fromSubtags(',
        "fontFeatures: [FontFeature('smcp', 1)],",
        "fontVariations: [FontVariation('wght', 650.0)],",
        'decoration: TextDecoration.combine([',
        'overflow: TextOverflow.fade,',
      ]) {
        expect(generated.source, contains(needle), reason: 'missing $needle');
      }
      expect(generated.warnings, isEmpty);

      final fixture = File(
        '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
        '${Platform.pathSeparator}rich_textstyle_generated_source_compile_test.dart',
      );
      await fixture.writeAsString(
        '// ignore_for_file: prefer_const_constructors\n${generated.source}',
      );
      try {
        final format = await Process.run(
          'dart',
          ['format', '--output=none', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          format.exitCode,
          0,
          reason: '${format.stdout}\n${format.stderr}',
        );

        final analyze = await Process.run(
          'dart',
          ['analyze', '--no-fatal-warnings', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          analyze.exitCode,
          0,
          reason: '${analyze.stdout}\n${analyze.stderr}',
        );
      } finally {
        if (await fixture.exists()) await fixture.delete();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}
