import 'dart:convert';

import '../internal/collection_utils.dart';
import '../open_api_builder/open_api_info.dart';
import '../schemas/open_api_schema.dart';
import '../schemas/security_scheme.dart';
import '../schemas/path_schema.dart';

/// Builds a Bruno collection as a map of relative file path → file content.
///
/// The collection follows Bruno's filesystem-based `.bru` format, organized by
/// tag (folder), and includes an environment file and `bruno.json` metadata.
///
/// The result can be zipped and served as a download.
class BrunoCollectionBuilder {
  BrunoCollectionBuilder({
    required this.info,
    this.pathSchemas = const {},
    this.securitySchemes = const {},
    this.baseUrl = 'http://localhost:8080',
  });

  final OpenApiInfo info;
  final Map<String, PathSchema> pathSchemas;
  final Map<String, SecurityScheme> securitySchemes;
  final String baseUrl;

  /// Builds and returns all Bruno collection files as a map of
  /// relative path → file content (UTF-8 strings).
  ///
  /// Keys use forward-slash separators regardless of platform.
  /// Example keys:
  /// - `'bruno.json'`
  /// - `'environments/local.bru'`
  /// - `'users/list_users.bru'`
  Map<String, String> build() {
    final files = <String, String>{};

    files['bruno.json'] = _buildBrunoJson();
    files['environments/local.bru'] = _buildEnvironmentFile();

    final sequenceByTag = <String, int>{};

    for (final entry in pathSchemas.entries) {
      final pathName = entry.key;
      final pathSchema = entry.value;

      void processMethod(String methodName, OperationSchema? schema) {
        if (schema == null) return;
        final tag = _tagFromPath(pathName, schema);
        final seq = (sequenceByTag[tag] ?? 0) + 1;
        sequenceByTag[tag] = seq;

        final name = schema.summary ?? '${methodName.toUpperCase()} $pathName';
        final filename = toFilename(name);

        final content = _buildBruFile(pathName, methodName, schema, seq);

        files['$tag/$filename.bru'] = content;
      }

      processMethod('get', pathSchema.get);
      processMethod('post', pathSchema.post);
      processMethod('put', pathSchema.put);
      processMethod('patch', pathSchema.patch);
      processMethod('delete', pathSchema.delete);
    }

    return files;
  }

  // ---------------------------------------------------------------------------
  // bruno.json
  // ---------------------------------------------------------------------------

  String _buildBrunoJson() {
    final lines = [
      '{',
      '  "version": "1",',
      '  "name": "${_escape(info.title)}",',
      '  "type": "collection"',
      '}',
    ];
    return lines.join('\n');
  }

  // ---------------------------------------------------------------------------
  // environments/local.bru
  // ---------------------------------------------------------------------------

  String _buildEnvironmentFile() {
    final buf = StringBuffer();
    buf.writeln('vars {');
    buf.writeln('  baseUrl: $baseUrl');

    for (final entry in securitySchemes.entries) {
      final varName = varNameForScheme(entry.key);
      final placeholder = _defaultEnvValue(varName);
      buf.writeln('  $varName: $placeholder');
    }

    buf.write('}');
    return buf.toString();
  }

  String _defaultEnvValue(String varName) {
    return switch (varName) {
      'bearerToken' => '<your-bearer-token>',
      'apiKey' => '<your-api-key>',
      'basicAuth' => '<username:password>',
      _ => '',
    };
  }

  // ---------------------------------------------------------------------------
  // .bru file
  // ---------------------------------------------------------------------------

