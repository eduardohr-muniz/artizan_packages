import 'package:test/test.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';

void main() {
  group('BrunoCollectionBuilder', () {
    test('builds a basic Bruno collection from pathSchemas', () {
      final builder = BrunoCollectionBuilder(
        info: const OpenApiInfo(title: 'My API', version: '1.0.0'),
        baseUrl: 'http://localhost:8080',
        pathSchemas: {
          '/hello': PathSchema(
            get: OperationSchema(
              summary: 'Say hello',
              description: 'Returns a greeting',
              tags: ['Greeting'],
              responseSchemas: {
                200: OpenApiSchema(
                  typeName: 'ResponseSchema',
                  jsonSchema: {
                    'type': 'object',
                    'properties': {
                      'message': {'type': 'string'},
                    },
                  },
                ),
              },
            ),
          ),
        },
      );

      final files = builder.build();

      expect(files.keys, contains('bruno.json'));
      expect(files.keys, contains('environments/local.bru'));
      expect(files.keys, contains('Greeting/say_hello.bru'));

      final bruContent = files['Greeting/say_hello.bru']!;
      expect(bruContent, contains('meta {'));
      expect(bruContent, contains('name: Say hello'));
      expect(bruContent, contains('get {'));
      expect(bruContent, contains('url: {{baseUrl}}/hello'));
    });
  });
}
