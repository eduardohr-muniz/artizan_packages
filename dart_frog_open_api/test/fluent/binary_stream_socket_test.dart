import 'package:test/test.dart';
import 'package:zto/zto.dart';

import 'package:dart_frog_open_api/dart_frog_open_api.dart';

const $wsMessageDtoSchema = ZtoSchema(
  typeName: 'WsMessageDto',
  descriptors: [
    FieldDescriptor(
        fieldAnnotation: ZString(mapKey: 'type'),
        validators: [],
        isNullable: false),
  ],
);

const $orderEventDtoSchema = ZtoSchema(
  typeName: 'OrderEventDto',
  descriptors: [
    FieldDescriptor(
        fieldAnnotation: ZString(mapKey: 'status'),
        validators: [],
        isNullable: false),
  ],
);

Map<String, dynamic> _specFor(PathSchema path) => OpenApiBuilder(
      info: const OpenApiInfo(title: 'Test'),
      pathSchemas: {'/v1/stream': path},
    ).build();

Map<String, dynamic> _op(Map<String, dynamic> spec, String method) =>
    (spec['paths']['/v1/stream'][method] as Map).cast<String, dynamic>();

void main() {
  group('Bytes / Stream / Socket → serialização OpenAPI', () {
    // ── RESPONSE ──────────────────────────────────────────────────────────

    test('response.bytes() gera octet-stream com schema binário', () {
      final path = Api.path().get((op) => op.public().bytes(200)).build();

      final media =
          _op(_specFor(path), 'get')['responses']['200']['content'] as Map;
      expect(media.containsKey('application/octet-stream'), isTrue);
      final schema = media['application/octet-stream']['schema'] as Map;
      expect(schema['type'], equals('string'));
      expect(schema['format'], equals('binary'));
    });

    test('response.bytes(mime) respeita o content-type custom', () {
      final path = Api.path()
          .get((op) => op.public().bytes(200, contentType: 'application/pdf'))
          .build();

      final content =
          _op(_specFor(path), 'get')['responses']['200']['content'] as Map;
      expect(content.keys.single, equals('application/pdf'));
    });

    test('response.sse(ztoSchema) gera text/event-stream com \$ref do evento',
        () {
      final path = Api.path()
          .get((op) => op.public().sse(200, ztoSchema: $orderEventDtoSchema))
          .build();

      final spec = _specFor(path);
      final content = _op(spec, 'get')['responses']['200']['content'] as Map;
      expect(content.containsKey('text/event-stream'), isTrue);
      expect(content['text/event-stream']['schema'][r'$ref'],
          equals('#/components/schemas/OrderEventDto'));
      // Evento tipado é registrado como componente.
      expect(
          (spec['components']['schemas'] as Map).containsKey('OrderEventDto'),
          isTrue);
    });

    test('response.sse() sem schema emite content-type sem schema', () {
      final path = Api.path().get((op) => op.public().sse(200)).build();

      final content =
          _op(_specFor(path), 'get')['responses']['200']['content'] as Map;
      expect(content.containsKey('text/event-stream'), isTrue);
      expect(
          (content['text/event-stream'] as Map).containsKey('schema'), isFalse);
    });

    // ── REQUEST ───────────────────────────────────────────────────────────

    test('bytesBody() gera requestBody binário', () {
      final path = Api.path()
          .post((op) =>
              op.public().bytesBody(contentType: 'image/png').response(200))
          .build();

      final body = _op(_specFor(path), 'post')['requestBody'] as Map;
      final schema = body['content']['image/png']['schema'] as Map;
      expect(schema['type'], equals('string'));
      expect(schema['format'], equals('binary'));
    });

    test('streamBody(ztoSchema) gera ndjson com \$ref e registra componente',
        () {
      final path = Api.path()
          .post((op) => op
              .public()
              .streamBody(ztoSchema: $orderEventDtoSchema)
              .response(200))
          .build();

      final spec = _specFor(path);
      final body = _op(spec, 'post')['requestBody'] as Map;
      final content = body['content'] as Map;
      expect(content.containsKey('application/x-ndjson'), isTrue);
      expect(content['application/x-ndjson']['schema'][r'$ref'],
          equals('#/components/schemas/OrderEventDto'));
      expect(
          (spec['components']['schemas'] as Map).containsKey('OrderEventDto'),
          isTrue);
    });

    // ── WEBSOCKET ─────────────────────────────────────────────────────────

    test('websocket() gera 101 + x-websocket e registra schema de mensagem',
        () {
      final path = Api.path()
          .get((op) => op.public().websocket(
                messageZtoSchema: $wsMessageDtoSchema,
                description: 'Canal de pedidos em tempo real',
              ))
          .build();

      final spec = _specFor(path);
      final get = _op(spec, 'get');

      final res101 = get['responses']['101'] as Map;
      expect(res101['description'], equals('Canal de pedidos em tempo real'));
      expect(res101.containsKey('content'), isFalse);

      final ws = get['x-websocket'] as Map;
      expect(
          ws['message'][r'$ref'], equals('#/components/schemas/WsMessageDto'));

      expect((spec['components']['schemas'] as Map).containsKey('WsMessageDto'),
          isTrue);
    });

    test('websocket() sem schema usa descrição padrão do 101', () {
      final path = Api.path().get((op) => op.public().websocket()).build();

      final res101 = _op(_specFor(path), 'get')['responses']['101'] as Map;
      expect(res101['description'], equals('Switching Protocols'));
    });
  });
}
