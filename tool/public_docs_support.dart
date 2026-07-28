import 'dart:io';

typedef PublicDocsPackageMetadata = ({
  String version,
  String dartConstraint,
  String flutterConstraint,
});

String normalizePublicDocsText(String value) {
  return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

PublicDocsPackageMetadata readPublicDocsPackageMetadata(File pubspec) {
  final source = pubspec.readAsStringSync();
  final version = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(source)?.group(1);
  final dartConstraint = RegExp(
    r'^\s+sdk:\s*"([^"]+)"\s*$',
    multiLine: true,
  ).firstMatch(source)?.group(1);
  final flutterConstraint = RegExp(
    r'^\s+flutter:\s*"([^"]+)"\s*$',
    multiLine: true,
  ).firstMatch(source)?.group(1);
  if (version == null || dartConstraint == null || flutterConstraint == null) {
    throw FormatException(
      'Could not read version and SDK constraints from ${pubspec.path}.',
    );
  }
  return (
    version: version,
    dartConstraint: dartConstraint,
    flutterConstraint: flutterConstraint,
  );
}
