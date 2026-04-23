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
            ),
          ),
        },
      );

      final spec = builder.build();

      expect(spec['openapi'], equals('3.0.0'));
      expect(spec['info']['title'], equals('API'));
      expect(spec['paths']['/test']['get']['summary'], equals('Test GET'));
    });
  });
}
