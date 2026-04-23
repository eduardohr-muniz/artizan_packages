import 'dart:io';

import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements frog.RequestContext {}

class _MockRequest extends Mock implements frog.Request {}

void main() {
  group('DartFrogOpenApi', () {
    test('initializes normally and instantiates openApiJsonHandler', () {
      final config = OpenApiConfig(
        info: const OpenApiInfo(title: 'T', version: '1'),
      );
      final openApi = DartFrogOpenApi(config: config);

      final handler = openApi.openApiJsonHandler();
      expect(handler, isNotNull);
    });

    test('openApiJsonHandler returns 405 if method is not GET', () async {
      final config = OpenApiConfig(
        info: const OpenApiInfo(title: 'T', version: '1'),
        security: const SecurityConfig(enabled: true),
      );
      final openApi = DartFrogOpenApi(config: config);

      final request = _MockRequest();
      when(() => request.method).thenReturn(frog.HttpMethod.post);

      final ctx = _MockRequestContext();
      when(() => ctx.request).thenReturn(request);

      final response = await openApi.openApiJsonHandler()(ctx);
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('swaggerUiHandler returns 405 if method is not GET', () async {
      final config = OpenApiConfig(
        info: const OpenApiInfo(title: 'T', version: '1'),
        security: const SecurityConfig(enabled: true),
      );
      final openApi = DartFrogOpenApi(config: config);

      final request = _MockRequest();
      when(() => request.method).thenReturn(frog.HttpMethod.post);

      final ctx = _MockRequestContext();
      when(() => ctx.request).thenReturn(request);

      final response = await openApi.swaggerUiHandler()(ctx);
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });
}
