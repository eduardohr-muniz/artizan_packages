import 'dart:io';

import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../lib/src/dart_frog/scalar_ui_handler.dart' as scalar;
import '../../lib/src/open_api_builder/scalar_options.dart';
import '../../lib/src/security/security_config.dart';

class _MockRequestContext extends Mock implements frog.RequestContext {}

class _MockRequest extends Mock implements frog.Request {}

void main() {
  group('scalarUiHandler', () {
    late _MockRequestContext ctx;
    late _MockRequest request;

    setUp(() {
      ctx = _MockRequestContext();
      request = _MockRequest();
      when(() => ctx.request).thenReturn(request);
    });

    test('returns 405 for non-GET requests', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.post);

      final handler = scalar.scalarUiHandler();
      final response = await handler(ctx);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('returns 200 with HTML for GET requests', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = scalar.scalarUiHandler();
      final response = await handler(ctx);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        contains('text/html'),
      );

      final body = await response.body();
      expect(body, contains('<!DOCTYPE html>'));
      expect(body, contains('@scalar/api-reference'));
    });

    test('HTML contains data-url pointing to specUrl', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = scalar.scalarUiHandler(specUrl: '/my-spec');
      final response = await handler(ctx);
      final body = await response.body();

      expect(body, contains('data-url="/my-spec"'));
    });

    test('HTML embeds options as JSON in data-configuration', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      const options = ScalarOptions(theme: 'moon', layout: 'classic');
      final handler = scalar.scalarUiHandler(options: options);
      final response = await handler(ctx);
      final body = await response.body();

      expect(body, contains('data-configuration='));
      expect(body, contains('moon'));
      expect(body, contains('classic'));
    });

    test('quotes in config are HTML-escaped in data-configuration', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = scalar.scalarUiHandler();
      final response = await handler(ctx);
      final body = await response.body();

      // JSON values in the attribute must use &quot; not raw "
      expect(body, contains('&quot;'));
      expect(
        RegExp(r'data-configuration="[^"]*"').hasMatch(body),
        isTrue,
        reason: 'data-configuration attribute must be a valid HTML attribute',
      );
    });

    test('sets security response headers when securityHeaders enabled', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);
      when(() => request.headers).thenReturn({});

      const security = SecurityConfig(securityHeaders: true);
      final handler = scalar.scalarUiHandler(security: security);
      final response = await handler(ctx);

      expect(response.headers['x-content-type-options'], equals('nosniff'));
    });
  });
}
