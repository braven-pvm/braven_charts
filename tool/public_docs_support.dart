String normalizePublicDocsText(String value) {
  return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}
