import 'package:zto/zto.dart'
    show DtoToOpenApi, ZList, ZListOf, ZObj, Zto, ZtoSchema;

import '../internal/collection_utils.dart';
import '../schemas/open_api_schema.dart';
import '../schemas/security_scheme.dart';
import '../schemas/path_schema.dart';
import 'open_api_info.dart';
import 'scalar_options.dart';

export 'open_api_info.dart';
export '../schemas/security_scheme.dart';
export 'scalar_options.dart'
    show
        ScalarAgent,
        ScalarEnvironment,
        ScalarEnvironmentVariable,
        ScalarHttpClient,
        ScalarMetaData,
        ScalarMcp,
        ScalarOptions,
        ScalarPathRouting;

/// Builds a complete OpenAPI 3.0 spec as a [Map] by processing
/// the explicitly provided [pathSchemas].
class OpenApiBuilder {
  OpenApiBuilder({
    required this.info,
    Map<String, PathSchema>? pathSchemas,
    Map<String, SecurityScheme>? securitySchemes,
    this.globalSecurity,
    List<ScalarEnvironment>? scalarEnvironments,
    this.scalarActiveEnvironment,
  })  : pathSchemas = pathSchemas ?? const {},
        securitySchemes = securitySchemes ?? const {},
        scalarEnvironments = scalarEnvironments ?? const [];

  static const _defaultBearerScheme = SecurityScheme.bearer;

  final OpenApiInfo info;

  /// Zto-based request/response schemas keyed by OpenAPI path.
  final Map<String, PathSchema> pathSchemas;

  /// Additional security schemes shown in the Swagger UI "Authorize" dialog.
  final Map<String, SecurityScheme> securitySchemes;

  /// Security scheme names applied globally to **all** operations.
  final List<String>? globalSecurity;

  /// Named environments emitted as `x-scalar-environments` in the spec root.
  ///
  /// Variables defined here become available as `{{variableName}}` in Scalar's
  /// "Try it" panel — in URLs, headers, query params, and request bodies.
  final List<ScalarEnvironment> scalarEnvironments;

  /// Emitted as `x-scalar-active-environment`. Must match a [ScalarEnvironment.name].
  final String? scalarActiveEnvironment;

