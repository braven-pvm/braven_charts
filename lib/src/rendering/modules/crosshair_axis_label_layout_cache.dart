// Copyright (c) 2025 braven_charts. All rights reserved.

import 'dart:collection';

import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:flutter/painting.dart';

/// Ambient inputs used to resolve a crosshair axis-label layout request.
@immutable
class CrosshairAxisLabelLayoutEnvironment {
  const CrosshairAxisLabelLayoutEnvironment({
    this.textDirection = TextDirection.ltr,
    this.locale,
    this.textScaler = TextScaler.noScaling,
    this.devicePixelRatio = 1,
  }) : assert(devicePixelRatio > 0);

  final TextDirection textDirection;
  final Locale? locale;
  final TextScaler textScaler;
  final double devicePixelRatio;
}

/// Complete compatibility key for one crosshair axis-label layout.
@immutable
class CrosshairAxisLabelLayoutRequest {
  const CrosshairAxisLabelLayoutRequest({
    required this.text,
    required this.style,
    required this.textDirection,
    this.locale,
    this.textScaler = TextScaler.noScaling,
    this.devicePixelRatio = 1,
    this.minWidth = 0,
    this.maxWidth = double.infinity,
  }) : assert(devicePixelRatio > 0),
       assert(minWidth >= 0),
       assert(maxWidth >= minWidth);

  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final TextScaler textScaler;
  final double devicePixelRatio;
  final double minWidth;
  final double maxWidth;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CrosshairAxisLabelLayoutRequest &&
            text == other.text &&
            style == other.style &&
            textDirection == other.textDirection &&
            locale == other.locale &&
            textScaler == other.textScaler &&
            devicePixelRatio == other.devicePixelRatio &&
            minWidth == other.minWidth &&
            maxWidth == other.maxWidth;
  }

  @override
  int get hashCode => Object.hash(
    text,
    style,
    textDirection,
    locale,
    textScaler,
    devicePixelRatio,
    minWidth,
    maxWidth,
  );
}

/// Bounded least-recently-used cache of laid-out axis-label painters.
class CrosshairAxisLabelLayoutCache {
  CrosshairAxisLabelLayoutCache({this.capacity = 16}) : assert(capacity > 0);

  final int capacity;
  final LinkedHashMap<CrosshairAxisLabelLayoutRequest, TextPainter> _entries =
      LinkedHashMap<CrosshairAxisLabelLayoutRequest, TextPainter>();

  var _hitCount = 0;
  var _missCount = 0;
  var _disposedPainterCount = 0;
  var _isDisposed = false;

  @visibleForTesting
  int get debugEntryCount => _entries.length;

  @visibleForTesting
  int get debugHitCount => _hitCount;

  @visibleForTesting
  int get debugMissCount => _missCount;

  @visibleForTesting
  int get debugDisposedPainterCount => _disposedPainterCount;

  TextPainter layout(CrosshairAxisLabelLayoutRequest request) {
    if (_isDisposed) {
      throw StateError('CrosshairAxisLabelLayoutCache has been disposed.');
    }

    final cached = _entries.remove(request);
    if (cached != null) {
      _entries[request] = cached;
      _hitCount++;
      return cached;
    }

    _missCount++;
    final painter = TextPainter(
      text: TextSpan(text: request.text, style: request.style),
      textDirection: request.textDirection,
      locale: request.locale,
      textScaler: request.textScaler,
    )..layout(minWidth: request.minWidth, maxWidth: request.maxWidth);
    _entries[request] = painter;

    if (_entries.length > capacity) {
      final oldestRequest = _entries.keys.first;
      final oldestPainter = _entries.remove(oldestRequest)!;
      oldestPainter.dispose();
      _disposedPainterCount++;
    }

    return painter;
  }

  void clear() {
    for (final painter in _entries.values) {
      painter.dispose();
      _disposedPainterCount++;
    }
    _entries.clear();
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    clear();
  }
}
