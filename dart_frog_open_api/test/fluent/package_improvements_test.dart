import 'package:test/test.dart';
import 'package:zto/zto.dart';

import 'package:dart_frog_open_api/dart_frog_open_api.dart';

const $createUserDtoSchema = ZtoSchema(
  typeName: 'CreateUserDto',
  descriptors: [
    FieldDescriptor(
        fieldAnnotation: ZString(mapKey: 'name'),
        validators: [],
        isNullable: false),
  ],
);

const $wsMessageDtoSchema = ZtoSchema(
  typeName: 'WsMessageDto',
  descriptors: [
    FieldDescriptor(
        fieldAnnotation: ZString(mapKey: 'type'),
        validators: [],
        isNullable: false),
  ],
);

Map<String, dynamic> _spec(Map<String, PathSchema> paths,
        {List<String>? globalSecurity}) =>
    OpenApiBuilder(
      info: const OpenApiInfo(title: 'T'),
      pathSchemas: paths,
      globalSecurity: globalSecurity,
    ).build();

void main() {
  group('#6 — operação sem response é rejeitada', () {
    test('build() lança StateError quando uma operação não tem response', () {
      final doc =
          Api.path().get((op) => op.summary('Sem response').public()).build();

      expect(
        () => _spec({'/x': doc}),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('no responses'))),
      );
    });
  });

  group('#7 — operationId duplicado é rejeitado', () {
    test('build() lança StateError em operationId colidente', () {
      // Mesmo método + path normalizado idêntico → mesmo operationId.
      final a = Api.path().get((op) => op.summary('A').public().ok()).build();
      final b = Api.path().get((op) => op.summary('A').public().ok()).build();

      // Dois paths que normalizam para o mesmo operationId.
      expect(
        () => _spec({'/users/list': a, '/users-list': b}),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('Duplicate operationId'))),
      );
    });
  });

  group('#8 — security scheme não definido é rejeitado', () {
    test('build() lança StateError ao referenciar scheme inexistente', () {
      final doc = Api.path()
          .get((op) => op.summary('X').security(['ApiKey']).ok())
          .build();

      expect(
        () => _spec({'/x': doc}),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            allOf(contains('ApiKey'), contains('not defined')))),
      );
    });

    test('BearerAuth é auto-definido para rotas protegidas (não lança)', () {
      final doc = Api.path()
          .get((op) => op.summary('X').security(['BearerAuth']).ok())
          .build();

      expect(() => _spec({'/x': doc}), returnsNormally);
    });
  });

  group('#1 — content-type do request body nas collections', () {
    PathSchema uploadPath() => Api.path()
        .post((op) => op
            .summary('Upload')
            .bytesBody(contentType: 'image/png')
            .response(201))
        .build();

    PathSchema jsonPath() => Api.path()
        .post((op) => op.summary('Criar').body($createUserDtoSchema).created())
        .build();

    test('Postman usa requestContentType (binário) em vez de application/json',
        () {
      final collection = PostmanCollectionBuilder(
        info: const OpenApiInfo(title: 'T'),
        pathSchemas: {'/upload': uploadPath()},
      ).build();

      final json = collection.toString();
      expect(json, contains('image/png'));
      // body raw vira placeholder, não JSON.
      expect(json, contains('<image/png payload>'));
    });

    test('Postman mantém application/json para body JSON', () {
      final collection = PostmanCollectionBuilder(
        info: const OpenApiInfo(title: 'T'),
        pathSchemas: {'/users': jsonPath()},
      ).build();
      expect(collection.toString(), contains('application/json'));
    });

    test('Bruno usa requestContentType e body:text para não-JSON', () {
      final bruno = BrunoCollectionBuilder(
        info: const OpenApiInfo(title: 'T'),
        pathSchemas: {'/upload': uploadPath()},
      ).build();

      final content = bruno.values.join('\n');
      expect(content, contains('Content-Type: image/png'));
      expect(content, contains('body:text'));
    });
  });

  group('#9 — websocket inline não é registrado como componente', () {
    test('websocket com zto schema registra componente normalmente', () {
      final doc = Api.path()
          .get((op) => op
              .summary('WS')
              .public()
              .websocket(messageZtoSchema: $wsMessageDtoSchema))
          .build();

      final spec = _spec({'/ws': doc});
      expect((spec['components']['schemas'] as Map).containsKey('WsMessageDto'),
          isTrue);
      // Nunca registra um componente de typeName vazio.
      expect((spec['components']['schemas'] as Map).containsKey(''), isFalse);
    });
  });
}
