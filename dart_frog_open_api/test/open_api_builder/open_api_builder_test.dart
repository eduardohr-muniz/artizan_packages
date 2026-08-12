import 'package:test/test.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';

void main() {
  group('OpenApiBuilder', () {
    test('builds OpenAPI spec from pathSchemas', () {
      final builder = OpenApiBuilder(
        info: const OpenApiInfo(title: 'API', version: '1.0'),
        pathSchemas: {
          '/test': PathSchema(
            get: OperationSchema(
              summary: 'Test GET',
              responseSchemas: {200: null},
            ),
          ),
        },
      );

      final spec = builder.build();

      expect(spec['openapi'], equals('3.0.0'));
      expect(spec['info']['title'], equals('API'));
      expect(spec['paths']['/test']['get']['summary'], equals('Test GET'));
    });

    test('emits top-level tags sorted alphabetically', () {
      final builder = OpenApiBuilder(
        info: const OpenApiInfo(title: 'API', version: '1.0'),
        pathSchemas: {
          '/zebra': PathSchema(
            get: OperationSchema(responseSchemas: {200: null}),
          ),
          '/apple': PathSchema(
            get: OperationSchema(responseSchemas: {200: null}),
          ),
          '/mango': PathSchema(
            get: OperationSchema(
              tags: ['Mango'],
              responseSchemas: {200: null},
            ),
          ),
        },
      );

      final spec = builder.build();

      final tags = (spec['tags'] as List)
          .map((t) => (t as Map)['name'] as String)
          .toList();
      expect(tags, equals(['apple', 'Mango', 'zebra']));
    });

    test('deduplicates tags shared across operations', () {
      final builder = OpenApiBuilder(
        info: const OpenApiInfo(title: 'API', version: '1.0'),
        pathSchemas: {
          '/users': PathSchema(
            get: OperationSchema(responseSchemas: {200: null}),
            post: OperationSchema(responseSchemas: {200: null}),
          ),
          '/users/{id}': PathSchema(
            get: OperationSchema(responseSchemas: {200: null}),
          ),
        },
      );

      final spec = builder.build();

      final tags = (spec['tags'] as List)
          .map((t) => (t as Map)['name'] as String)
          .toList();
      expect(tags, equals(['users']));
    });

    test('omits top-level tags when there are no operations', () {
      final builder = OpenApiBuilder(
        info: const OpenApiInfo(title: 'API', version: '1.0'),
      );

      final spec = builder.build();

      expect(spec.containsKey('tags'), isFalse);
    });
  });
}
