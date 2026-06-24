import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import 'package:test/test.dart';
import 'package:zto/zto.dart';

const _itemSchema = ZtoSchema(
  typeName: 'ItemDto',
  descriptors: [
    FieldDescriptor(
        fieldAnnotation: ZString(mapKey: 'id'),
        validators: [],
        isNullable: false),
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
              .response(200, description: 'Success list'))
          .post((op) => op
              .summary('Create item')
              .response(201, description: 'Created item'))
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
      expect(
          pathSchema.post!.responseDescriptions[201], equals('Created item'));
      expect(pathSchema.put, isNull);
    });

    test('response com listOfZtoSchema define array responseSchema e descrição',
        () {
      final pathSchema = Api.path()
          .get((op) => op.summary('List items').response(200,
              listOfZtoSchema: _itemSchema, description: 'Lista de itens'))
          .build();

      final op = pathSchema.get!;
      expect(op.responseDescriptions[200], equals('Lista de itens'));

      final schema = op.responseSchemas[200]!;
      expect(schema.typeName, equals('ItemDtoList'));
      expect(schema.jsonSchema['type'], equals('array'));
      final items = schema.jsonSchema['items'] as Map<String, dynamic>;
      expect(items[r'$ref'], equals('#/components/schemas/ItemDto'));
    });

    test('ok(listOfZtoSchema:) sem descrição deixa responseDescriptions vazio',
        () {
      final pathSchema = Api.path()
          .get((op) => op.summary('X').ok(listOfZtoSchema: _itemSchema))
          .build();

      expect(pathSchema.get!.responseDescriptions.containsKey(200), isFalse);
    });

    test('response agrupa schema, header e descrição no mesmo status', () {
      final pathSchema = Api.path()
          .get((op) => op.summary('List').response(
                200,
                ztoSchema: _itemSchema,
                description: 'Lista paginada',
                headers: const [
                  ResHeader('X-Total-Count', ParamType.integer,
                      description: 'Total de registros'),
                ],
              ))
          .build();

      final op = pathSchema.get!;
      expect(op.responseSchemas[200]!.typeName, equals('ItemDto'));
      expect(op.responseDescriptions[200], equals('Lista paginada'));
      final header = op.responseHeaders[200]!.single;
      expect(header.name, equals('X-Total-Count'));
      expect(header.type, equals('integer'));
      expect(header.description, equals('Total de registros'));
    });

    test('json infere schema da resposta real e anexa example', () {
      final pathSchema = Api.path()
          .get((op) =>
              op.summary('Ping').ok(json: const {'pong': true, 'count': 3}))
          .build();

      final schema = pathSchema.get!.responseSchemas[200]!;
      expect(schema.isInline, isTrue);
      expect(schema.typeName, isEmpty);
      expect(schema.jsonSchema['type'], equals('object'));
      final props = schema.jsonSchema['properties'] as Map<String, dynamic>;
      expect(props['pong']['type'], equals('boolean'));
      expect(props['count']['type'], equals('integer'));
      expect(schema.jsonSchema['example'], equals({'pong': true, 'count': 3}));
    });

    test('listOfJson infere array do item e usa [item] como example', () {
      final pathSchema = Api.path()
          .get((op) => op
              .summary('List')
              .response(200, listOfJson: const {'id': 'usr_1'}))
          .build();

      final schema = pathSchema.get!.responseSchemas[200]!;
      expect(schema.isInline, isTrue);
      expect(schema.jsonSchema['type'], equals('array'));
      expect(schema.jsonSchema['items']['type'], equals('object'));
      expect(schema.jsonSchema['items']['properties']['id']['type'],
          equals('string'));
      expect(
          schema.jsonSchema['example'],
          equals([
            {'id': 'usr_1'}
          ]));
    });

    test('created/noContent/badRequest mapeiam para os status corretos', () {
      final pathSchema = Api.path()
          .post((op) => op
                  .summary('Create')
                  .created(ztoSchema: _itemSchema, headers: const [
                ResHeader('Location', ParamType.string,
                    description: 'URL do recurso'),
              ]).badRequest(description: 'Dados inválidos'))
          .delete((op) => op.summary('Delete').noContent())
          .build();

      final post = pathSchema.post!;
      expect(post.responseSchemas.containsKey(201), isTrue);
      expect(post.responseHeaders[201]!.single.name, equals('Location'));
      expect(post.responseSchemas.containsKey(400), isTrue);
      expect(post.responseSchemas[400], isNull);

      final del = pathSchema.delete!;
      expect(del.responseSchemas.containsKey(204), isTrue);
      expect(del.responseSchemas[204], isNull);
    });

    test(
        'accepted/tooManyRequests/serverError/serviceUnavailable mapeiam o status',
        () {
      final pathSchema = Api.path()
          .post((op) => op
              .accepted(ztoSchema: _itemSchema)
              .tooManyRequests(description: 'Rate limit')
              .serverError()
              .serviceUnavailable())
          .build();

      final post = pathSchema.post!;
      expect(post.responseSchemas[202]!.typeName, equals('ItemDto'));
      expect(post.responseDescriptions[429], equals('Rate limit'));
      expect(post.responseSchemas.containsKey(500), isTrue);
      expect(post.responseSchemas.containsKey(503), isTrue);
    });

    test('response com dois modos de corpo dispara AssertionError', () {
      expect(
        () => Api.path().get((op) =>
            op.response(200, ztoSchema: _itemSchema, json: const {'a': 1})),
        throwsA(isA<AssertionError>()),
      );
    });

    test('declarar o mesmo status duas vezes dispara AssertionError', () {
      expect(
        () => Api.path().get((op) => op.ok(ztoSchema: _itemSchema).ok()),
        throwsA(isA<AssertionError>()),
      );
    });

    group('queryParam', () {
      test('adds a required string query parameter', () {
        final pathSchema = Api.path()
            .get(
              (op) => op.summary('Get me').queryParam('user_id',
                  description: 'ID do usuário', required: true),
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
              (op) => op.summary('X').queryParam('page', example: '1'),
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
