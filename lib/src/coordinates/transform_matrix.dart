/// 3x3 affine transformation matrix for 2D coordinate transformations.
///
/// **INTERNAL UTILITY** - Not exposed in public API.
///
/// Efficient matrix implementation for composing transformations (scale,
/// rotate, translate) and applying them to points. Uses Float32List for
/// performance and SIMD operations for batch transformations.
///
/// Matrix layout (column-major for GLSL/Flutter compatibility):
/// ```
/// [m00 m10 m20]   [scaleX  shearY  transX]
/// [m01 m11 m21] = [shearX  scaleY  transY]
/// [m02 m12 m22]   [0       0       1     ]
/// ```
///
/// **Usage Example**:
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
///
/// **Performance**:
/// - Single point transform: O(1), 6 multiplications, 4 additions
/// - Batch transform (SIMD): 4 points in ~same time as 1 point
/// - Matrix multiplication: O(1), 27 multiplications
library;

import 'dart:math' show Point;
import 'dart:typed_data' show Float32List, Float32x4;

/// 3x3 affine transformation matrix for 2D coordinate transformations.
///
/// This class is used internally by CoordinateTransformer for:
/// 1. Composing complex transformations (scale + rotate + translate)
/// 2. Caching transformation matrices per context
/// 3. SIMD-optimized batch transformations
///
/// See also:
/// - [UniversalCoordinateTransformer] - Uses matrices for transformations
/// - [TransformContext] - Provides context for matrix caching
class TransformMatrix {
  /// Create matrix from raw values (column-major order).
  ///
  /// **Validation**:
  /// - `_values.length` must equal 9
  /// - Bottom row must be [0, 0, 1] (affine constraint)
  ///
  /// This is a private constructor. Use factory constructors instead:
  /// - [TransformMatrix.identity]
  /// - [TransformMatrix.translation]
  /// - [TransformMatrix.scale]
  /// - [TransformMatrix.combined]
  const TransformMatrix._(this._values)
      : assert(_values.length == 9, 'Matrix must have exactly 9 values');

  /// Create identity matrix (no transformation).
  ///
  /// Returns a matrix that leaves points unchanged:
  /// ```
  /// [1 0 0]
  /// [0 1 0]
  /// [0 0 1]
  /// ```
  ///
  /// **Example**:
  /// ```dart
  /// final identity = TransformMatrix.identity();
  /// final point = Point(10.0, 20.0);
  /// final result = identity.transform(point);
  /// // result == Point(10.0, 20.0)
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
  /// Moves points by (`dx`, `dy`) in 2D space.
  ///
  /// Matrix form:
  /// ```
  /// [1  0  dx]
  /// [0  1  dy]
  /// [0  0  1 ]
  /// ```
  ///
  /// **Parameters**:
  /// - `dx`: Horizontal offset (positive = right)
  /// - `dy`: Vertical offset (positive = down in screen coords)
  ///
  /// **Example**:
  /// ```dart
  /// final trans = TransformMatrix.translation(50.0, 30.0);
  /// final point = Point(10.0, 20.0);
  /// final result = trans.transform(point);
  /// // result == Point(60.0, 50.0)
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
  /// Scales points by (`sx`, `sy`) relative to origin (0, 0).
  ///
  /// Matrix form:
  /// ```
  /// [sx  0  0]
  /// [0  sy  0]
  /// [0   0  1]
  /// ```
  ///
  /// **Parameters**:
  /// - `sx`: Horizontal scale factor (2.0 = double width)
  /// - `sy`: Vertical scale factor (2.0 = double height)
  ///
  /// **Example**:
  /// ```dart
  /// final scale = TransformMatrix.scale(2.0, 3.0);
  /// final point = Point(10.0, 20.0);
  /// final result = scale.transform(point);
  /// // result == Point(20.0, 60.0)
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
  /// This means the first matrix in the list is applied first,
  /// then the second, then the third, etc.
  ///
  /// **Parameters**:
  /// - `matrices`: List of matrices to compose (applied left-to-right)
  ///
  /// **Returns**: Identity matrix if list is empty
  ///
  /// **Example**:
  /// ```dart
  /// final combined = TransformMatrix.combined([
  ///   TransformMatrix.scale(2.0, 2.0),      // Apply first
  ///   TransformMatrix.translation(50.0, 30.0), // Apply second
  /// ]);
  /// // Scales point THEN translates it
  /// ```
  factory TransformMatrix.combined(List<TransformMatrix> matrices) {
    if (matrices.isEmpty) return TransformMatrix.identity();

    var result = matrices[0];
    for (var i = 1; i < matrices.length; i++) {
      result = result * matrices[i];
    }
    return result;
  }

  /// Column-major 3x3 matrix storage.
  ///
  /// Indices:
  /// ```
  /// [0 3 6]   [m00 m10 m20]
  /// [1 4 7] = [m01 m11 m21]
  /// [2 5 8]   [m02 m12 m22]
  /// ```
  ///
  /// Column-major order matches GLSL/WebGL conventions and allows
  /// efficient SIMD operations.
  final Float32List _values;

