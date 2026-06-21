import 'package:zto/zto.dart';

import '../schemas/open_api_schema.dart';
import '../schemas/path_schema.dart';
import 'param_type.dart';

/// Entry point for the Fluent API to build OpenAPI documentation schemas.
abstract class Api {
  const Api._();

  /// Creates a new path builder to document a route.
  static ApiPathBuilder path() => ApiPathBuilder();
}

/// Builder for defining a [PathSchema].
class ApiPathBuilder {
  final Map<String, ParameterSchema> _pathParameters = {};
  OperationSchema? _get;
  OperationSchema? _post;
  OperationSchema? _put;
  OperationSchema? _patch;
  OperationSchema? _delete;

  /// Defines a path parameter (e.g., `{id}`).
  ApiPathBuilder param(String name, ParamType type, {String? description, Object? example}) {
    _pathParameters[name] = ParameterSchema(
      name: name,
      type: type.openApiName,
      description: description,
      example: example,
    );
    return this;
  }

  /// Configures the GET operation for this path.
  ApiPathBuilder get(void Function(OperationBuilder op) configure) {
    _get = _buildOperation(configure);
    return this;
  }

  /// Configures the POST operation for this path.
  ApiPathBuilder post(void Function(OperationBuilder op) configure) {
    _post = _buildOperation(configure);
    return this;
  }

  /// Configures the PUT operation for this path.
  ApiPathBuilder put(void Function(OperationBuilder op) configure) {
    _put = _buildOperation(configure);
    return this;
  }

  /// Configures the PATCH operation for this path.
  ApiPathBuilder patch(void Function(OperationBuilder op) configure) {
    _patch = _buildOperation(configure);
    return this;
  }

  /// Configures the DELETE operation for this path.
  ApiPathBuilder delete(void Function(OperationBuilder op) configure) {
    _delete = _buildOperation(configure);
    return this;
  }

  OperationSchema _buildOperation(void Function(OperationBuilder op) configure) {
    final builder = OperationBuilder();
    configure(builder);
    return builder.build();
  }

  /// Finalizes the configuration and returns a [PathSchema].
  PathSchema build() {
    return PathSchema(
      pathParameters: _pathParameters,
      get: _get,
      post: _post,
      put: _put,
      patch: _patch,
      delete: _delete,
    );
  }
}

/// Builder for defining an [OperationSchema].
class OperationBuilder {
  String? _summary;
  String? _description;
  List<String>? _tags;
  bool _deprecated = false;
  List<String>? _security;
  OpenApiSchema? _requestBodySchema;
  bool _requestBodyRequired = true;
  String _requestContentType = 'application/json';
  final Map<int, OpenApiSchema?> _responseSchemas = {};
  final Map<int, String> _responseContentTypes = {};
  final Map<int, List<ResponseHeaderSchema>> _responseHeaders = {};
  final Map<int, String> _responseDescriptions = {};
  OpenApiSchema? _websocketMessageSchema;
  final List<ParameterSchema> _queryParameters = [];
  final List<ParameterSchema> _headerParameters = [];
  String? _postmanTestScript;
  String? _postmanPreRequestScript;
  String? _brunoTestScript;
  String? _brunoPreRequestScript;
  final Map<String, dynamic> _extensions = {};

  /// Adds a custom OpenAPI extension (e.g. `x-pre-request`).
  ///
  /// If [key] does not start with `x-`, it will be automatically prefixed.
  OperationBuilder extension(String key, dynamic value) {
    final normalizedKey = key.startsWith('x-') ? key : 'x-$key';
    _extensions[normalizedKey] = value;
    return this;
  }

  /// Sets the operation summary.
  OperationBuilder summary(String value) {
    _summary = value;
    return this;
  }

  /// Sets the operation description (markdown supported).
  OperationBuilder description(String value) {
    _description = value;
    return this;
  }

  /// Adds a single tag to this operation. Useful for grouping endpoints.
  OperationBuilder tag(String value) {
    _tags ??= [];
    if (!_tags!.contains(value)) _tags!.add(value);
    return this;
  }

  /// Sets multiple tags for this operation.
  OperationBuilder tags(List<String> values) {
    _tags = List.from(values);
    return this;
  }

  /// Marks the operation as deprecated.
  OperationBuilder deprecated() {
    _deprecated = true;
    return this;
  }

  /// Sets the operation as explicitly public (no security requirements).
  OperationBuilder public() {
    _security = [];
    return this;
  }

  /// Defines explicit security requirements for this operation.
  OperationBuilder security(List<String> schemes) {
    _security = List.from(schemes);
    return this;
  }

