/// Configuration used to populate the OpenAPI `info` and `servers` objects.
class OpenApiInfo {
  const OpenApiInfo({
    required this.title,
    this.description,
    this.version = '1.0.0',
    this.servers = const [],
  });

  final String title;
  final String? description;
  final String version;

  /// List of server URLs, e.g. `['http://localhost:8080']`.
  final List<String> servers;
}
