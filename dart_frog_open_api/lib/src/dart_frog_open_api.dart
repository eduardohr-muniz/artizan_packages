import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'dart_frog/swagger_handler.dart' as json_handler;
import 'dart_frog/swagger_ui_handler.dart' as ui_handler;
import 'dart_frog/scalar_ui_handler.dart' as scalar_handler;
import 'open_api_builder/scalar_options.dart';
import 'open_api_config.dart';
import 'security/security_cache_holder.dart';
import 'security/security_guard.dart';

/// Central configuration and handlers for OpenAPI/Swagger in Dart Frog.
///
/// Instantiate it in your `main.dart` init before the server starts:
///
/// ```dart
/// // main.dart
/// import 'package:dart_frog/dart_frog.dart';
/// import 'package:dart_frog_open_api/dart_frog_open_api.dart';
/// import 'package:example/api_config.dart';
///
/// late final DartFrogOpenApi openApi;
///
/// Future<void> init(InternetAddress ip, int port) async {
///   openApi = DartFrogOpenApi(config: openApiConfig);
/// }
/// ```
///
/// Then use the handlers in your routes:
///
/// ```dart
/// // routes/swagger/index.dart
/// FutureOr<Response> onRequest(RequestContext context) =>
///     openApi.swaggerUiHandler()(context);
///
/// // routes/swagger/json.dart
/// FutureOr<Response> onRequest(RequestContext context) =>
///     openApi.openApiJsonHandler()(context);
/// ```
class DartFrogOpenApi {
  /// Initializes a new OpenAPI instance with the given config.
  ///
  /// Emits a warning to [stderr] for any configured server using HTTP on a
  /// non-localhost address.
  DartFrogOpenApi({required this.config})
      : _cacheHolder = SecurityCacheHolder() {
    _cacheHolder.reset(config.security.cacheTtl);
    _warnIfInsecureServers(config);
  }

  /// The active configuration for this instance.
  final OpenApiConfig config;

  final SecurityCacheHolder _cacheHolder;

  /// Clears the stored config and spec cache. Used in tests.
  void invalidateCache() {
    _cacheHolder.invalidate();
  }

  /// Returns a handler that serves the OpenAPI 3.0 JSON spec.
  ///
  /// Returns **404** when [SecurityConfig.enabled] is `false`.
  /// Returns **403** when the guard function denies the request.
  Handler openApiJsonHandler() {
    return (RequestContext context) {
      final check = _checkAccess(context.request, config);
      if (check != null) return check;

      _logAccess(config, context.request, 'openapi-json');

      final cached = _cacheHolder.cache.get();
      if (cached != null) {
        return json_handler.buildJsonResponse(cached, context.request, security: config.security);
      }

      return json_handler.swaggerJsonHandler(
        info: config.info,
        pathSchemas: config.pathSchemas,
        securitySchemes: config.resolvedSecuritySchemes,
        globalSecurity: config.globalSecurity,
        scalarEnvironments: config.scalarEnvironments,
        scalarActiveEnvironment: config.scalarActiveEnvironment,
        security: config.security,
        onSpecBuilt: _cacheHolder.cache.set,
      )(context);
    };
  }

  /// Returns a handler that serves the Swagger UI HTML page.
  ///
  /// Returns **404** when [SecurityConfig.enabled] is `false`.
  /// Returns **403** when the guard function denies the request.
  Handler swaggerUiHandler() {
    return (RequestContext context) {
      final check = _checkAccess(context.request, config);
      if (check != null) return check;

      _logAccess(config, context.request, 'swagger-ui');

      return ui_handler.swaggerUiHandler(
        specUrl: config.specUrl,
        info: config.info,
        pathSchemas: config.pathSchemas,
        securitySchemes: config.resolvedSecuritySchemes,
        baseUrl: config.baseUrl,
        brunoOutputDir: config.brunoOutputDir,
        security: config.security,
      )(context);
    };
  }

  /// Returns a handler that serves the Scalar UI HTML page.
  ///
  /// Returns **404** when [SecurityConfig.enabled] is `false`.
  /// Returns **403** when the guard function denies the request.
  Handler scalarUiHandler({ScalarOptions options = const ScalarOptions()}) {
    final hasBearerAuth = config.resolvedSecuritySchemes.containsKey('BearerAuth') ||
        (config.globalSecurity?.contains('BearerAuth') ?? false);

    // Only set preferredSecurityScheme so Scalar shows the correct auth panel.
    // The token itself is injected by the JS interceptor after login.
    final authentication = hasBearerAuth
        ? <String, dynamic>{'preferredSecurityScheme': 'BearerAuth'}
        : null;

    return (RequestContext context) {
      final check = _checkAccess(context.request, config);
      if (check != null) return check;

      _logAccess(config, context.request, 'scalar-ui');

      return scalar_handler.scalarUiHandler(
        specUrl: config.specUrl,
        options: options,
        security: config.security,
        authentication: authentication,
      )(context);
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a [Response] if the request should be denied, or `null` if allowed.
  static Response? _checkAccess(Request request, OpenApiConfig c) {
    if (!c.security.enabled) {
      return Response(statusCode: HttpStatus.notFound);
    }
    if (!SecurityGuard.isAllowed(request, c.security)) {
      return Response(statusCode: HttpStatus.forbidden);
    }
    return null;
  }

  static void _logAccess(OpenApiConfig c, Request request, String endpoint) {
    if (!c.security.logAccess) return;
    final time = DateTime.now().toIso8601String();
    final method = request.method.name.toUpperCase();
    stdout.writeln('[dart_frog_open_api] $time $method /$endpoint');
  }

  static void _warnIfInsecureServers(OpenApiConfig config) {
    for (final server in config.info.servers) {
      final uri = Uri.tryParse(server);
      if (uri != null &&
          uri.scheme == 'http' &&
          uri.host != 'localhost' &&
          uri.host != '127.0.0.1') {
        stderr.writeln(
          '⚠️  [dart_frog_open_api] Server "$server" uses HTTP without TLS. '
          'Consider HTTPS for non-local environments.',
        );
      }
    }
  }
}
