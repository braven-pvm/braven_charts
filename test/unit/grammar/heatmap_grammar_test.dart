// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class HeatmapRow {
  const HeatmapRow({
    required this.x,
    required this.y,
    required this.value,
    required this.key,
    required this.label,
    this.missing = false,
  });

  final double x;
  final double y;
  final double value;
  final String key;
  final String label;
  final bool missing;
}

double rowX(HeatmapRow row) => row.x;
double rowY(HeatmapRow row) => row.y;
double rowValue(HeatmapRow row) => row.value;
String? rowKey(HeatmapRow row) => row.key;
String? rowLabel(HeatmapRow row) => row.label;
bool rowMissing(HeatmapRow row) => row.missing;

const rows = <HeatmapRow>[
  HeatmapRow(x: 0, y: 0, value: 12, key: 'mon-am', label: '12'),
  HeatmapRow(
    x: 1,
    y: 0,
    value: 999,
    key: 'tue-am',
    label: 'missing',
    missing: true,
  ),
  HeatmapRow(x: 0, y: 1, value: 27, key: 'mon-pm', label: '27'),
];

final colorScale = HeatmapColorScale.diverging(
  lowColor: const Color(0xFF2563EB),
  midpointColor: const Color(0xFFF8FAFC),
  highColor: const Color(0xFFDC2626),
  midpoint: 20,
  minimumValue: 0,
  maximumValue: 40,
  missingColor: const Color(0xFFE2E8F0),
  label: 'Temperature',
  unit: 'C',
);
const emptyValueStyle = HeatmapEmptyValueStyle(
  fillColor: Color(0xFFE5E7EB),
  legendLabel: 'No readings',
);

Matcher throwsGrammarCode(GrammarDiagnosticCode code) => throwsA(
  isA<GrammarSpecException>().having((error) => error.code, 'code', code),
);

YAxisConfig defaultAxis() =>
    YAxisConfig(position: YAxisPosition.left).copyWith(id: 'axis-0');

