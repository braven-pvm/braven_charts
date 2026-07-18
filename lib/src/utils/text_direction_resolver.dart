// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show TextDirection;

/// Resolves the reading direction of chart-owned canvas text.
///
/// Canvas painters do not receive Flutter's automatic bidi paragraph handling
/// unless a [TextDirection] is supplied explicitly. Strong RTL characters win;
/// otherwise the ambient direction remains the fallback for numbers and neutral
/// punctuation.
TextDirection resolveChartTextDirection(
  String text, {
  TextDirection fallback = TextDirection.ltr,
}) {
  for (final rune in text.runes) {
    if (_isStrongRtl(rune)) return TextDirection.rtl;
    if (_isStrongLtr(rune)) return TextDirection.ltr;
  }
  return fallback;
}

bool _isStrongRtl(int rune) =>
    (rune >= 0x0590 && rune <= 0x08FF) ||
    (rune >= 0xFB1D && rune <= 0xFDFF) ||
    (rune >= 0xFE70 && rune <= 0xFEFF) ||
    (rune >= 0x10800 && rune <= 0x10FFF) ||
    (rune >= 0x1E800 && rune <= 0x1EEFF);

bool _isStrongLtr(int rune) =>
    (rune >= 0x0041 && rune <= 0x005A) ||
    (rune >= 0x0061 && rune <= 0x007A) ||
    (rune >= 0x00C0 && rune <= 0x02AF) ||
    (rune >= 0x0370 && rune <= 0x058F);
