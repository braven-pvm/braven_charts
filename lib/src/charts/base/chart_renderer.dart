/// Chart rendering utilities for marker shapes, gradients, and path pooling
library;

import 'dart:math' show pi, cos, sin;
import 'dart:ui' show Canvas, Color, Offset, Paint, Path, Rect, Shader;

import 'package:flutter/painting.dart' show LinearGradient, Alignment;

import 'chart_config.dart' show MarkerShape;

/// Shared rendering utilities for chart types
///
/// Provides optimized rendering with:
/// - Marker shape generation (circle, square, triangle, diamond, cross, plus)
/// - Gradient shader caching for area fills
/// - Object pooling for marker paths
///
/// Constitutional requirement: Performance optimization
class ChartRenderer {
  /// Creates a chart renderer
  ChartRenderer();

  /// Cache for gradient shaders to avoid recreation
  final Map<String, Shader> _shaderCache = {};

  /// Object pools for marker paths, organized by shape
  final Map<MarkerShape, List<Path>> _pathPools = {};

  /// Maximum number of paths to keep in each pool
  static const int _maxPoolSize = 20;

  /// Draws a marker at the specified position
  ///
  /// Supports all MarkerShape types except 'none'.
  /// Uses object pooling to reuse Path objects for performance.
  ///
  /// Parameters:
  /// - [canvas]: Canvas to draw on
  /// - [shape]: Shape of the marker
  /// - [position]: Center position of the marker
  /// - [size]: Size (diameter/width) of the marker
  /// - [paint]: Paint style for the marker
  void drawMarker({
    required Canvas canvas,
    required MarkerShape shape,
    required Offset position,
    required double size,
    required Paint paint,
  }) {
    if (shape == MarkerShape.none) {
      return; // Don't render 'none' markers
    }

    final path = getMarkerPath(shape, position, size);
    
    if (shape == MarkerShape.circle) {
      // Use drawCircle for better performance
      canvas.drawCircle(position, size / 2, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  /// Gets a marker path for the specified shape
  ///
  /// Returns a Path object from the pool or creates a new one.
  /// The path is configured for the given shape, position, and size.
  ///
  /// Note: Paths are pooled per shape type for performance.
  Path getMarkerPath(MarkerShape shape, Offset position, double size) {
    Path path;

    // Try to get from pool
    final pool = _pathPools[shape];
    if (pool != null && pool.isNotEmpty) {
      path = pool.removeLast();
      path.reset();
    } else {
      path = Path();
    }

    // Generate path based on shape
    switch (shape) {
      case MarkerShape.circle:
        // For circle, we create a simple rectangular bounds path
        // (actual rendering uses drawCircle for performance)
        final radius = size / 2;
        path.addOval(Rect.fromCircle(center: position, radius: radius));
        break;

      case MarkerShape.square:
        path.addRect(
          Rect.fromCenter(center: position, width: size, height: size),
        );
        break;

      case MarkerShape.triangle:
        final halfSize = size / 2;
        final height = size * 0.866; // sqrt(3)/2 for equilateral triangle
        path.moveTo(position.dx, position.dy - height / 2);
        path.lineTo(position.dx - halfSize, position.dy + height / 2);
        path.lineTo(position.dx + halfSize, position.dy + height / 2);
        path.close();
        break;

      case MarkerShape.diamond:
        final halfSize = size / 2;
        path.moveTo(position.dx, position.dy - halfSize); // Top
        path.lineTo(position.dx + halfSize, position.dy); // Right
        path.lineTo(position.dx, position.dy + halfSize); // Bottom
        path.lineTo(position.dx - halfSize, position.dy); // Left
        path.close();
        break;

      case MarkerShape.cross:
        final thickness = size * 0.2;
        // Vertical bar
        path.addRect(
          Rect.fromCenter(
            center: position,
            width: thickness,
            height: size,
          ),
        );
        // Horizontal bar
        path.addRect(
          Rect.fromCenter(
            center: position,
            width: size,
            height: thickness,
          ),
        );
        break;

      case MarkerShape.plus:
        // Plus is a cross rotated 45 degrees
        final diagonal = (size / 2) * 1.414; // sqrt(2)

        // Diagonal from top-left to bottom-right
        path.moveTo(
          position.dx - diagonal * cos(pi / 4),
          position.dy - diagonal * sin(pi / 4),
        );
        path.lineTo(
          position.dx + diagonal * cos(pi / 4),
          position.dy + diagonal * sin(pi / 4),
        );

        // Diagonal from top-right to bottom-left
        path.moveTo(
          position.dx + diagonal * cos(pi / 4),
          position.dy - diagonal * sin(pi / 4),
        );
        path.lineTo(
          position.dx - diagonal * cos(pi / 4),
          position.dy + diagonal * sin(pi / 4),
        );
        break;

      case MarkerShape.none:
        // No path for 'none' marker
        break;
    }

    return path;
  }

  /// Returns a path to the pool for reuse
  ///
  /// Helps reduce allocations by recycling Path objects.
  /// Pool has a maximum size to prevent memory bloat.
  void returnPathToPool(Path path) {
    // Determine which shape this path belongs to (simplified - just use circle pool)
    // In practice, you might want to track this when creating paths
    final pool = _pathPools.putIfAbsent(MarkerShape.circle, () => []);
    
    if (pool.length < _maxPoolSize) {
      path.reset();
      pool.add(path);
    }
  }

  /// Creates a gradient shader for area fills
  ///
  /// Shaders are cached to avoid recreation on every frame.
  /// Cache key includes bounds, colors, and orientation.
  ///
  /// Parameters:
  /// - [bounds]: Rectangle defining the gradient area
  /// - [startColor]: Starting color of the gradient
  /// - [endColor]: Ending color of the gradient
  /// - [vertical]: true for top-to-bottom, false for left-to-right
  ///
  /// Returns: Cached or newly created Shader instance
  Shader createGradientShader({
    required Rect bounds,
    required Color startColor,
    required Color endColor,
    bool vertical = true,
  }) {
    // Create cache key
    final cacheKey = '${bounds.left},${bounds.top},${bounds.right},${bounds.bottom}'
        '_${startColor.value}_${endColor.value}_$vertical';

    // Return cached shader if available
    if (_shaderCache.containsKey(cacheKey)) {
      return _shaderCache[cacheKey]!;
    }

    // Create new shader using LinearGradient
    final gradient = LinearGradient(
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: [startColor, endColor],
    );

    final shader = gradient.createShader(bounds);
    _shaderCache[cacheKey] = shader;

    return shader;
  }

  /// Clears the gradient shader cache
  ///
  /// Use this when theme changes or when you want to free memory.
  void clearCache() {
    _shaderCache.clear();
  }

  /// Clears all pooled path objects
  ///
  /// Use this to free memory when renderer is no longer needed.
  void clearPathPool() {
    _pathPools.clear();
  }

  /// Gets the current size of the path pool for a shape
  ///
  /// Useful for debugging and testing pool behavior.
  int getPoolSize(MarkerShape shape) {
    return _pathPools[shape]?.length ?? 0;
  }
}
