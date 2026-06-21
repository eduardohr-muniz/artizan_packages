import 'package:test/test.dart';
import 'package:zto/zto.dart';

import '../../lib/dart_frog_open_api.dart';

// ── Schemas (espelham o que o zto_generator produziria) ─────────────────────

const $createUserDtoSchema = ZtoSchema(
  typeName: 'CreateUserDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'name'), validators: [], isNullable: false),
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'email'), validators: [], isNullable: false),
  ],
);

const $userResponseDtoSchema = ZtoSchema(
  typeName: 'UserResponseDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'id'), validators: [], isNullable: false),
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'name'), validators: [], isNullable: false),
  ],
);

const $orderEventDtoSchema = ZtoSchema(
  typeName: 'OrderEventDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'status'), validators: [], isNullable: false),
  ],
);

const $wsMessageDtoSchema = ZtoSchema(
  typeName: 'WsMessageDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'type'), validators: [], isNullable: false),
  ],
);

void main() {
  group('Showcase — fluent API completa', () {
    // ── 1. CRUD de usuários: GET (lista) + POST (cria) ──────────────────────
    test('CRUD de usuários', () {
      final usersDoc = Api.path()
          .get((op) => op
              .summary('Listar usuários')
              .description('Retorna lista paginada de usuários.')
              .tag('Users')
              .security(['BearerAuth'])
              .query('search', ParamType.string, description: 'Filtro por nome')
              .query('page', ParamType.integer, example: 1)
              .query('limit', ParamType.integer, example: 20)
              .ok(
                listOfZtoSchema: $userResponseDtoSchema,
                description: 'Lista paginada',
                headers: const [
                  ResHeader('X-Total-Count', ParamType.integer,
                      description: 'Total de registros'),
                ],
              )
              .unauthorized(description: 'Token ausente ou inválido'))
          .post((op) => op
              .summary('Criar usuário')
              .tag('Users')
              .header('X-Request-Id', ParamType.string,
                  format: 'uuid', description: 'Chave de idempotência')
              .body($createUserDtoSchema)
              .created(
                ztoSchema: $userResponseDtoSchema,
                headers: const [
                  ResHeader('Location', ParamType.string,
                      format: 'uri', description: 'URL do novo recurso'),
                ],
              )
              .badRequest(description: 'Dados inválidos')
              .unprocessable(
                  ztoSchema: $userResponseDtoSchema, description: 'Validação ZTO')
              .conflict(description: 'E-mail já cadastrado')
              .postman('pm.test("201", () => pm.response.to.have.status(201));')
              .bruno('test("201", () => expect(res.getStatus()).to.equal(201));'))
          .build();

      final spec = _spec({'/v1/users': usersDoc});

      // GET
      final get = spec['paths']['/v1/users']['get'] as Map;
      expect(get['summary'], equals('Listar usuários'));
      expect((get['parameters'] as List).length, equals(3));
      expect(get['responses']['200']['content']['application/json']['schema']
          [r'$ref'], equals('#/components/schemas/UserResponseDtoList'));
      expect(get['responses']['200']['headers']['X-Total-Count']['schema']
          ['type'], equals('integer'));
      expect(get['responses'].containsKey('401'), isTrue);

      // POST
      final post = spec['paths']['/v1/users']['post'] as Map;
      expect(post['requestBody']['content']['application/json']['schema']
          [r'$ref'], equals('#/components/schemas/CreateUserDto'));
      expect(post['responses']['201']['headers']['Location']['schema']['format'],
          equals('uri'));
      expect(post['responses'].containsKey('400'), isTrue);
      expect(post['responses'].containsKey('422'), isTrue);
      expect(post['responses'].containsKey('409'), isTrue);

      // Componentes registrados (DTO da lista + DTO do item + body)
      final components = spec['components']['schemas'] as Map;
      expect(components.containsKey('UserResponseDto'), isTrue);
      expect(components.containsKey('UserResponseDtoList'), isTrue);
      expect(components.containsKey('CreateUserDto'), isTrue);
    });

    // ── 2. Detalhe por id: path param + 200/404/500 ─────────────────────────
    test('detalhe por id com path param', () {
      final doc = Api.path()
          .param('id', ParamType.string, description: 'ID do usuário')
          .get((op) => op
              .summary('Buscar usuário')
              .tag('Users')
              .public()
              .ok(ztoSchema: $userResponseDtoSchema)
              .notFound(description: 'Usuário não encontrado')
              .serverError())
          .delete((op) => op
              .summary('Remover usuário')
              .tag('Users')
              .public()
              .noContent()
              .notFound(description: 'Usuário não encontrado'))
          .build();

      final spec = _spec({'/v1/users/{id}': doc});
      final get = spec['paths']['/v1/users/{id}']['get'] as Map;
      expect(get['responses']['200']['content']['application/json']['schema']
          [r'$ref'], equals('#/components/schemas/UserResponseDto'));
      expect(get['responses'].containsKey('404'), isTrue);
      expect(get['responses']['500']['description'],
          equals('Internal Server Error'));

      final del = spec['paths']['/v1/users/{id}']['delete'] as Map;
      expect(del['responses']['204'].containsKey('content'), isFalse);
    });

    // ── 3. Respostas com JSON literal (resposta real) ───────────────────────
    test('respostas com json/listOfJson (schema inferido + example)', () {
      final doc = Api.path()
          .get((op) => op
              .summary('Health & métricas')
              .public()
              .response(200, json: const {
                'status': 'ok',
                'uptime': 1234,
                'healthy': true,
              }))
          .build();

      final schema = _spec({'/v1/health': doc})['paths']['/v1/health']['get']
          ['responses']['200']['content']['application/json']['schema'] as Map;
      expect(schema['type'], equals('object'));
      expect(schema['properties']['status']['type'], equals('string'));
      expect(schema['properties']['uptime']['type'], equals('integer'));
      expect(schema['properties']['healthy']['type'], equals('boolean'));
      expect(schema['example'], equals({'status': 'ok', 'uptime': 1234, 'healthy': true}));
    });

    // ── 4. Mídia: download binário + erro tipado (problem+json) ─────────────
    test('download binário e erro tipado em problem+json', () {
      final doc = Api.path()
          .get((op) => op
              .summary('Baixar fatura em PDF')
              .tag('Billing')
              .public()
              .bytes(200, contentType: 'application/pdf', description: 'PDF da fatura')
              .response(404,
                  json: const {'type': 'not_found', 'title': 'Fatura não existe'},
                  contentType: 'application/problem+json',
                  description: 'Não encontrada'))
          .build();

      final get = _spec({'/v1/invoices/{id}/pdf': doc})['paths']
          ['/v1/invoices/{id}/pdf']['get'] as Map;
      expect(get['responses']['200']['content']['application/pdf']['schema']
          ['format'], equals('binary'));
      expect(get['responses']['404']['content'].keys.single,
          equals('application/problem+json'));
    });

    // ── 5. Upload binário (request) ─────────────────────────────────────────
    test('upload binário via bytesBody', () {
      final doc = Api.path()
          .post((op) => op
              .summary('Upload de logo')
              .tag('Media')
              .public()
              .bytesBody(contentType: 'image/png')
              .created(ztoSchema: $userResponseDtoSchema))
          .build();

      final body = _spec({'/v1/media/logo': doc})['paths']['/v1/media/logo']
          ['post']['requestBody'] as Map;
      expect(body['content']['image/png']['schema']['format'], equals('binary'));
    });

    // ── 6. Stream de eventos (SSE) ──────────────────────────────────────────
    test('stream SSE de eventos de pedido', () {
      final doc = Api.path()
          .get((op) => op
              .summary('Stream de eventos do pedido')
              .tag('Orders')
              .public()
              .sse(200, ztoSchema: $orderEventDtoSchema, description: 'Eventos'))
          .build();

      final content = _spec({'/v1/orders/{id}/events': doc})['paths']
          ['/v1/orders/{id}/events']['get']['responses']['200']['content'] as Map;
      expect(content.containsKey('text/event-stream'), isTrue);
      expect(content['text/event-stream']['schema'][r'$ref'],
          equals('#/components/schemas/OrderEventDto'));
    });

    // ── 7. WebSocket (handshake 101 + x-websocket) ──────────────────────────
    test('endpoint WebSocket', () {
      final doc = Api.path()
          .get((op) => op
              .summary('Canal de pedidos em tempo real')
              .tag('Realtime')
              .public()
              .websocket(
                messageZtoSchema: $wsMessageDtoSchema,
                description: 'Upgrade para WebSocket — canal de pedidos',
              ))
          .build();

      final spec = _spec({'/v1/ws/orders': doc});
      final get = spec['paths']['/v1/ws/orders']['get'] as Map;
      expect(get['responses']['101']['description'],
          equals('Upgrade para WebSocket — canal de pedidos'));
      expect(get['x-websocket']['message'][r'$ref'],
          equals('#/components/schemas/WsMessageDto'));
      expect((spec['components']['schemas'] as Map).containsKey('WsMessageDto'),
          isTrue);
    });
  });
}

Map<String, dynamic> _spec(Map<String, PathSchema> paths) => OpenApiBuilder(
      info: const OpenApiInfo(title: 'Showcase API', version: '1.0.0'),
      pathSchemas: paths,
    ).build();
