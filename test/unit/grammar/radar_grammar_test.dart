// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Radar grammar authoring, lowering, and composition diagnostics.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ProfileRow {
  const ProfileRow(this.category, this.budget, this.actual);

  final String category;
  final double budget;
  final double actual;
}

Object? profileCategory(ProfileRow row) => row.category;
Object? shiftedProfileCategory(ProfileRow row) => '${row.category} shifted';
double profileBudget(ProfileRow row) => row.budget;
double profileActual(ProfileRow row) => row.actual;

const profiles = <ProfileRow>[
  ProfileRow('Sales', 80, 68),
  ProfileRow('Marketing', 45, 61),
  ProfileRow('Development', 72, 84),
];

Matcher throwsGrammarCode(GrammarDiagnosticCode code) => throwsA(
  isA<GrammarSpecException>().having(
    (error) => error.code,
    'diagnostic code',
    code,
  ),
);

void main() {
  test('geomRadar lowers aligned profiles and the shared Radar config', () {
    const config = RadarChartConfig(
      pane: PolarPaneConfig(startAngleDegrees: -75),
      radialAxis: RadarNumericAxisConfig(maximum: 100, tickCount: 6),
    );
    const budgetStyle = RadarSeriesStyle(
      strokeWidth: 3,
      fillOpacity: 0.2,
      markerRadius: 4,
    );

    final spec = BravenChart.of(profiles)
        .geomRadar(
          category: profileCategory,
          value: profileBudget,
          id: 'budget',
          name: 'Budget',
          unit: 'k USD',
          color: const Color(0xFF2563EB),
          style: budgetStyle,
        )
        .geomRadar(
          category: profileCategory,
          value: profileActual,
          id: 'actual',
          name: 'Actual',
          unit: 'k USD',
        )
        .radarConfig(config)
        .toSpec();

    expect(spec.marks, hasLength(2));
    expect(spec.marks.first, isA<RadarMark<ProfileRow>>());
    expect(spec.radar, config);

    final lowered = spec.lower();
    expect(lowered.radarChartConfig, config);
    expect(lowered.series, hasLength(2));
    final budget = lowered.series.first as RadarChartSeries;
    final actual = lowered.series.last as RadarChartSeries;
    expect(budget.id, 'budget');
    expect(budget.name, 'Budget');
    expect(budget.unit, 'k USD');
    expect(budget.radarStyle, budgetStyle);
    expect(budget.points.map((point) => point.label), <String>[
      'Sales',
      'Marketing',
      'Development',
    ]);
    expect(budget.points.map((point) => point.y), <double>[80, 45, 72]);
    expect(actual.points.map((point) => point.y), <double>[68, 61, 84]);
  });

  test('misaligned Radar profiles fail with an actionable diagnostic', () {
    final spec = BravenChart.of(profiles)
        .geomRadar(category: profileCategory, value: profileBudget)
        .geomRadar(category: shiftedProfileCategory, value: profileActual)
        .toSpec();

    expect(
      spec.lower,
      throwsGrammarCode(GrammarDiagnosticCode.invalidRadarComposition),
    );
  });

  test('radarConfig refuses a non-Radar grammar', () {
    final spec = BravenChart.of(profiles)
        .geomLine(x: profileBudget, y: profileActual)
        .radarConfig(const RadarChartConfig())
        .toSpec();

    expect(
      spec.lower,
      throwsGrammarCode(GrammarDiagnosticCode.radarConfigOnNonRadarSpec),
    );
  });
}
