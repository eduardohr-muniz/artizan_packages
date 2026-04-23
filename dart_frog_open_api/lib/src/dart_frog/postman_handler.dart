import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../open_api_builder/open_api_info.dart';
import '../postman/postman_collection_builder.dart';
import '../schemas/security_scheme.dart';
import '../schemas/path_schema.dart';

export '../postman/postman_collection_builder.dart';

/// Returns a Dart Frog [Handler] that serves a Postman Collection v2.1 JSON
/// generated from the given [routesDir].
///
/// Mount it in a route file (e.g. `routes/postman.dart`):
/// ```dart
/// import 'package:dart_frog_swagger/dart_frog_swagger.dart';
///
/// FutureOr<Response> onRequest(RequestContext context) =>
///   postmanCollectionHandler(
///     info: OpenApiInfo(title: 'My API', version: '1.0.0'),
///     routesDir: RoutesDirResolver.fromCwd(),
///     baseUrl: 'http://localhost:8080',
///     securitySchemes: {
///       'BearerAuth': SecurityScheme.bearer,
///       'ApiKey': SecurityScheme.apiKeyHeader('X-API-Key'),
///     },
///     pathSchemas: {
///       '/auth/login': PathSchema(
///         post: OperationSchema(
///           summary: 'Login',
///           postmanTestScript: '''
/// const body = pm.response.json();
/// pm.environment.set("bearerToken", body.accessToken);
/// pm.test("Status is 200", () => pm.response.to.have.status(200));
/// ''',
///         ),
///       ),
///     },
///   )(context);
/// ```
///
/// The generated collection can be imported directly into Postman via
/// **Import → Raw text** or by pointing to the URL once the server is running.
Handler postmanCollectionHandler({
  required OpenApiInfo info,
  Map<String, PathSchema>? pathSchemas,
  Map<String, SecurityScheme>? securitySchemes,
  String baseUrl = 'http://localhost:8080',
}) {
  return (RequestContext context) {
    if (context.request.method != HttpMethod.get) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final collection = PostmanCollectionBuilder(
      info: info,
      pathSchemas: pathSchemas ?? const {},
      securitySchemes: securitySchemes ?? const {},
      baseUrl: baseUrl,
    ).build();

    final json = const JsonEncoder.withIndent('  ').convert(collection);

    return Response(
      body: json,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        'Content-Disposition':
            'attachment; filename="${_toFilename(info.title)}.postman_collection.json"',
        'Access-Control-Allow-Origin': '*',
      },
    );
  };
}

String _toFilename(String title) =>
    title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