  /// Adds a query parameter to this operation.
  OperationBuilder query(String name, ParamType type, {String? description, Object? example, List<String>? values}) {
    _queryParameters.add(ParameterSchema(
      name: name,
      type: type.openApiName,
      description: description,
      example: example,
      enumValues: values,
    ));
    return this;
  }

  /// Adds a string query parameter with optional [required] flag.
  ///
  /// Shorthand for [query] when the type is always `string` and `required`
  /// matters (e.g. `.queryParam('user_id', required: true)`).
  OperationBuilder queryParam(String name, {String? description, bool required = false, Object? example}) {
    _queryParameters.add(ParameterSchema(
      name: name,
      type: ParamType.string.openApiName,
      description: description,
      required: required,
      example: example,
    ));
    return this;
  }

  /// Adds a header parameter to this operation.
  OperationBuilder header(String name, ParamType type, {String? description, String? format, Object? example}) {
    _headerParameters.add(ParameterSchema(
      name: name,
      type: type.openApiName,
      description: description,
      format: format,
      example: example,
    ));
    return this;
  }

  /// Configures the request body using a Zto schema.
  OperationBuilder body(ZtoSchema schema, {bool required = true, String contentType = 'application/json'}) {
    _requestBodySchema = OpenApiSchema.fromZto(schema);
    _requestBodyRequired = required;
    _requestContentType = contentType;
    return this;
  }

  /// Configures a raw binary request body (upload), e.g. an image or file.
  ///
  /// Emits `content: {<contentType>: {schema: {type: string, format: binary}}}`.
  OperationBuilder bytesBody({
    String contentType = 'application/octet-stream',
    bool required = true,
  }) {
    _requestBodySchema = OpenApiSchema.inline({'type': 'string', 'format': 'binary'});
    _requestContentType = contentType;
    _requestBodyRequired = required;
    return this;
  }

  /// Configures a streaming request body (e.g. newline-delimited JSON upload).
  ///
  /// When [ztoSchema] is given it types each streamed record; otherwise the
  /// body is left schemaless. Defaults to `application/x-ndjson`.
  OperationBuilder streamBody({
    ZtoSchema? ztoSchema,
    String contentType = 'application/x-ndjson',
    bool required = true,
  }) {
    _requestBodySchema = ztoSchema != null
        ? OpenApiSchema.fromZto(ztoSchema)
        : OpenApiSchema.inline(<String, dynamic>{});
    _requestContentType = contentType;
    _requestBodyRequired = required;
    return this;
  }

  /// Documents a WebSocket upgrade endpoint.
  ///
  /// OpenAPI 3.0 cannot model WebSocket traffic, so this declares the HTTP
  /// `101 Switching Protocols` handshake and surfaces the message contract as
  /// an `x-websocket` extension (the [messageZtoSchema] is registered in
  /// `components/schemas`).
  OperationBuilder websocket({ZtoSchema? messageZtoSchema, String? description}) {
    _responseSchemas[101] = null;
    if (description != null) _responseDescriptions[101] = description;
    if (messageZtoSchema != null) {
      _websocketMessageSchema = OpenApiSchema.fromZto(messageZtoSchema);
      _extensions['x-websocket'] = {
        'message': {
          r'$ref': '#/components/schemas/${messageZtoSchema.typeName}',
        },
      };
    }
    return this;
  }

  /// Documents the response for [status] from flat parameters.
  ///
  /// Pick exactly one body mode (first non-null wins):
  /// - [ztoSchema] — a `zto` DTO referenced via `$ref`.
  /// - [listOfZtoSchema] — an array of a `zto` DTO.
  /// - [json] — a literal sample payload; the schema is inferred and the value
  ///   is attached as `example`.
  /// - [listOfJson] — a literal sample item; produces an array with example
  ///   `[item]`.
  /// - none — a bodyless response (e.g. `204`).
  ///
  /// An optional [contentType] overrides the default `application/json` media
  /// type — useful for typed error envelopes (e.g. `application/problem+json`).
  ///
  /// ```dart
  /// .response(201,
  ///     ztoSchema: $UserResponseDtoSchema,
  ///     headers: [ResHeader('Location', ParamType.string)])
  /// ```
  ///
  /// See also the semantic shortcuts [ok], [created], [noContent],
  /// [badRequest], [notFound], and the media helpers [bytes], [sse], [stream].
  OperationBuilder response(
    int status, {
    ZtoSchema? ztoSchema,
    ZtoSchema? listOfZtoSchema,
    Object? json,
    Object? listOfJson,
    String? contentType,
    String? description,
    List<ResHeader> headers = const [],
  }) {
    assert(
      [ztoSchema, listOfZtoSchema, json, listOfJson]
              .where((m) => m != null)
              .length <=
          1,
      'response($status): set at most one body mode '
      '(ztoSchema / listOfZtoSchema / json / listOfJson).',
    );
    OpenApiSchema? schema;
    if (ztoSchema != null) {
      schema = OpenApiSchema.fromZto(ztoSchema);
    } else if (listOfZtoSchema != null) {
      schema = OpenApiSchema.arrayOf(listOfZtoSchema);
    } else if (json != null) {
      schema = OpenApiSchema.inline({..._inferSchema(json), 'example': json});
    } else if (listOfJson != null) {
      schema = OpenApiSchema.inline({
        'type': 'array',
        'items': _inferSchema(listOfJson),
        'example': [listOfJson],
      });
    }
    _writeResponse(
      status,
      schema: schema,
      contentType: contentType,
      description: description,
      headers: headers,
    );
    return this;
  }

