// Copyright 2025 Braven Charts. All rights reserved.
// Use of this source code is governed by a BSD-style license.

import 'package:flutter/widgets.dart';
import 'package:braven_charts/src/coordinate_system/data_range.dart';
import 'package:braven_charts/src/theming/scrollbar_theme.dart';

/// Dual-purpose scrollbar for chart navigation (pan + zoom).
///
/// Provides two interaction modes:
/// - **Pan**: Drag center of handle to shift viewport
/// - **Zoom**: Drag edges of handle to resize viewport
///
/// Supports mouse, touch, and keyboard interactions with WCAG 2.1 AA accessibility.
///
/// ## Basic Usage
///
/// ```dart
/// ChartScrollbar(
///   axis: Axis.horizontal,
///   dataRange: DataRange(min: 0, max: 100),
///   viewportRange: DataRange(min: 25, max: 75),
///   onViewportChanged: (newRange) {
///     setState(() => _viewport = _viewport.withRanges(newRange, _viewport.yRange));
///   },
///   theme: ScrollbarConfig.defaultLight,
/// )
/// ```
///
/// ## Keyboard Navigation
///
/// | Key | Action | Increment |
/// |-----|--------|-----------|
/// | Arrow keys | Pan (small) | 5% of visible range |
/// | Shift + Arrow | Pan (fast) | 25% of visible range |
/// | Ctrl + Arrow | Zoom in/out | ±10% zoom level |
/// | Home | Jump to start | viewportMin = dataMin |
/// | End | Jump to end | viewportMax = dataMax |
/// | Page Up/Down | Jump (large) | 1 viewport width |
///
/// ## Interaction Zones
///
/// - **Left/Top Edge** (8px): Drag to resize viewport minimum
/// - **Right/Bottom Edge** (8px): Drag to resize viewport maximum
/// - **Center**: Drag to pan viewport (shift both min/max)
/// - **Track** (outside handle): Click to jump viewport to position
///
/// ## Performance
///
/// - Handle calculations: O(1), <0.1ms
/// - Scrollbar rendering: <1ms (RepaintBoundary isolated)
/// - Viewport updates: Throttled to 60 FPS during drag
/// - Chart re-render: <16ms (depends on data complexity)
///
/// ## Accessibility
///
/// - Keyboard navigation for all actions (WCAG 2.1.1)
/// - Screen reader support with semantic labels
/// - 4.5:1 contrast ratios for handle/track (WCAG 1.4.3)
/// - Visible focus indicator (2px solid ring)
///
/// ## See Also
///
/// - [ScrollbarConfig] - Visual and interaction configuration
/// - [ScrollbarTheme] - Theme container for X/Y scrollbars
/// - [ViewportState] - Viewport state management
/// - [InteractionConfig.showXScrollbar] - Enable flag for horizontal scrollbar
/// - [InteractionConfig.showYScrollbar] - Enable flag for vertical scrollbar
class ChartScrollbar extends StatefulWidget {
  /// Creates a dual-purpose scrollbar for chart navigation.
  ///
  /// All parameters are required except [key].
  ///
  /// The [viewportRange] must be a subset of [dataRange] (no validation enforced,
  /// but violations will cause visual artifacts).
  ///
  /// Example:
  /// ```dart
  /// ChartScrollbar(
  ///   axis: Axis.vertical,
  ///   dataRange: DataRange(min: -100, max: 500),  // Full data range
  ///   viewportRange: DataRange(min: 0, max: 100),  // Currently visible range (20% of data)
  ///   onViewportChanged: (newRange) => print('Viewport: $newRange'),
  ///   theme: ScrollbarConfig(thickness: 16.0, handleColor: Colors.blue),
  /// )
  /// ```
  const ChartScrollbar({
    super.key,
    required this.axis,
    required this.dataRange,
    required this.viewportRange,
    required this.onViewportChanged,
    required this.theme,
  });

  /// Orientation of the scrollbar (horizontal or vertical).
  ///
  /// - [Axis.horizontal]: Rendered below chart, controls X-axis range
  /// - [Axis.vertical]: Rendered to the right of chart, controls Y-axis range
  final Axis axis;

  /// Full range of data available for this axis.
  ///
  /// This defines the scrollable area. User can pan/zoom within this range
  /// but cannot exceed it.
  ///
  /// Example for time series spanning Jan 1 - Dec 31, 2024:
  /// ```dart
  /// dataRange: DataRange(
  ///   min: 0,      // Jan 1 (day 0)
  ///   max: 365,    // Dec 31 (day 365)
  /// )
  /// ```
  ///
  /// Must have span > 0 (dataRange.max > dataRange.min).
  final DataRange dataRange;

  /// Currently visible range within the data.
  ///
  /// This should be a subset of [dataRange]. The scrollbar handle size
  /// is calculated as (viewportRange.span / dataRange.span) * trackSize.
  ///
  /// Example (viewing Feb 1-28 in above time series):
  /// ```dart
  /// viewportRange: DataRange(
  ///   min: 31,     // Feb 1 (day 31)
  ///   max: 59,     // Feb 28 (day 59)
  /// )
  /// // Handle size: (28/365) * trackSize ≈ 7.7% of track
  /// ```
  ///
  /// When user interacts with scrollbar, [onViewportChanged] fires with
  /// updated viewportRange. Parent widget should rebuild with new range.
  final DataRange viewportRange;

  /// Callback fired when user changes viewport via scrollbar interaction.
  ///
  /// Called on:
  /// - Handle drag (pan or zoom)
  /// - Track click (jump to position)
  /// - Keyboard navigation (arrow keys, page up/down, home/end)
  ///
  /// **Performance**: Throttled to max 60 FPS during drag to prevent chart jank.
  /// Visual handle position updates immediately, but this callback only fires
  /// every 16ms max during rapid pointer events.
  ///
  /// **Implementation Pattern**:
  /// ```dart
  /// ChartScrollbar(
  ///   // ...
  ///   onViewportChanged: (newRange) {
  ///     // Update viewport state immutably
  ///     setState(() {
  ///       _viewportState = _viewportState.withRanges(
  ///         axis == Axis.horizontal ? newRange : _viewportState.xRange,
  ///         axis == Axis.vertical ? newRange : _viewportState.yRange,
  ///       );
  ///     });
  ///   },
  /// )
  /// ```
  ///
  /// **Final Update**: Always fires on drag end (even if throttled during drag),
  /// ensuring viewport syncs with final handle position.
  final ValueChanged<DataRange> onViewportChanged;

  /// Visual configuration and interaction settings.
  ///
  /// Controls:
  /// - Visual properties (colors, thickness, border radius)
  /// - Interaction behavior (edge grip width, auto-hide, zoom limits)
  ///
  /// Typically provided from ChartTheme:
  /// ```dart
  /// theme: chartTheme.scrollbarTheme.xAxisScrollbar,
  /// ```
  ///
  /// Or customized:
  /// ```dart
  /// theme: ScrollbarConfig(
  ///   thickness: 16.0,
  ///   handleColor: Colors.blue[300]!,
  ///   autoHide: false,  // Always visible
  /// ),
  /// ```
  final ScrollbarConfig theme;

  @override
  State<ChartScrollbar> createState() => _ChartScrollbarState();
}

// NOTE: _ChartScrollbarState implementation is internal (not part of contract).
// Only ChartScrollbar public API is documented here.