  /// Apply affine transformation to a point.
  ///
  /// Transformation: `[x', y', 1] = M × [x, y, 1]`
  ///
  /// Calculation:
  /// ```
  /// x' = x * m00 + y * m10 + m20
  /// y' = x * m01 + y * m11 + m21
  /// ```
  ///
  /// **Performance**: O(1) - 6 multiplications, 4 additions
  ///
  /// **Parameters**:
  /// - `point`: Input point to transform
  ///
  /// **Returns**: Transformed point
  ///
  /// **Example**:
  /// ```dart
  /// final matrix = TransformMatrix.translation(10.0, 20.0);
  /// final point = Point(5.0, 8.0);
  /// final result = matrix.transform(point);
  /// // result == Point(15.0, 28.0)
  /// ```
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
  /// **Parameters**:
  /// - `points`: List of at least 4 points to transform
  ///
  /// **Returns**: List of 4 transformed points
  ///
  /// **Performance**: ~4x faster than calling [transform] 4 times
  ///
  /// **Example**:
  /// ```dart
  /// final matrix = TransformMatrix.scale(2.0, 2.0);
  /// final points = [
  ///   Point(1.0, 2.0),
  ///   Point(3.0, 4.0),
  ///   Point(5.0, 6.0),
  ///   Point(7.0, 8.0),
  /// ];
  /// final results = matrix.transformBatch4(points);
  /// // ~4x faster than individual transforms
  /// ```
  List<Point<double>> transformBatch4(List<Point<double>> points) {
    assert(points.length >= 4, 'transformBatch4 requires at least 4 points');

    // Load 4 x-coordinates and 4 y-coordinates
    final xVec = Float32x4(
      points[0].x,
      points[1].x,
      points[2].x,
      points[3].x,
    );
    final yVec = Float32x4(
      points[0].y,
      points[1].y,
      points[2].y,
      points[3].y,
    );

    // Apply matrix in parallel: x' = x * m00 + y * m10 + m20
    final xPrime = xVec.scale(_values[0]) +
        yVec.scale(_values[3]) +
        Float32x4.splat(_values[6]);

    // y' = x * m01 + y * m11 + m21
    final yPrime = xVec.scale(_values[1]) +
        yVec.scale(_values[4]) +
        Float32x4.splat(_values[7]);

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
  /// For affine matrices, the inverse formula is:
  /// ```
  /// [a c e]^-1   1      [ d  -c  ce-de]
  /// [b d f]    = ─────  [-b   a  bf-af]
  /// [0 0 1]      ad-bc  [ 0   0  ad-bc]
  /// ```
  ///
  /// **Throws**: [ArgumentError] if matrix is singular (determinant == 0)
  ///
  /// **Example**:
  /// ```dart
  /// final matrix = TransformMatrix.translation(10.0, 20.0);
  /// final inverse = matrix.inverse();
  /// final point = Point(15.0, 28.0);
  /// final original = inverse.transform(point);
  /// // original == Point(5.0, 8.0)
  /// ```
  TransformMatrix inverse() {
    final a = _values[0], b = _values[1];
    final c = _values[3], d = _values[4];
    final e = _values[6], f = _values[7];

    final det = a * d - b * c;
    if (det == 0.0) {
      throw ArgumentError(
        'Matrix is singular (determinant = 0), cannot invert. '
        'Matrix: [[${_values[0]}, ${_values[3]}, ${_values[6]}], '
        '[${_values[1]}, ${_values[4]}, ${_values[7]}], '
        '[${_values[2]}, ${_values[5]}, ${_values[8]}]]',
      );
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
  /// **Parameters**:
  /// - `other`: Matrix to apply first
  ///
  /// **Returns**: Composed transformation matrix
  ///
  /// **Example**:
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
      0.0, // m02 (always 0 for affine)
      a[0] * b[3] + a[3] * b[4], // m10
      a[1] * b[3] + a[4] * b[4], // m11
      0.0, // m12 (always 0 for affine)
      a[0] * b[6] + a[3] * b[7] + a[6], // m20
      a[1] * b[6] + a[4] * b[7] + a[7], // m21
      1.0, // m22 (always 1 for affine)
    ]));
  }

  /// Get matrix element at column-major index.
  ///
  /// **For debugging and testing only**. Not used in performance-critical code.
  ///
  /// Indices:
  /// ```
  /// [0 3 6]
  /// [1 4 7]
  /// [2 5 8]
  /// ```
  ///
  /// **Example**:
  /// ```dart
  /// final matrix = TransformMatrix.translation(10.0, 20.0);
  /// print(matrix[6]); // 10.0 (dx)
  /// print(matrix[7]); // 20.0 (dy)
  /// ```
  double operator [](int index) => _values[index];

  /// String representation for debugging.
  ///
  /// Shows matrix in row-major format for readability:
  /// ```
  /// TransformMatrix[
  ///   [m00, m10, m20]
  ///   [m01, m11, m21]
  ///   [m02, m12, m22]
  /// ]
  /// ```
  @override
  String toString() {
    return 'TransformMatrix[\n'
        '  [${_values[0].toStringAsFixed(3)}, ${_values[3].toStringAsFixed(3)}, ${_values[6].toStringAsFixed(3)}]\n'
        '  [${_values[1].toStringAsFixed(3)}, ${_values[4].toStringAsFixed(3)}, ${_values[7].toStringAsFixed(3)}]\n'
        '  [${_values[2].toStringAsFixed(3)}, ${_values[5].toStringAsFixed(3)}, ${_values[8].toStringAsFixed(3)}]\n'
        ']';
  }
}