void main() {
  group('Heatmap grammar parity', () {
    test('HeatmapMark lowers to the exact native Heatmap series', () {
      final lowered = PlotSpec<HeatmapRow>(
        data: rows,
        marks: <Mark<HeatmapRow>>[
          HeatmapMark<HeatmapRow>(
            id: 'temperature',
            name: 'Temperature',
            x: rowX,
            y: rowY,
            value: rowValue,
            missing: rowMissing,
            pointKey: rowKey,
            label: rowLabel,
            colorScale: colorScale,
            emptyValueStyle: emptyValueStyle,
            unit: 'C',
            cellWidth: 0.9,
            cellHeight: 0.8,
            gapFraction: 0.1,
            borderColor: const Color(0xFF334155),
            borderWidth: 1,
            cornerRadius: 3,
            showCellLabels: true,
            cellLabelColor: const Color(0xFF0F172A),
            cellLabelFontSize: 10,
            valueFilter: const HeatmapValueFilter(
              minimumValue: 10,
              maximumValue: 20,
              mode: HeatmapValueFilterMode.hide,
            ),
          ),
        ],
      ).lower();

      final axis = defaultAxis();
      expect(lowered.series, <ChartSeries>[
        HeatmapChartSeries(
          id: 'temperature',
          name: 'Temperature',
          points: <HeatmapDataPoint>[
            HeatmapDataPoint(
              x: 0,
              y: 0,
              value: 12,
              pointKey: 'mon-am',
              label: '12',
            ),
            HeatmapDataPoint.missing(
              x: 1,
              y: 0,
              pointKey: 'tue-am',
              label: 'missing',
            ),
            HeatmapDataPoint(
              x: 0,
              y: 1,
              value: 27,
              pointKey: 'mon-pm',
              label: '27',
            ),
          ],
          colorScale: colorScale,
          emptyValueStyle: emptyValueStyle,
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          unit: 'C',
          cellWidth: 0.9,
          cellHeight: 0.8,
          gapFraction: 0.1,
          borderColor: const Color(0xFF334155),
          borderWidth: 1,
          cornerRadius: 3,
          showCellLabels: true,
          cellLabelColor: const Color(0xFF0F172A),
          cellLabelFontSize: 10,
          valueFilter: const HeatmapValueFilter(
            minimumValue: 10,
            maximumValue: 20,
            mode: HeatmapValueFilterMode.hide,
          ),
        ),
      ]);
      expect(lowered.yAxes, <YAxisConfig>[axis]);
      expect(lowered.annotations, isEmpty);
    });

    test('geomHeatmap is exactly the hand-written mark', () {
      final built = BravenChart.of(rows)
          .x(rowX)
          .y(rowY)
          .geomHeatmap(
            id: 'temperature',
            name: 'Temperature',
            value: rowValue,
            missing: rowMissing,
            pointKey: rowKey,
            label: rowLabel,
            colorScale: colorScale,
            emptyValueStyle: emptyValueStyle,
            unit: 'C',
            cornerRadius: 2,
            showCellLabels: true,
          )
          .toSpec();

      expect(
        built,
        PlotSpec<HeatmapRow>(
          data: rows,
          marks: <Mark<HeatmapRow>>[
            HeatmapMark<HeatmapRow>(
              id: 'temperature',
              name: 'Temperature',
              x: rowX,
              y: rowY,
              value: rowValue,
              missing: rowMissing,
              pointKey: rowKey,
              label: rowLabel,
              colorScale: colorScale,
              emptyValueStyle: emptyValueStyle,
              unit: 'C',
              cornerRadius: 2,
              showCellLabels: true,
            ),
          ],
        ),
      );
    });

    test('reference annotations remain valid beside one Heatmap', () {
      final lowered = PlotSpec<HeatmapRow>(
        data: rows,
        marks: <Mark<HeatmapRow>>[
          HeatmapMark<HeatmapRow>(
            x: rowX,
            y: rowY,
            value: rowValue,
            colorScale: colorScale,
          ),
          const ThresholdMark<HeatmapRow>(
            value: 0.5,
            axis: AnnotationAxis.x,
            label: 'Current day',
          ),
        ],
      ).lower();

      expect(lowered.series.single, isA<HeatmapChartSeries>());
      expect(lowered.annotations.single, isA<ThresholdAnnotation>());
    });
  });

  group('Heatmap grammar diagnostics', () {
    test('missing rows do not evaluate their value accessor', () {
      var reads = 0;
      num countedValue(HeatmapRow row) {
        reads++;
        return row.value;
      }

      final lowered = PlotSpec<HeatmapRow>(
        data: rows,
        marks: <Mark<HeatmapRow>>[
          HeatmapMark<HeatmapRow>(
            x: rowX,
            y: rowY,
            value: countedValue,
            missing: rowMissing,
            colorScale: colorScale,
          ),
        ],
      ).lower();

      expect(reads, 2);
      expect(
        (lowered.series.single as HeatmapChartSeries).cells[1].isMissing,
        isTrue,
      );
    });

    test('multiple Heatmaps are an explicit Phase-1 composition error', () {
      expect(
        () => PlotSpec<HeatmapRow>(
          data: rows,
          marks: <Mark<HeatmapRow>>[
            HeatmapMark<HeatmapRow>(
              x: rowX,
              y: rowY,
              value: rowValue,
              colorScale: colorScale,
            ),
            HeatmapMark<HeatmapRow>(
              x: rowX,
              y: rowY,
              value: rowValue,
              colorScale: colorScale,
            ),
          ],
        ).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unsupportedHeatmapComposition),
      );
    });

    test(
      'Heatmap plus ordinary Cartesian geometry is explicit, not dropped',
      () {
        expect(
          () => PlotSpec<HeatmapRow>(
            data: rows,
            marks: <Mark<HeatmapRow>>[
              HeatmapMark<HeatmapRow>(
                x: rowX,
                y: rowY,
                value: rowValue,
                colorScale: colorScale,
              ),
              const LineMark<HeatmapRow>(x: rowX, y: rowValue),
            ],
          ).lower(),
          throwsGrammarCode(
            GrammarDiagnosticCode.unsupportedHeatmapComposition,
          ),
        );
      },
    );

    test('duplicate cell identity reports the offending Heatmap row', () {
      const duplicateRows = <HeatmapRow>[
        HeatmapRow(x: 0, y: 0, value: 1, key: 'same', label: 'A'),
        HeatmapRow(x: 1, y: 1, value: 2, key: 'same', label: 'B'),
      ];
      expect(
        () => PlotSpec<HeatmapRow>(
          data: duplicateRows,
          marks: <Mark<HeatmapRow>>[
            HeatmapMark<HeatmapRow>(
              id: 'matrix',
              x: rowX,
              y: rowY,
              value: rowValue,
              pointKey: rowKey,
              colorScale: colorScale,
            ),
          ],
        ).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidHeatmapRow),
      );
    });

    test('invalid cell style beats the empty-data guard', () {
      expect(
        () => PlotSpec<HeatmapRow>(
          data: const <HeatmapRow>[],
          marks: <Mark<HeatmapRow>>[
            HeatmapMark<HeatmapRow>(
              x: rowX,
              y: rowY,
              value: rowValue,
              colorScale: colorScale,
              gapFraction: 1,
            ),
          ],
        ).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidHeatmapConfiguration),
      );
    });

    test(
      'category coordinates must be integer centres inside both domains',
      () {
        const invalidRows = <HeatmapRow>[
          HeatmapRow(x: 1.5, y: 0, value: 1, key: 'bad', label: 'Bad'),
        ];
        expect(
          () => PlotSpec<HeatmapRow>(
            data: invalidRows,
            marks: <Mark<HeatmapRow>>[
              HeatmapMark<HeatmapRow>(
                x: rowX,
                y: rowY,
                value: rowValue,
                colorScale: colorScale,
                yAxisId: 'rows',
              ),
            ],
            xAxis: const XAxisConfig(
              categoryAxis: CategoryAxisConfig(
                categories: <String>['Mon', 'Tue'],
              ),
            ),
            yAxes: <YAxisConfig>[
              YAxisConfig.withId(
                id: 'rows',
                position: YAxisPosition.left,
                categoryAxis: const CategoryAxisConfig(
                  categories: <String>['AM', 'PM'],
                ),
              ),
            ],
          ).lower(),
          throwsGrammarCode(GrammarDiagnosticCode.invalidHeatmapConfiguration),
        );
      },
    );

    test('log validation applies to coordinates, not the measured value', () {
      const negativeMeasure = <HeatmapRow>[
        HeatmapRow(x: 1, y: 1, value: -50, key: 'valid', label: 'Valid'),
      ];
      final lowered = PlotSpec<HeatmapRow>(
        data: negativeMeasure,
        marks: <Mark<HeatmapRow>>[
          HeatmapMark<HeatmapRow>(
            x: rowX,
            y: rowY,
            value: rowValue,
            colorScale: colorScale,
          ),
        ],
        xAxis: const XAxisConfig(scaleType: AxisScaleType.log),
        yAxes: <YAxisConfig>[
          YAxisConfig(
            position: YAxisPosition.left,
            scaleType: AxisScaleType.log,
          ),
        ],
      ).lower();
      expect(
        (lowered.series.single as HeatmapChartSeries).cells.single.value,
        -50,
      );

      const invalidCoordinate = <HeatmapRow>[
        HeatmapRow(x: 0, y: 1, value: 50, key: 'invalid', label: 'Invalid'),
      ];
      expect(
        () => PlotSpec<HeatmapRow>(
          data: invalidCoordinate,
          marks: <Mark<HeatmapRow>>[
            HeatmapMark<HeatmapRow>(
              x: rowX,
              y: rowY,
              value: rowValue,
              colorScale: colorScale,
            ),
          ],
          xAxis: const XAxisConfig(scaleType: AxisScaleType.log),
        ).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.nonPositiveLogValue),
      );
    });
  });
}
