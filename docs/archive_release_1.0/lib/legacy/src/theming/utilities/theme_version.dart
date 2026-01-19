/// Theme versioning utilities for compatibility checking.
///
/// Provides semantic versioning support for theme serialization,
/// following the theme JSON schema v1.0 specification.
library;

/// Current theme version supported by this implementation.
///
/// This is the version number that will be written when serializing themes.
/// The version follows semantic versioning: major.minor.patch
const currentVersion = ThemeVersion(1, 0, 0);

/// Represents a semantic version number for theme compatibility.
///
/// Theme versions follow semantic versioning:
/// - Major: Breaking changes (incompatible themes)
/// - Minor: Backward-compatible additions (new optional fields)
/// - Patch: Bug fixes (no schema changes)
///
/// Examples:
/// ```dart
/// const v1 = ThemeVersion(1, 0, 0);
/// const v1_1 = ThemeVersion(1, 1, 0);
/// const v2 = ThemeVersion(2, 0, 0);
///
/// v1.isCompatible(v1_1); // true (same major version)
/// v1.isCompatible(v2);   // false (different major version)
/// ```
class ThemeVersion {
  /// Creates a theme version with the given components.
  const ThemeVersion(this.major, this.minor, this.patch);

  /// Parses a version string in "major.minor.patch" format.
  ///
  /// Returns the parsed version or null if the format is invalid.
  ///
  /// Valid formats:
  /// - "1.0.0" (three components)
  /// - "1.2.3" (any non-negative integers)
  ///
  /// Invalid formats:
  /// - "1.0" (missing patch)
  /// - "1" (missing minor and patch)
  /// - "1.0.0.0" (too many components)
  /// - "1.0.a" (non-numeric)
  /// - "-1.0.0" (negative)
  /// - "1.-0.0" (negative)
  ///
  /// Examples:
  /// ```dart
  /// ThemeVersion.fromString('1.0.0'); // ThemeVersion(1, 0, 0)
  /// ThemeVersion.fromString('1.2.3'); // ThemeVersion(1, 2, 3)
  /// ThemeVersion.fromString('1.0');   // null (invalid)
  /// ThemeVersion.fromString('abc');   // null (invalid)
  /// ```
  static ThemeVersion? fromString(String? versionString) {
    if (versionString == null) return null;

    final parts = versionString.split('.');
    if (parts.length != 3) return null;

    final major = int.tryParse(parts[0]);
    final minor = int.tryParse(parts[1]);
    final patch = int.tryParse(parts[2]);

    if (major == null || minor == null || patch == null) return null;
    if (major < 0 || minor < 0 || patch < 0) return null;

    return ThemeVersion(major, minor, patch);
  }

  /// Major version number (breaking changes).
  final int major;

  /// Minor version number (backward-compatible additions).
  final int minor;

  /// Patch version number (bug fixes).
  final int patch;

  /// Checks if this version is compatible with another version.
  ///
  /// Two versions are compatible if they have the same major version.
  /// This follows semantic versioning rules:
  /// - Major version changes indicate breaking changes (incompatible)
  /// - Minor/patch changes are backward-compatible
  ///
  /// Examples:
  /// ```dart
  /// const v1_0_0 = ThemeVersion(1, 0, 0);
  /// const v1_1_0 = ThemeVersion(1, 1, 0);
  /// const v1_2_3 = ThemeVersion(1, 2, 3);
  /// const v2_0_0 = ThemeVersion(2, 0, 0);
  ///
  /// v1_0_0.isCompatible(v1_1_0); // true (same major)
  /// v1_0_0.isCompatible(v1_2_3); // true (same major)
  /// v1_0_0.isCompatible(v2_0_0); // false (different major)
  /// v1_1_0.isCompatible(v1_0_0); // true (same major)
  /// v2_0_0.isCompatible(v1_0_0); // false (different major)
  /// ```
  bool isCompatible(ThemeVersion other) {
    return major == other.major;
  }

  /// Converts the version to a string in "major.minor.patch" format.
  ///
  /// Examples:
  /// ```dart
  /// ThemeVersion(1, 0, 0).toString(); // "1.0.0"
  /// ThemeVersion(1, 2, 3).toString(); // "1.2.3"
  /// ThemeVersion(10, 20, 30).toString(); // "10.20.30"
  /// ```
  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeVersion &&
        other.major == major &&
        other.minor == minor &&
        other.patch == patch;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch);
}