  /// Documents a raw binary response (file/blob download) for [status].
  ///
  /// Emits `content: {<contentType>: {schema: {type: string, format: binary}}}`.
  OperationBuilder bytes(
    int status, {
    String contentType = 'application/octet-stream',
    String? description,
    List<ResHeader> headers = const [],
  }) {
    _writeResponse(
      status,
      schema: OpenApiSchema.inline({'type': 'string', 'format': 'binary'}),
      contentType: contentType,
      description: description,
      headers: headers,
    );
    return this;
  }

  /// Documents a Server-Sent Events response (`text/event-stream`) for [status].
  ///
  /// [ztoSchema]/[json] type the payload of each event; omit both for a
  /// schemaless stream.
  OperationBuilder sse(
    int status, {
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      stream(status, 'text/event-stream',
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a streamed response under an arbitrary [contentType] for
  /// [status]. [ztoSchema]/[json] type each streamed chunk.
  OperationBuilder stream(
    int status,
    String contentType, {
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) {
    assert(ztoSchema == null || json == null,
        'stream($status): use ztoSchema OR json, not both.');
    OpenApiSchema? schema;
    if (ztoSchema != null) {
      schema = OpenApiSchema.fromZto(ztoSchema);
    } else if (json != null) {
      schema = OpenApiSchema.inline({..._inferSchema(json), 'example': json});
    }
    _writeResponse(
      status,
      schema: schema,
      contentType: contentType,
      description: description,
      headers: headers,
    );
    return this;
  }

  void _writeResponse(
    int status, {
    OpenApiSchema? schema,
    String? contentType,
    String? description,
    List<ResHeader> headers = const [],
  }) {
    assert(!_responseSchemas.containsKey(status),
        'status $status already declared for this operation.');
    _responseSchemas[status] = schema;
    if (contentType != null) _responseContentTypes[status] = contentType;
    if (description != null) _responseDescriptions[status] = description;
    if (headers.isNotEmpty) {
      _responseHeaders.putIfAbsent(status, () => []).addAll([
        for (final h in headers)
          ResponseHeaderSchema(
            name: h.name,
            description: h.description ?? '',
            type: h.type.openApiName,
            format: h.format,
            example: h.example,
          ),
      ]);
    }
  }

  /// Documents a `200 OK` response. See [response] for the general form.
  OperationBuilder ok({
    ZtoSchema? ztoSchema,
    ZtoSchema? listOfZtoSchema,
    Object? json,
    Object? listOfJson,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(200,
          ztoSchema: ztoSchema,
          listOfZtoSchema: listOfZtoSchema,
          json: json,
          listOfJson: listOfJson,
          description: description,
          headers: headers);

  /// Documents a `201 Created` response.
  OperationBuilder created({
    ZtoSchema? ztoSchema,
    ZtoSchema? listOfZtoSchema,
    Object? json,
    Object? listOfJson,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(201,
          ztoSchema: ztoSchema,
          listOfZtoSchema: listOfZtoSchema,
          json: json,
          listOfJson: listOfJson,
          description: description,
          headers: headers);

  /// Documents a `202 Accepted` response (async processing).
  OperationBuilder accepted({
    ZtoSchema? ztoSchema,
    ZtoSchema? listOfZtoSchema,
    Object? json,
    Object? listOfJson,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(202,
          ztoSchema: ztoSchema,
          listOfZtoSchema: listOfZtoSchema,
          json: json,
          listOfJson: listOfJson,
          description: description,
          headers: headers);

  /// Documents a `204 No Content` (bodyless) response.
  OperationBuilder noContent({
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(204, description: description, headers: headers);

  /// Documents a `400 Bad Request` response.
  OperationBuilder badRequest({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(400,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a `401 Unauthorized` response.
  OperationBuilder unauthorized({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(401,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a `403 Forbidden` response.
  OperationBuilder forbidden({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(403,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a `404 Not Found` response.
  OperationBuilder notFound({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(404,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a `409 Conflict` response.
  OperationBuilder conflict({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(409,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a `422 Unprocessable Entity` response (typical ZTO validation).
  OperationBuilder unprocessable({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(422,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a `429 Too Many Requests` response (rate limiting).
  OperationBuilder tooManyRequests({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(429,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a `500 Internal Server Error` response.
  OperationBuilder serverError({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(500,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Documents a `503 Service Unavailable` response.
  OperationBuilder serviceUnavailable({
    ZtoSchema? ztoSchema,
    Object? json,
    String? description,
    List<ResHeader> headers = const [],
  }) =>
      response(503,
          ztoSchema: ztoSchema,
          json: json,
          description: description,
          headers: headers);

  /// Sets the Postman test script (JavaScript) for this operation.
  OperationBuilder postman(String script) {
    _postmanTestScript = script;
    return this;
  }

  /// Sets the Postman pre-request script (JavaScript) for this operation.
  OperationBuilder postmanPre(String script) {
    _postmanPreRequestScript = script;
    return this;
  }

  /// Sets the Bruno test script (JavaScript) for this operation.
  OperationBuilder bruno(String script) {
    _brunoTestScript = script;
    return this;
  }

  /// Sets the Bruno pre-request script (JavaScript) for this operation.
  OperationBuilder brunoPre(String script) {
    _brunoPreRequestScript = script;
    return this;
  }

  /// Builds the OperationSchema object.
  OperationSchema build() {
    return OperationSchema(
      summary: _summary,
      description: _description,
      tags: _tags,
      deprecated: _deprecated,
      security: _security,
      requestBodySchema: _requestBodySchema,
      requestBodyRequired: _requestBodyRequired,
      requestContentType: _requestContentType,
      responseSchemas: _responseSchemas,
      responseContentTypes: _responseContentTypes,
      responseHeaders: _responseHeaders,
      responseDescriptions: _responseDescriptions,
      queryParameters: _queryParameters,
      headerParameters: _headerParameters,
      postmanTestScript: _postmanTestScript,
      postmanPreRequestScript: _postmanPreRequestScript,
      brunoTestScript: _brunoTestScript,
      brunoPreRequestScript: _brunoPreRequestScript,
      websocketMessageSchema: _websocketMessageSchema,
      extensions: Map.from(_extensions),
    );
  }
}

/// A response header declaration used by [OperationBuilder.response] and the
/// semantic shortcuts ([OperationBuilder.ok], [OperationBuilder.created], ...).
///
/// Carries the full OpenAPI header metadata: type, description, format and an
/// example value.
class ResHeader {
  const ResHeader(
    this.name,
    this.type, {
    this.description,
    this.format,
    this.example,
  });

  /// Header name (e.g. `'Location'`, `'X-Total-Count'`).
  final String name;

  /// OpenAPI primitive type of the header value.
  final ParamType type;

  /// Human-readable description shown in Swagger UI.
  final String? description;

  /// OpenAPI format, e.g. `'uuid'`, `'date-time'`.
  final String? format;

  /// Example value for Swagger UI.
  final Object? example;
}

/// Infers an OpenAPI 3.0 JSON Schema from a literal sample [value].
///
/// Used by [OperationBuilder.response] (the `json`/`listOfJson` params) so
/// callers can document a response by pasting the real payload instead of
/// hand-writing a schema.
Map<String, dynamic> _inferSchema(Object? value) {
  if (value is Map) {
    return {
      'type': 'object',
      if (value.isNotEmpty)
        'properties': {
          for (final entry in value.entries)
            entry.key.toString(): _inferSchema(entry.value),
        },
    };
  }
  if (value is List) {
    return {
      'type': 'array',
      'items': value.isEmpty ? <String, dynamic>{} : _inferSchema(value.first),
    };
  }
  if (value is bool) return {'type': 'boolean'};
  if (value is int) return {'type': 'integer'};
  if (value is num) return {'type': 'number'};
  if (value is String) return {'type': 'string'};
  return <String, dynamic>{};
}

