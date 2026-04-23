import 'dart:io';

import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:dart_frog_open_api/dart_frog_open_api.dart';

class _MockRequestContext extends Mock implements frog.RequestContext {}

class _MockRequest extends Mock implements frog.Request {}

/// Builds a GET RequestContext mock with optional headers.
_MockRequestContext _ctx(
  _MockRequest request, {
  Map<String, String> headers = const {},
  Uri? uri,
}) {
  final ctx = _MockRequestContext();
  when(() => ctx.request).thenReturn(request);
  when(() => request.method).thenReturn(frog.HttpMethod.get);
  when(() => request.headers).thenReturn(headers);
  when(() => request.uri).thenReturn(uri ?? Uri.parse('/swagger'));
  return ctx;
}

void main() {
  group('openApiJsonHandler — security', () {
    test('returns 404 when SecurityConfig.enabled is false (default)', () async {
      final openApi = DartFrogOpenApi(config: const OpenApiConfig(
        info: OpenApiInfo(title: 'T', version: '1.0'),
      ));

      final request = _MockRequest();
      final ctx = _ctx(request);
      final response = await openApi.openApiJsonHandler()(ctx);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 200 when enabled is true and no guard', () async {
      final openApi = DartFrogOpenApi(config: const OpenApiConfig(
        info: OpenApiInfo(title: 'T', version: '1.0'),
        security: SecurityConfig(enabled: true),
      ));

      final request = _MockRequest();
      final ctx = _ctx(request);
      final response = await openApi.openApiJsonHandler()(ctx);

      expect(response.statusCode, equals(HttpStatus.ok));
    });

    test('returns 403 when enabled but guard returns false', () async {
      final openApi = DartFrogOpenApi(config: OpenApiConfig(
        info: const OpenApiInfo(title: 'T', version: '1.0'),
        security: SecurityConfig(enabled: true, guard: (_) => false),
      ));

      final request = _MockRequest();
      final ctx = _ctx(request);
      final response = await openApi.openApiJsonHandler()(ctx);

      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('returns 200 when enabled and guard returns true', () async {
      final openApi = DartFrogOpenApi(config: OpenApiConfig(
        info: const OpenApiInfo(title: 'T', version: '1.0'),
        security: SecurityConfig(enabled: true, guard: (_) => true),
      ));

      final request = _MockRequest();
      final ctx = _ctx(request);
      final response = await openApi.openApiJsonHandler()(ctx);

      expect(response.statusCode, equals(HttpStatus.ok));
    });

    group('CORS', () {
      test('no CORS headers when corsOrigins is null', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          security: SecurityConfig(enabled: true),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request, headers: {'Origin': 'http://localhost:3000'});
        final response = await openApi.openApiJsonHandler()(ctx);

        expect(response.headers.containsKey('access-control-allow-origin'), isFalse);
      });

      test('CORS header is set for allowed origin', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          security: SecurityConfig(
            enabled: true,
            corsOrigins: ['http://localhost:3000'],
          ),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request, headers: {'Origin': 'http://localhost:3000'});
        final response = await openApi.openApiJsonHandler()(ctx);

        expect(response.headers['access-control-allow-origin'], equals('http://localhost:3000'));
      });

      test('CORS header is never wildcard *', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          security: SecurityConfig(
            enabled: true,
            corsOrigins: ['http://localhost:3000'],
          ),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request, headers: {'Origin': 'http://localhost:3000'});
        final response = await openApi.openApiJsonHandler()(ctx);

        expect(response.headers['access-control-allow-origin'], isNot(equals('*')));
      });

      test('no CORS header for origin not in allowlist', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          security: SecurityConfig(
            enabled: true,
            corsOrigins: ['http://localhost:3000'],
          ),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request, headers: {'Origin': 'https://evil.com'});
        final response = await openApi.openApiJsonHandler()(ctx);

        expect(response.headers.containsKey('access-control-allow-origin'), isFalse);
      });
    });
  });

  group('swaggerUiHandler — security', () {
    test('returns 404 when enabled is false', () async {
      final openApi = DartFrogOpenApi(config: const OpenApiConfig(
        info: OpenApiInfo(title: 'T', version: '1.0'),
      ));

      final request = _MockRequest();
      final ctx = _ctx(request);
      final response = await openApi.swaggerUiHandler()(ctx);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 200 when enabled', () async {
      final openApi = DartFrogOpenApi(config: const OpenApiConfig(
        info: OpenApiInfo(title: 'T', version: '1.0'),
        security: SecurityConfig(enabled: true),
      ));

      final request = _MockRequest();
      final ctx = _ctx(request);
      final response = await openApi.swaggerUiHandler()(ctx);

      expect(response.statusCode, equals(HttpStatus.ok));
    });

    group('security headers', () {
      test('includes X-Content-Type-Options: nosniff', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          security: SecurityConfig(enabled: true, securityHeaders: true),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request);
        final response = await openApi.swaggerUiHandler()(ctx);

        expect(response.headers['x-content-type-options'], equals('nosniff'));
      });

      test('includes X-Frame-Options: DENY', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          security: SecurityConfig(enabled: true, securityHeaders: true),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request);
        final response = await openApi.swaggerUiHandler()(ctx);

        expect(response.headers['x-frame-options'], equals('DENY'));
      });

      test('includes Content-Security-Policy', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          security: SecurityConfig(enabled: true, securityHeaders: true),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request);
        final response = await openApi.swaggerUiHandler()(ctx);

        expect(response.headers['content-security-policy'], isNotNull);
        expect(response.headers['content-security-policy'], contains('unpkg.com'));
      });

      test('no security headers when securityHeaders is false', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          security: SecurityConfig(enabled: true, securityHeaders: false),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request);
        final response = await openApi.swaggerUiHandler()(ctx);

        expect(response.headers.containsKey('x-frame-options'), isFalse);
        expect(response.headers.containsKey('x-content-type-options'), isFalse);
      });
    });

    group('XSS prevention', () {
      test('specUrl with script injection is sanitized in HTML output', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(title: 'T', version: '1.0'),
          specUrl: '"/><script>alert(1)</script>',
          security: SecurityConfig(enabled: true),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request);
        final response = await openApi.swaggerUiHandler()(ctx);
        final body = await response.body();

        expect(body, isNot(contains('<script>alert(1)</script>')));
      });

      test('info.title with HTML tags is escaped in HTML output', () async {
        final openApi = DartFrogOpenApi(config: const OpenApiConfig(
          info: OpenApiInfo(
            title: '<img src=x onerror=alert(1)>',
            version: '1.0',
          ),
          security: SecurityConfig(enabled: true),
        ));

        final request = _MockRequest();
        final ctx = _ctx(request);
        final response = await openApi.swaggerUiHandler()(ctx);
        final body = await response.body();

        expect(body, isNot(contains('<img src=x onerror=alert(1)>')));
      });
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Bruno — credential placeholders
  // ──────────────────────────────────────────────────────────────────────────
  group('BrunoCollectionBuilder — credential safety', () {
    test('environment file does not contain "test-token-123"', () {
      final files = BrunoCollectionBuilder(
        info: const OpenApiInfo(title: 'T', version: '1.0'),
        securitySchemes: const {
          'BearerAuth': SecurityScheme.bearer,
        },
      ).build();

      final env = files['environments/local.bru']!;
      expect(env, isNot(contains('test-token-123')));
    });

    test('environment file does not contain "test-api-key"', () {
      final files = BrunoCollectionBuilder(
        info: const OpenApiInfo(title: 'T', version: '1.0'),
        securitySchemes: const {
          'ApiKey': ApiKeyScheme(name: 'X-API-Key', location: 'header'),
        },
      ).build();

      final env = files['environments/local.bru']!;
      expect(env, isNot(contains('test-api-key')));
    });

    test('environment file does not contain "user:password"', () {
      final files = BrunoCollectionBuilder(
        info: const OpenApiInfo(title: 'T', version: '1.0'),
        securitySchemes: const {
          'BasicAuth': SecurityScheme.basic,
        },
      ).build();

      final env = files['environments/local.bru']!;
      expect(env, isNot(contains('user:password')));
    });

    test('bearer token placeholder uses angle-bracket format', () {
      final files = BrunoCollectionBuilder(
        info: const OpenApiInfo(title: 'T', version: '1.0'),
        securitySchemes: const {
          'BearerAuth': SecurityScheme.bearer,
        },
      ).build();

      final env = files['environments/local.bru']!;
      expect(env, contains('<your-bearer-token>'));
    });

    test('api key placeholder uses angle-bracket format', () {
      final files = BrunoCollectionBuilder(
        info: const OpenApiInfo(title: 'T', version: '1.0'),
        securitySchemes: const {
          'ApiKey': ApiKeyScheme(name: 'X-API-Key', location: 'header'),
        },
      ).build();

      final env = files['environments/local.bru']!;
      expect(env, contains('<your-api-key>'));
    });
  });
}
