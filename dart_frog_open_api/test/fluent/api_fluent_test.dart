import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import 'package:test/test.dart';

void main() {
  group('Api Fluent Builder', () {
    test('builds a simple PathSchema with GET and POST', () {
      final pathSchema = Api.path()
          .get((op) => op
              .summary('List items')
              .tag('Items')
              .public()
              .query('page', ParamType.integer, example: 1)
              .returns(200, description: 'Success list')
          )
          .post((op) => op
              .summary('Create item')
              .returns(201, description: 'Created item')
          )
          .build();

      expect(pathSchema.get, isNotNull);
      expect(pathSchema.get!.summary, equals('List items'));
      expect(pathSchema.get!.tags, equals(['Items']));
      expect(pathSchema.get!.security, equals([]));
      expect(pathSchema.get!.queryParameters.length, equals(1));
      expect(pathSchema.get!.queryParameters.first.name, equals('page'));
      expect(pathSchema.get!.queryParameters.first.type, equals('integer'));
      expect(pathSchema.get!.queryParameters.first.example, equals(1));
      expect(pathSchema.get!.responseDescriptions[200], equals('Success list'));

      expect(pathSchema.post, isNotNull);
      expect(pathSchema.post!.summary, equals('Create item'));
      expect(pathSchema.post!.responseDescriptions[201], equals('Created item'));
      expect(pathSchema.put, isNull);
    });

    test('builds PathSchema with path parameters', () {
      final pathSchema = Api.path()
          .param('id', ParamType.string, description: 'ID param')
          .get((op) => op.summary('Get by ID'))
          .build();

      expect(pathSchema.pathParameters.length, equals(1));
      expect(pathSchema.pathParameters['id'], isNotNull);
      expect(pathSchema.pathParameters['id']!.name, equals('id'));
      expect(pathSchema.pathParameters['id']!.type, equals('string'));
      expect(pathSchema.pathParameters['id']!.description, equals('ID param'));
    });
  });
}
