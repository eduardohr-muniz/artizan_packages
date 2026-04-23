import 'dart:io';

import 'package:test/test.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';

void main() {
  group('PostmanCollectionBuilder', () {
    test('builds a basic Postman collection from pathSchemas', () {
      final builder = PostmanCollectionBuilder(
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

      final collection = builder.build();

      expect(collection['info']['name'], equals('My API'));
      expect(collection['item'], isA<List>());

      final items = collection['item'] as List;
      expect(items.length, equals(1));

      final folder = items.first as Map<String, dynamic>;
      expect(folder['name'], equals('Greeting')); // folder tag

      final endpoint = (folder['item'] as List).first as Map<String, dynamic>;
      expect(endpoint['name'], equals('Say hello'));

      final request = endpoint['request'] as Map<String, dynamic>;
      expect(request['method'], equals('GET'));
      
      final url = request['url'] as Map<String, dynamic>;
      expect(url['raw'], equals('{{baseUrl}}/hello'));
    });
  });
}
