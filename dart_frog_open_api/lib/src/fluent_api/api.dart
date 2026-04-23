import 'package:zto/zto.dart';

import '../schemas/open_api_schema.dart';
import '../schemas/path_schema.dart';
import 'param_type.dart';

typedef BuildResponseExamples = Object? Function(
  ResponseExampleContext response,
);

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
  final Map<int, List<ResponseHeaderSchema>> _responseHeaders = {};
  final Map<int, String> _responseDescriptions = {};
  final Map<int, Map<String, Map<String, dynamic>>> _responseExamples = {};
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

  /// Configures a response for a specific HTTP status code.
  OperationBuilder returns(int status, {ZtoSchema? schema, String? description, BuildResponseExamples? buildResponse}) {
    if (schema != null) {
      _responseSchemas[status] = OpenApiSchema.fromZto(schema);
    } else {
      _responseSchemas[status] = null;
    }
    if (description != null) {
      _responseDescriptions[status] = description;
    }
    if (buildResponse != null) {
      final context = ResponseExampleContext(
        status: status,
        description: description,
        schemaTypeName: schema?.typeName,
      );
      final produced = buildResponse(context);
      final values = <Object?>[
        ...context.items,
      ];
      if (produced is List) {
        values.addAll(produced);
      } else if (produced != null) {
        values.add(produced);
      }
      _responseExamples[status] = _normalizeExamples(values);
    }
    return this;
  }

  Map<String, Map<String, dynamic>> _normalizeExamples(List<Object?> values) {
    final out = <String, Map<String, dynamic>>{};
    var i = 1;
    for (final item in values) {
      if (item == null) continue;
      if (item is OpenApiResponseExample) {
        out[item.name] = item.toOpenApiMap();
        continue;
      }
      if (item is Map<String, dynamic>) {
        out['example_$i'] = {'value': item};
        i++;
        continue;
      }
      final map = _tryToMap(item);
      if (map != null) {
        out['example_$i'] = {'value': map};
        i++;
      }
    }
    return out;
  }

  Map<String, dynamic>? _tryToMap(Object item) {
    try {
      final dynamic dyn = item;
      final result = dyn.toMap();
      if (result is Map<String, dynamic>) return result;
      if (result is Map) {
        return result.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Adds a response header for a specific HTTP status code.
  OperationBuilder responseHeader(int status, String name, ParamType type, {String? description, Object? example}) {
    _responseHeaders.putIfAbsent(status, () => []);
    _responseHeaders[status]!.add(ResponseHeaderSchema(
      name: name,
      description: description ?? '',
      type: type.openApiName,
      example: example,
    ));
    return this;
  }

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
      responseHeaders: _responseHeaders,
      responseDescriptions: _responseDescriptions,
      responseExamples: _responseExamples,
      queryParameters: _queryParameters,
      headerParameters: _headerParameters,
      postmanTestScript: _postmanTestScript,
      postmanPreRequestScript: _postmanPreRequestScript,
      brunoTestScript: _brunoTestScript,
      brunoPreRequestScript: _brunoPreRequestScript,
      extensions: Map.from(_extensions),
    );
  }
}