  /// Builds and returns the OpenAPI 3.0 spec as a plain Dart [Map].
  Map<String, dynamic> build() {
    final paths = <String, dynamic>{};
    var hasProtectedRoute = false;
    final seenOperationIds = <String>{};
    final referencedSchemes = <String>{};
    final usedTags = <String>{};

    for (final entry in pathSchemas.entries) {
      final pathName = entry.key;
      final pathSchema = entry.value;

      final pathItem = <String, dynamic>{};

      // Helper to process each HTTP method
      void processMethod(String methodName, OperationSchema? op) {
        if (op == null) return;

        final resolvedSecurity = _resolveOperationSecurity(op);
        if (resolvedSecurity != null && resolvedSecurity.isNotEmpty) {
          hasProtectedRoute = true;
          referencedSchemes.addAll(resolvedSecurity);
        }

        final operation = _buildOperation(
          pathName: pathName,
          methodName: methodName,
          operationSchema: op,
          operationSecurity: resolvedSecurity,
        );

        // operationId must be unique across the whole document.
        final operationId = operation['operationId'] as String;
        if (!seenOperationIds.add(operationId)) {
          throw StateError(
            'Duplicate operationId "$operationId" (at "$methodName '
            '$pathName"). Give one of the colliding operations a distinct '
            'summary or path.',
          );
        }

        usedTags.addAll((operation['tags'] as List).cast<String>());

        pathItem[methodName] = operation;
      }

      processMethod('get', pathSchema.get);
      processMethod('post', pathSchema.post);
      processMethod('put', pathSchema.put);
      processMethod('patch', pathSchema.patch);
      processMethod('delete', pathSchema.delete);

      if (pathSchema.pathParameters.isNotEmpty) {
        pathItem['parameters'] = pathSchema.pathParameters.values
            .map((p) => _buildPathParameter(p.name, p))
            .toList();
      } else if (pathName.contains('{')) {
        // Auto-extract parameters from path string if missing in pathParameters
        final paramPattern = RegExp(r'\{([^}]+)\}');
        final extracted =
            paramPattern.allMatches(pathName).map((m) => m.group(1)!);
        if (extracted.isNotEmpty) {
          pathItem['parameters'] =
              extracted.map((name) => _buildPathParameter(name, null)).toList();
        }
      }

      if (pathItem.isNotEmpty) {
        paths[pathName] = pathItem;
      }
    }

    final mergedSchemes = _buildSecuritySchemes(hasProtectedRoute);

    // Every referenced security scheme must be defined, otherwise the spec
    // contains a dangling security requirement.
    for (final name in {...referencedSchemes, ...?globalSecurity}) {
      if (!mergedSchemes.containsKey(name)) {
        throw StateError(
          'Security scheme "$name" is referenced by an operation but not '
          'defined. Add it to OpenApiBuilder.securitySchemes.',
        );
      }
    }

    final schemas = _collectSchemas();

    final components = <String, dynamic>{
      if (mergedSchemes.isNotEmpty) 'securitySchemes': mergedSchemes,
      if (schemas.isNotEmpty) 'schemas': _buildComponentSchemas(schemas),
    };

    return {
      'openapi': '3.0.0',
      'info': _buildInfo(),
      if (info.servers.isNotEmpty) 'servers': _buildServers(),
      if (globalSecurity != null && globalSecurity!.isNotEmpty)
        'security': globalSecurity!.map((name) => {name: <String>[]}).toList(),
      if (usedTags.isNotEmpty)
        'tags': (usedTags.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())))
            .map((name) => {'name': name})
            .toList(),
      'paths': paths,
      if (components.isNotEmpty) 'components': components,
      if (scalarEnvironments.isNotEmpty)
        'x-scalar-environments': {
          for (final env in scalarEnvironments) env.name: env.toJson(),
        },
      if (scalarActiveEnvironment != null)
        'x-scalar-active-environment': scalarActiveEnvironment,
    };
  }

  /// Merges auto-detected bearer scheme (when protected routes exist) with
  /// any explicitly provided [securitySchemes].
  Map<String, dynamic> _buildSecuritySchemes(bool hasProtectedRoute) {
    final merged = <String, dynamic>{};
    if (hasProtectedRoute && !securitySchemes.containsKey('BearerAuth')) {
      merged['BearerAuth'] = _defaultBearerScheme.toJson();
    }
    for (final entry in securitySchemes.entries) {
      merged[entry.key] = entry.value.toJson();
    }
    return merged;
  }

  Set<OpenApiSchema> _collectSchemas() {
    final schemas = <OpenApiSchema>{};
    final seenTypeNames = <String>{};
    final queue = <OpenApiSchema>[];

    void enqueue(OpenApiSchema s) {
      if (seenTypeNames.add(s.typeName)) {
        schemas.add(s);
        queue.add(s);
      }
    }

    for (final pathSchema in pathSchemas.values) {
      for (final op in [
        pathSchema.get,
        pathSchema.post,
        pathSchema.put,
        pathSchema.patch,
        pathSchema.delete
      ]) {
        if (op == null) continue;
        if (op.requestBodySchema != null && !op.requestBodySchema!.isInline) {
          enqueue(op.requestBodySchema!);
        }
        if (op.websocketMessageSchema != null &&
            !op.websocketMessageSchema!.isInline) {
          enqueue(op.websocketMessageSchema!);
        }
        for (final s in op.responseSchemas.values) {
          if (s == null) continue;
          // Inline schemas are emitted at the use site, not as components.
          if (!s.isInline) enqueue(s);
          // Array wrappers (e.g. `XList`) reference their item via `$ref`, so
          // the item schema itself must also be registered as a component.
          final item = s.ztoSchema;
          if (item != null && item.typeName != s.typeName) {
            enqueue(OpenApiSchema.fromZto(item));
          }
        }
      }
    }

    // Recursively collect schemas referenced via $ref inside nested fields.
    // seenTypeNames guards against circular references (A → B → A).
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final nested in _nestedSchemas(current.ztoSchema)) {
        enqueue(nested);
      }
    }

    return schemas;
  }

  /// Walks [ztoSchema]'s descriptors and yields [OpenApiSchema] for every
  /// nested DTO referenced by a [ZObj], [ZListOf], or [ZList] field.
  Iterable<OpenApiSchema> _nestedSchemas(ZtoSchema? ztoSchema) sync* {
    if (ztoSchema == null) return;
    for (final d in ztoSchema.descriptors) {
      final ann = d.fieldAnnotation;
      ZtoSchema? nested;
      if (ann is ZObj) {
        nested = (ann.dtoSchema ??
                (ann.dtoType != null ? Zto.getSchema(ann.dtoType!) : null))
            as ZtoSchema?;
      } else if (ann is ZListOf) {
        nested = (ann.dtoSchema ??
                (ann.dtoType != null ? Zto.getSchema(ann.dtoType!) : null))
            as ZtoSchema?;
      } else if (ann is ZList) {
        nested = Zto.getSchema(ann.itemType);
      }
      if (nested is ZtoSchema) {
        yield OpenApiSchema(
          typeName: nested.typeName,
          jsonSchema: DtoToOpenApi.convert(nested),
          ztoSchema: nested,
        );
      }
    }
  }

  Map<String, dynamic> _buildComponentSchemas(Set<OpenApiSchema> schemas) {
    return {
      for (final schema in schemas) schema.typeName: schema.jsonSchema,
    };
  }

  Map<String, dynamic> _buildInfo() => {
        'title': info.title,
        if (info.description != null) 'description': info.description,
        'version': info.version,
      };

  List<Map<String, dynamic>> _buildServers() =>
      info.servers.map((url) => {'url': url}).toList();

  Map<String, dynamic> _buildOperation({
    required String pathName,
    required String methodName,
    required OperationSchema operationSchema,
    required List<String>? operationSecurity,
  }) {
    final autoTag = tagFromPath(pathName);
    final responses = _buildResponses(
      operationSchema: operationSchema,
      operationSecurity: operationSecurity,
    );

    // OpenAPI 3.0 requires every operation to declare at least one response.
    if (responses.isEmpty) {
      throw StateError(
        'Operation "$methodName $pathName" has no responses. Declare at least '
        'one, e.g. .ok(...) or .response(200, ...).',
      );
    }

    final hasRequestBody = operationSchema.requestBodySchema != null;

    // Build query and header parameters
    final params = <Map<String, dynamic>>[];
    for (final p in operationSchema.queryParameters) {
      params.add(_buildParameter(p, 'query'));
    }
    for (final p in operationSchema.headerParameters) {
      params.add(_buildParameter(p, 'header'));
    }

    return {
      'operationId': _operationId(pathName, methodName),
      'summary':
          operationSchema.summary ?? _summaryFromPath(pathName, methodName),
      if (operationSchema.description != null)
        'description': operationSchema.description!,
      'tags': operationSchema.tags ?? [autoTag],
      if (operationSchema.deprecated == true) 'deprecated': true,
      if (operationSecurity != null)
        'security':
            operationSecurity.map((name) => {name: <String>[]}).toList(),
      if (params.isNotEmpty) 'parameters': params,
      if (hasRequestBody) 'requestBody': _buildRequestBody(operationSchema),
      'responses': responses,
      ...operationSchema.extensions,
      if (operationSchema.postmanPreRequestScript != null &&
          !operationSchema.extensions.containsKey('x-pre-request'))
        'x-pre-request': operationSchema.postmanPreRequestScript,
      if (operationSchema.postmanTestScript != null &&
          !operationSchema.extensions.containsKey('x-post-response'))
        'x-post-response': operationSchema.postmanTestScript,
    };
  }

  /// Returns the per-operation security list.
  /// If it returns a non-empty list, we consider the route as protected
  /// for the sake of adding BearerAuth to the global schemes list.
  List<String>? _resolveOperationSecurity(OperationSchema operationSchema) {
    if (operationSchema.security != null) return operationSchema.security;
    return globalSecurity;
  }

  Map<String, dynamic> _buildRequestBody(OperationSchema schema) {
    final body = schema.requestBodySchema!;
    return {
      'required': schema.requestBodyRequired,
      'content': {
        schema.requestContentType: {
          'schema': body.isInline
              ? body.jsonSchema
              : {r'$ref': '#/components/schemas/${body.typeName}'},
        },
      },
    };
  }

  Map<String, dynamic> _buildParameter(ParameterSchema p, String location) {
    final schemaMap = <String, dynamic>{'type': p.type};
    if (p.format != null) schemaMap['format'] = p.format!;
    if (p.enumValues != null) schemaMap['enum'] = p.enumValues!;
    if (p.example != null) schemaMap['example'] = p.example!;

    return {
      'name': p.name,
      'in': location,
      if (p.description != null) 'description': p.description!,
      'required': p.required,
      'schema': schemaMap,
    };
  }

  Map<String, dynamic> _buildResponses({
    required OperationSchema operationSchema,
    required List<String>? operationSecurity,
  }) {
    final isProtected =
        operationSecurity != null && operationSecurity.isNotEmpty;
    final responses = <String, dynamic>{
      if (isProtected) '401': {'description': 'Unauthorized'},
    };

    for (final entry in operationSchema.responseSchemas.entries) {
      final code = entry.key;
      final codeStr = code.toString();
      final responseSchema = entry.value;

      // Determine description: custom override → default
      final description = operationSchema.responseDescriptions[code] ??
          _statusDescription(code);

      // Determine response headers for this status code
      final headers = operationSchema.responseHeaders[code];
      Map<String, dynamic>? headersMap;
      if (headers != null && headers.isNotEmpty) {
        headersMap = {
          for (final h in headers) h.name: _buildResponseHeader(h),
        };
      }

      // A declared content type forces a `content` block even when the schema
      // is null (e.g. a schemaless SSE/stream response).
      final contentType = operationSchema.responseContentTypes[code];
      final hasContent = responseSchema != null || contentType != null;

      if (hasContent) {
        final mediaType = <String, dynamic>{
          if (responseSchema != null)
            'schema': responseSchema.isInline
                ? responseSchema.jsonSchema
                : {r'$ref': '#/components/schemas/${responseSchema.typeName}'},
        };
        responses[codeStr] = {
          'description': description,
          'content': {
            (contentType ?? 'application/json'): mediaType,
          },
          if (headersMap != null) 'headers': headersMap,
        };
      } else {
        responses[codeStr] = {
          'description': description,
          if (headersMap != null) 'headers': headersMap,
        };
      }
    }

    return responses;
  }

  Map<String, dynamic> _buildResponseHeader(ResponseHeaderSchema h) {
    final schemaMap = <String, dynamic>{'type': h.type};
    if (h.format != null) schemaMap['format'] = h.format!;
    if (h.example != null) schemaMap['example'] = h.example!;
    return {
      'description': h.description,
      'schema': schemaMap,
    };
  }

  String _statusDescription(int code) {
    return switch (code) {
      101 => 'Switching Protocols',
      200 => 'Success',
      201 => 'Created',
      202 => 'Accepted',
      204 => 'No Content',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      422 => 'Unprocessable Entity',
      429 => 'Rate Limit Exceeded',
      500 => 'Internal Server Error',
      503 => 'Service Unavailable',
      _ => 'Response',
    };
  }

  /// Generates a unique camelCase operationId.
  /// `POST /v1/payments/stripe/create-account` → `postV1PaymentsStripeCreateAccount`
  /// `GET /`                                  → `getRoot`
  /// `GET /v1/users/{id}`                     → `getV1UsersById`
  String _operationId(String path, String method) {
    if (path == '/') return '${method}Root';

    final segments = path.split('/').where((s) => s.isNotEmpty).map((s) {
      if (s.startsWith('{') && s.endsWith('}')) {
        final param = s.substring(1, s.length - 1);
        return 'By${param[0].toUpperCase()}${param.substring(1)}';
      }
      return s
          .split('-')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join();
    }).join();

    return '$method$segments';
  }

  Map<String, dynamic> _buildPathParameter(
      String name, ParameterSchema? override) {
    if (override != null) {
      final schemaMap = <String, dynamic>{'type': override.type};
      if (override.format != null) schemaMap['format'] = override.format!;
      return {
        'name': name,
        'in': 'path',
        'required': true,
        if (override.description != null) 'description': override.description!,
        'schema': schemaMap,
      };
    }
    return {
      'name': name,
      'in': 'path',
      'required': true,
      'schema': {'type': 'string'},
    };
  }

  /// Generates a human-readable summary from the last meaningful path segment.
  String _summaryFromPath(String path, String method) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final versionPattern = RegExp(r'^v\d+$');

    final lastMeaningful = segments.lastWhere(
      (s) => !versionPattern.hasMatch(s) && !s.startsWith('{'),
      orElse: () => '',
    );

    if (lastMeaningful.isEmpty) return method.toUpperCase();

    return lastMeaningful
        .split('-')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
