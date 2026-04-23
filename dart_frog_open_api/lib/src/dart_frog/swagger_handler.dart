import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../open_api_builder/open_api_builder.dart';
import '../schemas/path_schema.dart';
import '../security/security_config.dart';
import '../security/security_guard.dart';

export '../open_api_builder/open_api_builder.dart';

/// Returns a Dart Frog [Handler] that serves the OpenAPI 3.0 JSON spec.
///
/// [security] controls CORS headers. No `*` wildcard is ever emitted.
/// [onSpecBuilt] is called with the freshly built spec — use it to populate
/// an external cache.
Handler swaggerJsonHandler({
  required OpenApiInfo info,
  Map<String, PathSchema>? pathSchemas,
  Map<String, SecurityScheme>? securitySchemes,
  List<String>? globalSecurity,
  List<ScalarEnvironment> scalarEnvironments = const [],
  String? scalarActiveEnvironment,
  SecurityConfig security = const SecurityConfig(),
  void Function(Map<String, dynamic>)? onSpecBuilt,
}) {
  return (RequestContext context) {
    if (context.request.method != HttpMethod.get) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final spec = OpenApiBuilder(
      info: info,
      pathSchemas: pathSchemas,
      securitySchemes: securitySchemes,
      globalSecurity: globalSecurity,
      scalarEnvironments: scalarEnvironments,
      scalarActiveEnvironment: scalarActiveEnvironment,
    ).build();

    onSpecBuilt?.call(spec);

    return buildJsonResponse(spec, context.request, security: security);
  };
}

/// Builds a JSON [Response] for [spec], applying CORS headers from [security].
///
/// Exposed separately so that [DartFrogOpenApi] can serve cached specs without
/// re-building them.
Response buildJsonResponse(
  Map<String, dynamic> spec,
  Request request, {
  SecurityConfig security = const SecurityConfig(),
}) {
  final json = const JsonEncoder.withIndent('  ').convert(spec);
  final cors = SecurityGuard.corsHeaders(request, security);

  return Response(
    body: json,
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      ...cors,
    },
  );
}
