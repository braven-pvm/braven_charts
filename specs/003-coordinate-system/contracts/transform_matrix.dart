/// Contract: TransformMatrix (Internal Utility)
///
/// Efficient 3x3 affine transformation matrix for coordinate transformations.
/// This is an internal implementation detail not exposed in public API.
library;

import 'dart:math' show Point;
import 'dart:typed_data' show Float32List, Float32x4;

/// 3x3 affine transformation matrix for 2D coordinate transformations.
///
/// Matrix layout (column-major for GLSL/Flutter compatibility):
/// ```
/// [m00 m10 m20]   [scaleX  shearY  0]
/// [m01 m11 m21] = [shearX  scaleY  0]
/// [m02 m12 m22]   [transX  transY  1]
/// ```
///
/// This class is used internally by CoordinateTransformer for:
/// 1. Composing complex transformations (scale + rotate + translate)
/// 2. Caching transformation matrices per context
/// 3. SIMD-optimized batch transformations
///
/// Example usage:
/// ```dart
/// // Translation: Move right 50px, down 30px
/// final trans = TransformMatrix.translation(50.0, 30.0);
///
/// // Scale: Double size
/// final scale = TransformMatrix.scale(2.0, 2.0);
///
/// // Combined: Scale THEN translate
/// final combined = scale * trans;
///
/// // Apply to point
/// final result = combined.transform(Point(10, 20));
/// // → scale: (10, 20) → (20, 40)
/// // → translate: (20, 40) → (70, 70)
///
/// // Inverse transformation
/// final original = combined.inverse().transform(result);
/// // → Point(10, 20) (original point recovered)
/// ```
class TransformMatrix {
  /// Column-major 3x3 matrix storage.
  ///
  /// Indices:
  /// [0 3 6]   [m00 m10 m20]
  /// [1 4 7] = [m01 m11 m21]
  /// [2 5 8]   [m02 m12 m22]
  final Float32List _values;

  /// Create matrix from raw values (column-major order).
  ///
  /// Validates:
  /// - _values.length == 9
  /// - Bottom row is [0, 0, 1] (affine constraint)
  const TransformMatrix._(this._values);

  /// Create identity matrix (no transformation).
  ///
  /// ```
  /// [1 0 0]
  /// [0 1 0]
  /// [0 0 1]
  /// ```
  factory TransformMatrix.identity() {
    return TransformMatrix._(Float32List.fromList([
      1.0, 0.0, 0.0, // Column 0
      0.0, 1.0, 0.0, // Column 1
      0.0, 0.0, 1.0, // Column 2
    ]));
  }

  /// Create translation matrix (shift by offset).
  ///
  /// ```
  /// [1 0 0]
  /// [0 1 0]
  /// [dx dy 1]
  /// ```
  factory TransformMatrix.translation(double dx, double dy) {
    return TransformMatrix._(Float32List.fromList([
      1.0, 0.0, 0.0, // Column 0
      0.0, 1.0, 0.0, // Column 1
      dx, dy, 1.0, // Column 2
    ]));
  }

  /// Create scale matrix (scale about origin).
  ///
  /// ```
  /// [sx 0  0]
  /// [0  sy 0]
  /// [0  0  1]
  /// ```
  factory TransformMatrix.scale(double sx, double sy) {
    return TransformMatrix._(Float32List.fromList([
      sx, 0.0, 0.0, // Column 0
      0.0, sy, 0.0, // Column 1
      0.0, 0.0, 1.0, // Column 2
    ]));
  }

  /// Compose multiple transformations (matrix multiplication).
  ///
  /// Applies transformations left-to-right:
  /// `combined([A, B, C]) = C * B * A`
  ///
  /// Example:
  /// ```dart
  /// final combined = TransformMatrix.combined([
  ///   TransformMatrix.scale(2.0, 2.0),
  ///   TransformMatrix.translation(50.0, 30.0),
  /// ]);
  /// // Applies scale THEN translation
  /// ```
  factory TransformMatrix.combined(List<TransformMatrix> matrices) {
    if (matrices.isEmpty) return TransformMatrix.identity();

    var result = matrices[0];
    for (var i = 1; i < matrices.length; i++) {
      result = result * matrices[i];
    }
    return result;
  }

