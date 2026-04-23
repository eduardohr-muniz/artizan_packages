import 'dart:convert';

import '../internal/collection_utils.dart';
import '../open_api_builder/open_api_info.dart';
import '../schemas/security_scheme.dart';
import '../schemas/path_schema.dart';

/// Builds a Postman Collection v2.1 JSON from the Dart Frog routes directory.
///
/// The generated collection groups requests by tag (folder), resolves
/// environment variables for auth headers, and injects test / pre-request
/// scripts defined in each [OperationSchema].
class PostmanCollectionBuilder {
  PostmanCollectionBuilder({
    required this.info,
    this.pathSchemas = const {},
    this.securitySchemes = const {},
    this.baseUrl = 'http://localhost:8080',
  });

  final OpenApiInfo info;
  final Map<String, PathSchema> pathSchemas;
  final Map<String, SecurityScheme> securitySchemes;
  final String baseUrl;

  /// Builds and returns the Postman Collection 2.1 spec as a plain Dart [Map].
  Map<String, dynamic> build() {
    final folders = <String, List<Map<String, dynamic>>>{};

    for (final entry in pathSchemas.entries) {
      final pathName = entry.key;
      final pathSchema = entry.value;

      void processMethod(String methodName, OperationSchema? schema) {
        if (schema == null) return;
        final tag = _folderTag(pathName, schema);
        final item = _buildItem(pathName, methodName, schema);
        folders.putIfAbsent(tag, () => []).add(item);
      }

      processMethod('get', pathSchema.get);
      processMethod('post', pathSchema.post);
      processMethod('put', pathSchema.put);
      processMethod('patch', pathSchema.patch);
      processMethod('delete', pathSchema.delete);
    }

    final variables = _buildVariables();

    return {
      'info': {
        'name': info.title,
        'description': info.description ?? '',
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      },
      'item': [
        for (final entry in folders.entries)
          {'name': entry.key, 'item': entry.value},
      ],
      if (variables.isNotEmpty) 'variable': variables,
    };
  }

  // ---------------------------------------------------------------------------
  // Item builder
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildItem(
    String pathName,
    String methodName,
    OperationSchema schema,
  ) {
    final events = _buildEvents(schema);
    final headers = _buildHeaders(pathName, methodName, schema);
    final urlObj = _buildUrl(pathName, schema);
    final name = schema.summary ?? '${methodName.toUpperCase()} $pathName';

    final request = <String, dynamic>{
      'method': methodName.toUpperCase(),
      'header': headers,
      'url': urlObj,
    };

    final hasBody =
        methodName == 'post' || methodName == 'put' || methodName == 'patch';

    if (hasBody) {
      request['body'] = _buildBody(schema);
    }

    return {
      'name': name,
      if (events.isNotEmpty) 'event': events,
      'request': request,
    };
  }

  // ---------------------------------------------------------------------------
  // Events (scripts)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _buildEvents(OperationSchema? schema) {
    final events = <Map<String, dynamic>>[];

    if (schema?.postmanPreRequestScript != null) {
      events.add(_script('prerequest', schema!.postmanPreRequestScript!));
    }

    if (schema?.postmanTestScript != null) {
      events.add(_script('test', schema!.postmanTestScript!));
    }

    return events;
  }

  Map<String, dynamic> _script(String listen, String code) => {
        'listen': listen,
        'script': {
          'type': 'text/javascript',
          'exec': code.split('\n'),
        },
      };

  // ---------------------------------------------------------------------------
  // Headers
  // ---------------------------------------------------------------------------

  List<Map<String, String>> _buildHeaders(
    String pathName,
    String methodName,
    OperationSchema schema,
  ) {
    final headers = <Map<String, String>>[];

    final effectiveSecurity = schema.security ?? [];

    for (final schemeName in effectiveSecurity) {
      final scheme = securitySchemes[schemeName];
      if (scheme == null) continue;
      final varName = varNameForScheme(schemeName);
      final header = scheme.postmanHeader(varName);
      if (header != null) headers.add(header);
    }

    final hasBody =
        methodName == 'post' || methodName == 'put' || methodName == 'patch';

    if (hasBody) {
      headers.add({'key': 'Content-Type', 'value': 'application/json'});
    }

    return headers;
  }

  // ---------------------------------------------------------------------------
  // URL
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildUrl(String pathName, OperationSchema schema) {
    final postmanPath = pathName.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (m) => ':${m.group(1)}',
    );
    final rawUrl = '{{baseUrl}}$postmanPath';

    final pathSegments =
        postmanPath.split('/').where((s) => s.isNotEmpty).toList();

    final urlMap = <String, dynamic>{
      'raw': rawUrl,
      'host': ['{{baseUrl}}'],
      'path': pathSegments,
    };

    final paramPattern = RegExp(r'\{([^}]+)\}');
    final extracted =
        paramPattern.allMatches(pathName).map((m) => m.group(1)!).toList();

    if (extracted.isNotEmpty) {
      urlMap['variable'] = extracted
          .map((p) => {'key': p, 'value': '', 'description': 'Path parameter'})
          .toList();
    }

    return urlMap;
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildBody(OperationSchema? schema) {
    String raw = '{}';

    final requestSchema = schema?.requestBodySchema;
    if (requestSchema != null) {
      final properties =
          requestSchema.jsonSchema['properties'] as Map<String, dynamic>?;
      if (properties != null && properties.isNotEmpty) {
        final body = <String, dynamic>{};
        for (final entry in properties.entries) {
          final propSchema = entry.value is Map<String, dynamic>
              ? entry.value as Map<String, dynamic>
              : const <String, dynamic>{};
          body[entry.key] = _exampleValueFromSchema(propSchema);
        }
        raw = const JsonEncoder.withIndent('  ').convert(body);
      }
    }

    return {
      'mode': 'raw',
      'raw': raw,
      'options': {
        'raw': {'language': 'json'},
      },
    };
  }

  /// Returns a sensible example value for a property schema.
  ///
  /// Prefers the `example` field if present; otherwise derives a default from
  /// the OpenAPI `type`.
  dynamic _exampleValueFromSchema(Map<String, dynamic> schema) {
    // oneOf (nullable) — use the first non-null option
    final oneOf = schema['oneOf'];
    if (oneOf is List && oneOf.isNotEmpty) {
      return _exampleValueFromSchema(oneOf.first as Map<String, dynamic>);
    }

    if (schema.containsKey('example')) return schema['example'];

    return switch (schema['type']) {
      'string' => '',
      'integer' => 0,
      'number' => 0.0,
      'boolean' => false,
      'array' => <dynamic>[],
      'object' => <String, dynamic>{},
      _ => null,
    };
  }

  // ---------------------------------------------------------------------------
  // Variables
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _buildVariables() {
    final variables = <Map<String, dynamic>>[
      {
        'key': 'baseUrl',
        'value': baseUrl,
        'type': 'string',
        'description': 'Base URL of the API',
      },
    ];

    for (final entry in securitySchemes.entries) {
      final varName = varNameForScheme(entry.key);
      final hasHeader = entry.value.postmanHeader(varName) != null;
      if (!hasHeader) continue;
      variables.add({
        'key': varName,
        'value': '',
        'type': 'string',
        'description': 'Credential for ${entry.key}',
      });
    }

    return variables;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _folderTag(String pathName, OperationSchema? schema) {
    if (schema?.tags != null && schema!.tags!.isNotEmpty) {
      return schema.tags!.first;
    }
    return tagFromPath(pathName);
  }
}
