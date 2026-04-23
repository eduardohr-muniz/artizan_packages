/// Converts an operation name to a safe filesystem identifier.
/// `'Say Hello'` → `'say_hello'`
String toFilename(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'_+$'), '');

/// Derives a tag from the first meaningful path segment, skipping version prefixes.
/// `/v1/users/{id}` → `'users'`
String tagFromPath(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  final versionPattern = RegExp(r'^v\d+$');
  return segments.firstWhere(
    (s) => !versionPattern.hasMatch(s) && !s.startsWith('{'),
    orElse: () => segments.isNotEmpty ? segments.first : 'Root',
  );
}

/// Derives a collection variable name from a security scheme name.
/// `'BearerAuth'` → `'bearerToken'`, `'BasicAuth'` → `'basicAuth'`
String varNameForScheme(String schemeName) {
  if (schemeName.toLowerCase().contains('bearer')) return 'bearerToken';
  if (schemeName.toLowerCase().contains('basic')) return 'basicAuth';
  final cleaned = schemeName
      .replaceAll(RegExp(r'[Aa]uth$'), '')
      .replaceAll(RegExp(r'[Ss]cheme$'), '')
      .trim();
  if (cleaned.isEmpty) return 'credential';
  return '${cleaned[0].toLowerCase()}${cleaned.substring(1)}';
}
