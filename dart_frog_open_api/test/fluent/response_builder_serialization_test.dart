import 'package:test/test.dart';
import 'package:zto/zto.dart';

import '../../lib/dart_frog_open_api.dart';

// ── Schemas (espelham o que o zto_generator produziria) ─────────────────────

const $userResponseDtoSchema = ZtoSchema(
  typeName: 'UserResponseDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'id'), validators: [], isNullable: false),
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'name'), validators: [], isNullable: false),
  ],
);

const $userListItemDtoSchema = ZtoSchema(
  typeName: 'UserListItemDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'id'), validators: [], isNullable: false),
  ],
);

Map<String, dynamic> _specFor(PathSchema path) => OpenApiBuilder(
      info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
      pathSchemas: {'/v1/users': path},
    ).build();

Map<String, dynamic> _op(Map<String, dynamic> spec, String method) =>
    (spec['paths']['/v1/users'][method] as Map).cast<String, dynamic>();

void main() {
  group('ResponseBuilder → serialização OpenAPI', () {
    test('response(ztoSchema) gera \$ref, descrição e registra o componente', () {
      final path = Api.path()
          .get((op) => op.public().response(
                200,
                ztoSchema: $userResponseDtoSchema,
                description: 'Usuário',
              ))
          .build();

      final spec = _specFor(path);
      final res = _op(spec, 'get')['responses']['200'] as Map;

      expect(res['description'], equals('Usuário'));
      final schema = res['content']['application/json']['schema'] as Map;
      expect(schema[r'$ref'], equals('#/components/schemas/UserResponseDto'));

      final components = spec['components']['schemas'] as Map;
      expect(components.containsKey('UserResponseDto'), isTrue);
    });

    test('response(header) ancora o header no status correto', () {
      final path = Api.path()
          .get((op) => op.public().response(
                200,
                ztoSchema: $userResponseDtoSchema,
                headers: const [
                  ResHeader('X-Total-Count', ParamType.integer,
                      description: 'Total de registros'),
                ],
              ))
          .build();

      final res = _op(_specFor(path), 'get')['responses']['200'] as Map;
      final header = res['headers']['X-Total-Count'] as Map;
      expect(header['description'], equals('Total de registros'));
      expect(header['schema']['type'], equals('integer'));
    });

    test('listOfZtoSchema referencia o wrapper de lista e registra item + lista', () {
      final path = Api.path()
          .get((op) => op.public().ok(listOfZtoSchema: $userListItemDtoSchema))
          .build();

      final spec = _specFor(path);
      final schema = _op(spec, 'get')['responses']['200']['content']
          ['application/json']['schema'] as Map;

      // O corpo referencia o componente de lista.
      expect(schema[r'$ref'], equals('#/components/schemas/UserListItemDtoList'));

      final schemas = (spec['components']['schemas'] as Map).cast<String, dynamic>();
      // Tanto a lista quanto o item devem existir (sem $ref pendurado).
      expect(schemas.containsKey('UserListItemDtoList'), isTrue);
      expect(schemas.containsKey('UserListItemDto'), isTrue);
      final listSchema = schemas['UserListItemDtoList'] as Map;
      expect(listSchema['type'], equals('array'));
      expect(listSchema['items'][r'$ref'],
          equals('#/components/schemas/UserListItemDto'));
    });

    test('json(resposta real) emite schema inline inferido + example, sem componente', () {
      final path = Api.path()
          .get((op) => op.public().ok(json: const {'pong': true}))
          .build();

      final spec = _specFor(path);
      final schema = _op(spec, 'get')['responses']['200']['content']
          ['application/json']['schema'] as Map;

      expect(schema.containsKey(r'$ref'), isFalse);
      expect(schema['type'], equals('object'));
      expect(schema['properties']['pong']['type'], equals('boolean'));
      // O valor literal vira o example do schema (resposta real).
      expect(schema['example'], equals({'pong': true}));
      // Schema inline não vira componente (typeName vazio); quando não há
      // nenhum componente, a chave `components` pode nem existir.
      final schemas = (spec['components'] as Map?)?['schemas'] as Map?;
      expect(schemas == null || !schemas.containsKey(''), isTrue);
    });

    test('created(headers:) gera 201 com \$ref e header Location', () {
      final path = Api.path()
          .post((op) => op.public().created(
                ztoSchema: $userResponseDtoSchema,
                headers: const [
                  ResHeader('Location', ParamType.string,
                      description: 'URL do novo recurso', format: 'uri'),
                ],
              ))
          .build();

      final res = _op(_specFor(path), 'post')['responses']['201'] as Map;
      expect(res['content']['application/json']['schema'][r'$ref'],
          equals('#/components/schemas/UserResponseDto'));
      expect(res['headers']['Location']['schema']['type'], equals('string'));
      expect(res['headers']['Location']['schema']['format'], equals('uri'));
      expect(res['headers']['Location']['description'], equals('URL do novo recurso'));
    });

    test('noContent() gera 204 sem bloco content', () {
      final path = Api.path()
          .delete((op) => op.public().noContent())
          .build();

      final res = _op(_specFor(path), 'delete')['responses']['204'] as Map;
      expect(res['description'], equals('No Content'));
      expect(res.containsKey('content'), isFalse);
    });

    test('badRequest(description:) gera 400 sem corpo', () {
      final path = Api.path()
          .post((op) => op.public().badRequest(description: 'Dados inválidos'))
          .build();

      final res = _op(_specFor(path), 'post')['responses']['400'] as Map;
      expect(res['description'], equals('Dados inválidos'));
      expect(res.containsKey('content'), isFalse);
    });

    test('contentType custom emite o media type informado (problem+json)', () {
      final path = Api.path()
          .post((op) => op.public().response(
                422,
                ztoSchema: $userResponseDtoSchema,
                contentType: 'application/problem+json',
                description: 'Validação',
              ))
          .build();

      final content = _op(_specFor(path), 'post')['responses']['422']['content']
          as Map;
      expect(content.keys.single, equals('application/problem+json'));
      expect(content['application/problem+json']['schema'][r'$ref'],
          equals('#/components/schemas/UserResponseDto'));
    });

    test('serverError() serializa 500 com descrição padrão', () {
      final path = Api.path()
          .get((op) => op.public().serverError())
          .build();

      final res = _op(_specFor(path), 'get')['responses']['500'] as Map;
      expect(res['description'], equals('Internal Server Error'));
    });
  });
}