  String _buildBruFile(
    String pathName,
    String methodName,
    OperationSchema schema,
    int seq,
  ) {
    final buf = StringBuffer();
    final name = schema.summary ?? '${methodName.toUpperCase()} $pathName';
    final url = _buildUrl(pathName);

    final effectiveSecurity = schema.security ?? [];

    final bearerScheme = _findScheme(effectiveSecurity, 'bearer');
    final apiKeySchemes = _findApiKeySchemes(effectiveSecurity);

    final hasBody =
        methodName == 'post' || methodName == 'put' || methodName == 'patch';

    // meta block
    buf.writeln('meta {');
    buf.writeln('  name: $name');
    buf.writeln('  type: http');
    buf.writeln('  seq: $seq');
    buf.writeln('}');
    buf.writeln();

    // method block
    final authType = bearerScheme != null ? 'bearer' : 'none';
    buf.writeln('$methodName {');
    buf.writeln('  url: $url');
    if (hasBody) buf.writeln('  body: json');
    buf.writeln('  auth: $authType');
    buf.writeln('}');
    buf.writeln();

    // auth:bearer block (must be right after request in some Bruno versions)
    if (bearerScheme != null) {
      final varName = varNameForScheme(bearerScheme);
      buf.writeln('auth:bearer {');
      buf.writeln('  token: {{$varName}}');
      buf.writeln('}');
      buf.writeln();
    }

    // headers block
    final headers = <String, String>{};
    if (hasBody) headers['Content-Type'] = 'application/json';
    for (final schemeName in apiKeySchemes) {
      final scheme = securitySchemes[schemeName];
      if (scheme == null) continue;
      final varName = varNameForScheme(schemeName);
      final header = scheme.postmanHeader(varName);
      if (header != null) {
        headers[header['key']!] = '{{${varName}}}';
      }
    }

    if (headers.isNotEmpty) {
      buf.writeln('headers {');
      for (final entry in headers.entries) {
        buf.writeln('  ${entry.key}: ${entry.value}');
      }
      buf.writeln('}');
      buf.writeln();
    }

    // body:json block
    if (hasBody) {
      final bodyJson = _buildExampleBody(schema);
      buf.writeln('body:json {');
      for (final line in bodyJson.split('\n')) {
        buf.writeln('  $line');
      }
      buf.writeln('}');
      buf.writeln();
    }

    // docs block (Bruno Docs tab - markdown)
    final docsContent = _buildDocsContent(schema);
    if (docsContent.isNotEmpty) {
      buf.writeln('docs {');
      for (final line in docsContent.split('\n')) {
        buf.writeln('  $line');
      }
      buf.writeln('}');
      buf.writeln();
    }

    if (schema.brunoPreRequestScript != null) {
      buf.writeln('script:pre-request {');
      _writeIndentedScript(buf, schema.brunoPreRequestScript!);
      buf.writeln('}');
      buf.writeln();
    }

    if (schema.brunoTestScript != null) {
      buf.writeln('script:post-response {');
      _writeIndentedScript(buf, schema.brunoTestScript!);
      buf.writeln('}');
      buf.writeln();
    }

    return buf.toString().trimRight();
  }

  // ---------------------------------------------------------------------------
  // URL builder
  // ---------------------------------------------------------------------------

