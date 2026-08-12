import 'dart:io';

import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:dart_frog_open_api/src/dart_frog/swagger_ui_handler.dart'
    as swagger;

class _MockRequestContext extends Mock implements frog.RequestContext {}

class _MockRequest extends Mock implements frog.Request {}

void main() {
  group('swaggerUiHandler', () {
    late _MockRequestContext ctx;
    late _MockRequest request;

    setUp(() {
      ctx = _MockRequestContext();
      request = _MockRequest();
      when(() => ctx.request).thenReturn(request);
      when(() => request.headers).thenReturn({});
      when(() => request.uri).thenReturn(Uri.parse('/docs'));
    });

    test('returns 405 for non-GET requests', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.post);

      final handler = swagger.swaggerUiHandler();
      final response = await handler(ctx);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('returns 200 with Swagger UI HTML for GET requests', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = swagger.swaggerUiHandler();
      final response = await handler(ctx);
      final body = await response.body();

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body, contains('<!DOCTYPE html>'));
      expect(body, contains('SwaggerUIBundle'));
    });

    test('defaults docExpansion to "list"', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = swagger.swaggerUiHandler();
      final response = await handler(ctx);
      final body = await response.body();

      expect(body, contains('docExpansion: "list"'));
    });

    test('honours docExpansion "none" (fully minimized)', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = swagger.swaggerUiHandler(docExpansion: 'none');
      final response = await handler(ctx);
      final body = await response.body();

      expect(body, contains('docExpansion: "none"'));
    });

    test('honours docExpansion "full" (fully expanded)', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = swagger.swaggerUiHandler(docExpansion: 'full');
      final response = await handler(ctx);
      final body = await response.body();

      expect(body, contains('docExpansion: "full"'));
    });

    test('falls back to "list" for an invalid docExpansion value', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = swagger.swaggerUiHandler(docExpansion: 'bogus');
      final response = await handler(ctx);
      final body = await response.body();

      expect(body, contains('docExpansion: "list"'));
      expect(body, isNot(contains('bogus')));
    });

    test('sorts tags and operations alphabetically', () async {
      when(() => request.method).thenReturn(frog.HttpMethod.get);

      final handler = swagger.swaggerUiHandler();
      final response = await handler(ctx);
      final body = await response.body();

      expect(body, contains('tagsSorter: "alpha"'));
      expect(body, contains('operationsSorter: "alpha"'));
    });
  });
}
