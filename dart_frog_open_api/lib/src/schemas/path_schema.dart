import 'open_api_schema.dart';

/// Describes a single query, header, or path parameter.
class ParameterSchema {
  const ParameterSchema({
    required this.name,
    required this.type,
    this.description,
    this.required = false,
    this.example,
    this.enumValues,
    this.format,
  });

  /// Parameter name (e.g. `'search'`, `'X-Tenant-Id'`).
  final String name;

  /// OpenAPI primitive type: `'string'`, `'integer'`, `'boolean'`, `'number'`.
  final String type;

  /// Human-readable description shown in Swagger UI.
  final String? description;

  /// Whether this parameter is required. Defaults to `false`.
  final bool required;

  /// Example value for Swagger UI.
  final Object? example;

  /// Restricts values to this list (generates `enum` in the schema).
  final List<String>? enumValues;

  /// OpenAPI format, e.g. `'date-time'`, `'uuid'`.
  final String? format;
}

/// Describes a single response header for a given status code.
class ResponseHeaderSchema {
  const ResponseHeaderSchema({
    required this.name,
    required this.description,
    this.type = 'string',
    this.format,
    this.example,
  });

  /// Header name (e.g. `'Location'`, `'X-Total-Count'`).
  final String name;

  /// Human-readable description shown in Swagger UI.
  final String description;

  /// OpenAPI primitive type. Defaults to `'string'`.
  final String type;

  /// OpenAPI format, e.g. `'date-time'`.
  final String? format;

  /// Example value for Swagger UI.
  final Object? example;
}

/// Describes the request/response schemas for a single HTTP operation.
class OperationSchema {
  const OperationSchema({
    this.summary,
    this.description,
    this.tags,
    this.deprecated = false,
    this.security,
    this.requestBodySchema,
    this.requestBodyRequired = true,
    this.requestContentType = 'application/json',
    this.responseSchemas = const {},
    this.responseHeaders = const {},
    this.responseDescriptions = const {},
    this.queryParameters = const [],
    this.headerParameters = const [],
    this.postmanTestScript,
    this.postmanPreRequestScript,
    this.brunoTestScript,
    this.brunoPreRequestScript,
    this.extensions = const {},
  });

  /// Overrides the auto-generated summary for this operation.
  ///
  /// When `null`, the summary is derived from the last path segment.
  final String? summary;

  /// Longer human-readable description shown in the Swagger UI panel.
  final String? description;

  /// Overrides the auto-generated tag(s) for this operation.
  ///
  /// When `null`, the tag is derived from the first meaningful path segment.
  final List<String>? tags;

  /// Marks this operation as deprecated in the Swagger UI.
  final bool deprecated;

  /// Explicit security scheme names required for this operation.
  ///
  /// Overrides both the global security and the auto-detected middleware-based
  /// security for this specific operation.
  ///
  /// - `null` → inherit: protected routes get `['BearerAuth']`, others inherit
  ///   the global security defined in [OpenApiBuilder].
  /// - `[]`   → explicitly **public**: no security, even if global is set.
  /// - `['SchemeName']` → requires that specific scheme.
  ///
  /// The scheme names must match keys in [OpenApiBuilder.securitySchemes].
  final List<String>? security;

  /// Optional [OpenApiSchema] for the JSON request body.
  ///
  /// Use [OpenApiSchema.fromZto] to convert a [ZtoSchema] from the `zto` package.
  final OpenApiSchema? requestBodySchema;

  /// Whether the request body is required. Defaults to `true`.
  final bool requestBodyRequired;

  /// MIME type for the request body content. Defaults to `'application/json'`.
  final String requestContentType;

  /// Map of HTTP status code → [OpenApiSchema] for the response body.
  ///
  /// A `null` value means the response has no body (e.g. 204 No Content).
  final Map<int, OpenApiSchema?> responseSchemas;

  /// Optional response headers per HTTP status code.
  ///
  /// Example:
  /// ```dart
  /// responseHeaders: {
  ///   201: [ResponseHeaderSchema(name: 'Location', description: 'URL of created resource')],
  /// }
  /// ```
  final Map<int, List<ResponseHeaderSchema>> responseHeaders;

  /// Custom descriptions for response status codes.
  ///
  /// Overrides the default description derived from the status code number.
  ///
  /// Example:
  /// ```dart
  /// responseDescriptions: {200: 'Returns the list of items'}
  /// ```
  final Map<int, String> responseDescriptions;

  /// Query parameters for this operation.
  ///
  /// Each [ParameterSchema] becomes a `in: query` parameter in the OpenAPI spec.
  final List<ParameterSchema> queryParameters;

  /// Header parameters for this operation.
  ///
  /// Each [ParameterSchema] becomes a `in: header` parameter in the OpenAPI spec.
  final List<ParameterSchema> headerParameters;

  /// JavaScript test script injected into the Postman Collection item.
  ///
  /// Runs after the response is received. Use the Postman `pm` API:
  /// ```javascript
  /// const body = pm.response.json();
  /// pm.environment.set("bearerToken", body.accessToken);
  /// pm.test("Status is 200", () => pm.response.to.have.status(200));
  /// ```
  final String? postmanTestScript;

  /// JavaScript pre-request script injected into the Postman Collection item.
  ///
  /// Runs before the request is sent. Use the Postman `pm` API:
  /// ```javascript
  /// pm.request.headers.add({ key: "X-Timestamp", value: Date.now().toString() });
  /// ```
  final String? postmanPreRequestScript;

  /// JavaScript test script injected into the Bruno `.bru` file.
  ///
  /// Runs after the response is received. Use the Bruno scripting API:
  /// ```javascript
  /// test("Status is 200", function() {
  ///   expect(res.getStatus()).to.equal(200);
  /// });
  /// const body = res.getBody();
  /// bru.setEnvVar("bearerToken", body.accessToken);
  /// ```
  final String? brunoTestScript;

  /// JavaScript pre-request script injected into the Bruno `.bru` file.
  ///
  /// Runs before the request is sent. Use the Bruno scripting API:
  /// ```javascript
  /// bru.setEnvVar("ts", Date.now().toString());
  /// ```
  final String? brunoPreRequestScript;

  /// Custom OpenAPI extensions (keys starting with `x-`).
  final Map<String, dynamic> extensions;
}

/// Describes [OperationSchema] per HTTP method for a single API path.
class PathSchema {
  const PathSchema({
    this.get,
    this.post,
    this.put,
    this.patch,
    this.delete,
    this.pathParameters = const {},
  });

  final OperationSchema? get;
  final OperationSchema? post;
  final OperationSchema? put;
  final OperationSchema? patch;
  final OperationSchema? delete;

  /// Optional type overrides for path parameters (keyed by parameter name).
  ///
  /// When provided, the path parameter schema uses the given [ParameterSchema]
  /// instead of the default `{type: 'string'}`.
  ///
  /// Example:
  /// ```dart
  /// pathParameters: {
  ///   'id': ParameterSchema(name: 'id', type: 'integer', description: 'User ID'),
  /// }
  /// ```
  final Map<String, ParameterSchema> pathParameters;

  /// Returns the [OperationSchema] for [method] (lowercase OpenAPI name).
  OperationSchema? forMethod(String method) {
    return switch (method) {
      'get' => get,
      'post' => post,
      'put' => put,
      'patch' => patch,
      'delete' => delete,
      _ => null,
    };
  }
}
