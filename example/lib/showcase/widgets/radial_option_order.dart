// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

/// Canonical section order shared by every radial-chart showcase.
///
/// Keeping this order in one place prevents Pie, Donut, and Concentric Donut
/// from drifting into different testing workflows as their option sets grow.
enum RadialOptionSectionKind {
  chartTheme,
  dataLabels,
  geometry,
  sliceAppearance,
  selection,
  motion,
  smallCategories,
  centerContent,
  legend,
  interaction,
  demoData,
  guidance,
}

/// One option-panel section tagged with its shared radial purpose.
class RadialOptionEntry {
  const RadialOptionEntry(this.kind, this.child);

  final RadialOptionSectionKind kind;
  final Widget child;
}

/// Returns radial option sections in the same order on every showcase page.
///
/// Entries with the same [RadialOptionSectionKind] retain their source order,
/// which lets Concentric Donut keep several focused geometry subsections.
List<Widget> orderRadialOptionSections(Iterable<RadialOptionEntry> entries) {
  final indexed = entries.indexed.toList(growable: false)
    ..sort((left, right) {
      final byKind = left.$2.kind.index.compareTo(right.$2.kind.index);
      return byKind != 0 ? byKind : left.$1.compareTo(right.$1);
    });
  return [for (final entry in indexed) entry.$2.child];
}