  String _buildUrl(String pathName) {
    final brunoPath = pathName.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (m) => ':${m.group(1)}',
    );
    return '{{baseUrl}}$brunoPath';
  }

  // ---------------------------------------------------------------------------
  // Scheme helpers
  // ---------------------------------------------------------------------------

  String? _findScheme(List<String> effectiveSecurity, String type) {
    for (final name in effectiveSecurity) {
      final scheme = securitySchemes[name];
      if (scheme == null) continue;
      final json = scheme.toJson();
      if (json['scheme'] == type ||
          json['type'] == 'http' && json['scheme'] == type) {
        return name;
      }
    }
    return null;
  }

  List<String> _findApiKeySchemes(List<String> effectiveSecurity) {
    final result = <String>[];
    for (final name in effectiveSecurity) {
      final scheme = securitySchemes[name];
      if (scheme == null) continue;
      final json = scheme.toJson();
      if (json['type'] == 'apiKey' && json['in'] == 'header') {
        result.add(name);
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Writes script content with 2-space indent per line (Bruno block format).
  void _writeIndentedScript(StringBuffer buf, String script) {
    final lines = _stripCommonIndent(script).split('\n');
    const blockIndent = '  ';
    for (final line in lines) {
      buf.writeln(line.trim().isEmpty ? '' : '$blockIndent$line');
    }
  }

  /// Strips minimum common leading whitespace from script lines.
  String _stripCommonIndent(String script) {
    final lines = script.split('\n');
    if (lines.isEmpty) return '';

    int? minIndent;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final leading = line.length - line.trimLeft().length;
      if (minIndent == null || leading < minIndent) minIndent = leading;
    }

    if (minIndent == null || minIndent == 0) return script.trim();

    final result = lines
        .map((line) =>
            line.length > minIndent! ? line.substring(minIndent) : line)
        .join('\n');
    return result.trim();
  }

  String _tagFromPath(String path, OperationSchema? schema) {
    if (schema?.tags != null && schema!.tags!.isNotEmpty) {
      return schema.tags!.first;
    }
    return tagFromPath(path);
  }

  String _escape(String s) => s.replaceAll('"', '\\"');

  // ---------------------------------------------------------------------------
  // Docs block content (description + schema tables)
  // ---------------------------------------------------------------------------

  String _buildDocsContent(OperationSchema? schema) {
    if (schema == null) return '';

    final parts = <String>[];

    if (schema.description != null && schema.description!.trim().isNotEmpty) {
      parts.add(schema.description!.trim());
    }

    if (schema.requestBodySchema != null) {
      final table = _schemaToMarkdownTable(schema.requestBodySchema!);
      if (table.isNotEmpty) {
        if (parts.isNotEmpty) parts.add('');
        parts.add('### Request body schema');
        parts.add('');
        parts.add(table);
      }
    }

    if (schema.responseSchemas.isNotEmpty) {
      for (final entry in schema.responseSchemas.entries) {
        final dtoSchema = entry.value;
        if (dtoSchema == null) continue;
        final table = _schemaToMarkdownTable(dtoSchema);
        if (table.isNotEmpty) {
          if (parts.isNotEmpty) parts.add('');
          parts.add('### Response ${entry.key} schema');
          parts.add('');
          parts.add(table);
        }
      }
    }

    return parts.join('\n');
  }

  String _schemaToMarkdownTable(OpenApiSchema schema) {
    final rawProps = schema.jsonSchema['properties'];
    final props =
        rawProps is Map<String, dynamic> ? rawProps : null;
    if (props == null || props.isEmpty) return '';

    final rawReq = schema.jsonSchema['required'];
    final required =
        rawReq is List ? rawReq.whereType<String>().toList() : <String>[];

    final rows = <String>[
      '| Field | Type | Description | Required |',
      '|-------|------|-------------|----------|',
    ];

    for (final entry in props.entries) {
      final prop = entry.value is Map<String, dynamic>
          ? entry.value as Map<String, dynamic>
          : const <String, dynamic>{};
      final type = _openApiTypeToReadable(prop);
      final desc = (prop['description'] as String?) ?? '-';
      final isReq = required.contains(entry.key);
      rows.add('| `${entry.key}` | $type | $desc | ${isReq ? 'Yes' : 'No'} |');
    }

    return rows.join('\n');
  }

  String _openApiTypeToReadable(Map<String, dynamic> prop) {
    final oneOf = prop['oneOf'] as List<dynamic>?;
    if (oneOf != null) {
      final nonNull = oneOf.cast<Map<String, dynamic>>().firstWhere(
            (s) => s['type'] != 'null',
            orElse: () => oneOf.first as Map<String, dynamic>,
          );
      return '${_openApiTypeToReadable(nonNull)}?';
    }

    final type = prop['type'] as String?;
    final format = prop['format'] as String?;
    final enumValues = prop['enum'] as List<dynamic>?;
    final items = prop['items'] as Map<String, dynamic>?;

    if (enumValues != null) return 'enum: ${enumValues.join(", ")}';
    if (type == 'array' && items != null) {
      final itemType = _openApiTypeToReadable(items);
      return 'array of $itemType';
    }

    return switch (type) {
      'string' => format == 'date-time' ? 'string (ISO 8601)' : 'string',
      'integer' => 'integer',
      'number' => 'number',
      'boolean' => 'boolean',
      'object' => 'object',
      _ => type ?? 'any',
    };
  }

  // ---------------------------------------------------------------------------
  // Example body from DTO
  // ---------------------------------------------------------------------------

  String _buildExampleBody(OperationSchema? schema) {
    if (schema?.requestBodySchema == null) return '{}';
    final example = _exampleFromSchema(schema!.requestBodySchema!.jsonSchema);
    return const JsonEncoder.withIndent('  ').convert(example);
  }

  dynamic _exampleFromSchema(Map<String, dynamic> schema) {
    final rawProps = schema['properties'];
    final props = rawProps is Map<String, dynamic> ? rawProps : null;
    if (props == null || props.isEmpty) return <String, dynamic>{};

    final result = <String, dynamic>{};
    for (final entry in props.entries) {
      final propSchema = entry.value is Map<String, dynamic>
          ? entry.value as Map<String, dynamic>
          : const <String, dynamic>{};
      result[entry.key] = _exampleValueForProperty(propSchema);
    }
    return result;
  }

  dynamic _exampleValueForProperty(Map<String, dynamic> prop) {
    if (prop.containsKey('example')) return prop['example'];

    final oneOf = prop['oneOf'] as List<dynamic>?;
    if (oneOf != null) {
      final nonNull = oneOf.cast<Map<String, dynamic>>().firstWhere(
            (s) => s['type'] != 'null',
            orElse: () => oneOf.first as Map<String, dynamic>,
          );
      return _exampleValueForProperty(nonNull);
    }

    return _defaultForType(prop);
  }

  dynamic _defaultForType(Map<String, dynamic> prop) {
    if (prop.containsKey('example')) return prop['example'];
    final type = prop['type'] as String?;
    final enumValues = prop['enum'] as List<dynamic>?;
    if (enumValues != null && enumValues.isNotEmpty) return enumValues.first;
    return switch (type) {
      'string' => '',
      'integer' || 'number' => 0,
      'boolean' => false,
      'array' => [],
      'object' => <String, dynamic>{},
      _ => '',
    };
  }
}
