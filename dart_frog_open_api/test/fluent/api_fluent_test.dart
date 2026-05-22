import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import 'package:test/test.dart';
import 'package:zto/zto.dart';

const _itemSchema = ZtoSchema(
  typeName: 'ItemDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'id'), validators: [], isNullable: false),
  ],
);

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

    test('returnsListOf sets array responseSchema and description', () {
      final pathSchema = Api.path()
          .get((op) => op
              .summary('List items')
              .returnsListOf(200, _itemSchema, description: 'Lista de itens'))
          .build();

      final op = pathSchema.get!;
      expect(op.responseDescriptions[200], equals('Lista de itens'));

      final schema = op.responseSchemas[200]!;
      expect(schema.typeName, equals('ItemDtoList'));
      expect(schema.jsonSchema['type'], equals('array'));
      final items = schema.jsonSchema['items'] as Map<String, dynamic>;
      expect(items[r'$ref'], equals('#/components/schemas/ItemDto'));
    });

    test('returnsListOf without description leaves responseDescriptions empty', () {
      final pathSchema = Api.path()
          .get((op) => op.summary('X').returnsListOf(200, _itemSchema))
          .build();

      expect(pathSchema.get!.responseDescriptions.containsKey(200), isFalse);
    });

    group('queryParam', () {
      test('adds a required string query parameter', () {
        final pathSchema = Api.path()
            .get(
              (op) => op
                  .summary('Get me')
                  .queryParam('user_id', description: 'ID do usuário', required: true),
            )
            .build();

        final params = pathSchema.get!.queryParameters;
        expect(params.length, equals(1));
        expect(params.first.name, equals('user_id'));
        expect(params.first.type, equals('string'));
        expect(params.first.required, isTrue);
        expect(params.first.description, equals('ID do usuário'));
      });

      test('defaults required to false', () {
        final pathSchema = Api.path()
            .get((op) => op.summary('X').queryParam('filter'))
            .build();

        expect(pathSchema.get!.queryParameters.first.required, isFalse);
      });

      test('accepts optional example', () {
        final pathSchema = Api.path()
            .get(
              (op) => op
                  .summary('X')
                  .queryParam('page', example: '1'),
            )
            .build();

        expect(pathSchema.get!.queryParameters.first.example, equals('1'));
      });

      test('can chain multiple queryParam calls', () {
        final pathSchema = Api.path()
            .get(
              (op) => op
                  .summary('X')
                  .queryParam('user_id', required: true)
                  .queryParam('include_deleted'),
            )
            .build();

        final params = pathSchema.get!.queryParameters;
        expect(params.length, equals(2));
        expect(params[0].name, equals('user_id'));
        expect(params[1].name, equals('include_deleted'));
      });
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