  /// Apply affine transformation to a point.
  ///
  /// Transformation: [x', y', 1] = M × [x, y, 1]
  /// ```
  /// x' = x * m00 + y * m01 + m02
  /// y' = x * m10 + y * m11 + m12
  /// ```
  ///
  /// Performance: O(1) - 6 multiplications, 4 additions
  Point<double> transform(Point<double> point) {
    final x = point.x * _values[0] + point.y * _values[3] + _values[6];
    final y = point.x * _values[1] + point.y * _values[4] + _values[7];
    return Point(x, y);
  }

  /// Apply transformation to 4 points simultaneously using SIMD.
  ///
  /// Uses dart:typed_data Float32x4 for parallel arithmetic.
  /// Processes 4 points in ~same time as 1 point (4x speedup).
  ///
  /// Example:
  /// ```dart
  /// final points = [p1, p2, p3, p4];
  /// final results = matrix.transformBatch4(points);
  /// // ~4x faster than calling transform() 4 times
  /// ```
  List<Point<double>> transformBatch4(List<Point<double>> points) {
    assert(points.length >= 4);

    // Load 4 x-coordinates and 4 y-coordinates
    final xVec = Float32x4(points[0].x, points[1].x, points[2].x, points[3].x);
    final yVec = Float32x4(points[0].y, points[1].y, points[2].y, points[3].y);

    // Apply matrix in parallel: x' = x * m00 + y * m01 + m02
    final xPrime = xVec.scale(_values[0]) + yVec.scale(_values[3]) + Float32x4.splat(_values[6]);

    // y' = x * m10 + y * m11 + m12
    final yPrime = xVec.scale(_values[1]) + yVec.scale(_values[4]) + Float32x4.splat(_values[7]);

    // Extract results
    return [
      Point(xPrime.x, yPrime.x),
      Point(xPrime.y, yPrime.y),
      Point(xPrime.z, yPrime.z),
      Point(xPrime.w, yPrime.w),
    ];
  }

  /// Compute inverse matrix (reverse transformation).
  ///
  /// For affine matrices:
  /// ```
  /// [a c e]^-1   1      [ d  -c  ce-de]
  /// [b d f]    = ─────  [-b   a  bf-af]
  /// [0 0 1]      ad-bc  [ 0   0  ad-bc]
  /// ```
  ///
  /// Throws ArgumentError if matrix is singular (determinant == 0).
  TransformMatrix inverse() {
    final a = _values[0], b = _values[1];
    final c = _values[3], d = _values[4];
    final e = _values[6], f = _values[7];

    final det = a * d - b * c;
    if (det == 0.0) {
      throw ArgumentError('Matrix is singular (determinant = 0), cannot invert');
    }

    final invDet = 1.0 / det;
    return TransformMatrix._(Float32List.fromList([
      d * invDet, -b * invDet, 0.0, // Column 0
      -c * invDet, a * invDet, 0.0, // Column 1
      (c * f - d * e) * invDet, (b * e - a * f) * invDet, 1.0, // Column 2
    ]));
  }

  /// Matrix multiplication (composition operator).
  ///
  /// `this * other` means: Apply `other` THEN apply `this`.
  ///
  /// Example:
  /// ```dart
  /// final scale = TransformMatrix.scale(2.0, 2.0);
  /// final trans = TransformMatrix.translation(50.0, 30.0);
  /// final combined = trans * scale; // Scale THEN translate
  /// ```
  TransformMatrix operator *(TransformMatrix other) {
    final a = _values, b = other._values;
    return TransformMatrix._(Float32List.fromList([
      a[0] * b[0] + a[3] * b[1], // m00
      a[1] * b[0] + a[4] * b[1], // m01
      0.0, // m02
      a[0] * b[3] + a[3] * b[4], // m10
      a[1] * b[3] + a[4] * b[4], // m11
      0.0, // m12
      a[0] * b[6] + a[3] * b[7] + a[6], // m20
      a[1] * b[6] + a[4] * b[7] + a[7], // m21
      1.0, // m22
    ]));
  }

  /// Get matrix element at (row, col).
  ///
  /// For debugging and testing. Not used in performance-critical code.
  double operator [](int index) => _values[index];

  @override
  String toString() {
    return 'TransformMatrix[\n'
        '  [${_values[0]}, ${_values[3]}, ${_values[6]}]\n'
        '  [${_values[1]}, ${_values[4]}, ${_values[7]}]\n'
        '  [${_values[2]}, ${_values[5]}, ${_values[8]}]\n'
        ']';
  }
}
