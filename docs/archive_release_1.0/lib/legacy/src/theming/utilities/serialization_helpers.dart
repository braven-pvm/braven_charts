/// Serialization utilities for theming system.
///
/// Provides helpers for converting between Dart types and JSON-serializable
/// formats, following the theme JSON schema v1.0 specification.
library;

import 'package:flutter/painting.dart';

/// Parses a color string in #AARRGGBB format.
///
/// Returns the parsed [Color] or null if the format is invalid.
///
/// Valid formats:
/// - `#AARRGGBB` (8 hex digits with alpha)
/// - Leading `#` is required
/// - All digits must be valid hexadecimal (0-9, A-F)
///
/// Examples:
/// ```dart
/// parseColor('#FFFFFFFF'); // white, fully opaque
/// parseColor('#80FF0000'); // red, 50% transparent
/// parseColor('#FF123456'); // custom color
/// parseColor('FFFFFFFF');  // null (missing #)
/// parseColor('#FFF');      // null (wrong length)
/// ```
Color? parseColor(String? colorString) {
  if (colorString == null) return null;

  // Must start with # and have exactly 8 hex digits
  if (!colorString.startsWith('#') || colorString.length != 9) {
    return null;
  }

  // Parse hex string (remove #)
  final hexString = colorString.substring(1);
  final hexValue = int.tryParse(hexString, radix: 16);

  if (hexValue == null) return null;

  // AARRGGBB format
  return Color(hexValue);
}

/// Converts a [Color] to #AARRGGBB hex string format.
///
/// Returns an 8-character uppercase hex string with leading `#`.
///
/// Examples:
/// ```dart
/// colorToHex(Color(0xFFFFFFFF)); // '#FFFFFFFF'
/// colorToHex(Color(0x80FF0000)); // '#80FF0000'
/// colorToHex(Color(0xFF123456)); // '#FF123456'
/// ```
String colorToHex(Color color) {
  // Extract ARGB components and format as 8-digit hex
  final hex = color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');
  return '#$hex';
}

/// Parses [EdgeInsets] from a JSON map.
///
/// Returns the parsed [EdgeInsets] or null if the map is invalid.
///
/// Required keys: `top`, `right`, `bottom`, `left`
/// All values must be numbers (int or double).
///
/// Examples:
/// ```dart
/// parseEdgeInsets({'top': 16, 'right': 16, 'bottom': 16, 'left': 16});
/// // EdgeInsets.all(16)
///
/// parseEdgeInsets({'top': 10, 'right': 20, 'bottom': 10, 'left': 20});
/// // EdgeInsets.symmetric(vertical: 10, horizontal: 20)
///
/// parseEdgeInsets({'top': 1, 'right': 2, 'bottom': 3, 'left': 4});
/// // EdgeInsets.only(top: 1, right: 2, bottom: 3, left: 4)
///
/// parseEdgeInsets({'top': 10}); // null (missing required keys)
/// parseEdgeInsets(null);         // null
/// ```
EdgeInsets? parseEdgeInsets(Map<String, dynamic>? json) {
  if (json == null) return null;

  // All four keys are required
  final top = json['top'];
  final right = json['right'];
  final bottom = json['bottom'];
  final left = json['left'];

  if (top == null || right == null || bottom == null || left == null) {
    return null;
  }

  // Convert to doubles (handles both int and double)
  if (top is! num || right is! num || bottom is! num || left is! num) {
    return null;
  }

  return EdgeInsets.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right.toDouble(),
    bottom.toDouble(),
  );
}

/// Converts [EdgeInsets] to a JSON-serializable map.
///
/// Returns a map with keys: `top`, `right`, `bottom`, `left`
///
/// Examples:
/// ```dart
/// edgeInsetsToJson(EdgeInsets.all(16));
/// // {'top': 16.0, 'right': 16.0, 'bottom': 16.0, 'left': 16.0}
///
/// edgeInsetsToJson(EdgeInsets.symmetric(vertical: 10, horizontal: 20));
/// // {'top': 10.0, 'right': 20.0, 'bottom': 10.0, 'left': 20.0}
///
/// edgeInsetsToJson(EdgeInsets.only(top: 1, right: 2, bottom: 3, left: 4));
/// // {'top': 1.0, 'right': 2.0, 'bottom': 3.0, 'left': 4.0}
/// ```
Map<String, double> edgeInsetsToJson(EdgeInsets insets) {
  return {
    'top': insets.top,
    'right': insets.right,
    'bottom': insets.bottom,
    'left': insets.left,
  };
}
