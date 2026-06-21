import 'dart:convert';

import 'package:test/test.dart';
import 'package:zto/zto.dart';

import '../../lib/dart_frog_open_api.dart';

// ── Schemas ─────────────────────────────────────────────────────────────────

const $createUserDtoSchema = ZtoSchema(
  typeName: 'CreateUserDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'name'), validators: [], isNullable: false),
  ],
);

const $userResponseDtoSchema = ZtoSchema(
  typeName: 'UserResponseDto',
  descriptors: [
    FieldDescriptor(fieldAnnotation: ZString(mapKey: 'id'), validators: [], isNullable: false),
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

/// A reasonably complete spec covering every output shape: $ref bodies, list
/// wrappers, inline json, binary, SSE, websocket, protected + public routes.
Map<String, dynamic> _fullSpec() => OpenApiBuilder(
      info: const OpenApiInfo(
        title: 'Paipfood API',
        version: '1.0.0',
        description: 'Documento completo de teste.',
        servers: ['https://api.paipfood.com'],
      ),
      pathSchemas: {
        '/v1/users': Api.path()
            .get((op) => op
                .summary('Listar')
                .security(['BearerAuth'])
                .ok(
                  listOfZtoSchema: $userResponseDtoSchema,
                  headers: const [
                    ResHeader('X-Total-Count', ParamType.integer,
                        description: 'Total'),
                  ],
                ))
            .post((op) => op
                .summary('Criar')
                .security(['BearerAuth'])
                .body($createUserDtoSchema)
                .created(
                  ztoSchema: $userResponseDtoSchema,
                  headers: const [
                    ResHeader('Location', ParamType.string, format: 'uri'),
                  ],
                )
                .unprocessable(
                    ztoSchema: $userResponseDtoSchema,
                    description: 'Validação'))
            .build(),
        '/v1/users/{id}': Api.path()
            .param('id', ParamType.string)
            .get((op) => op
                .summary('Buscar')
                .public()
                .ok(ztoSchema: $userResponseDtoSchema)
                .notFound(description: 'Não encontrado')
                .serverError())
            .delete((op) => op.summary('Remover').public().noContent())
            .build(),
        '/v1/health': Api.path()
            .get((op) => op.summary('Health').public().response(200,
                json: const {'status': 'ok', 'uptime': 12}))
            .build(),
        '/v1/invoices/{id}/pdf': Api.path()
            .get((op) => op
                .summary('PDF')
                .public()
                .bytes(200, contentType: 'application/pdf')
                .response(404,
                    json: const {'type': 'not_found'},
                    contentType: 'application/problem+json'))
            .build(),
        '/v1/orders/{id}/events': Api.path()
            .get((op) => op
                .summary('SSE')
                .public()
                .sse(200, ztoSchema: $orderEventDtoSchema))
            .build(),
        '/v1/ws/orders': Api.path()
            .get((op) => op.summary('WS').public().websocket(
                  messageZtoSchema: $wsMessageDtoSchema,
                  description: 'Canal',
                ))
            .build(),
      },
    ).build();

/// Walks the whole document and yields every `$ref` string value found.
Iterable<String> _allRefs(Object? node) sync* {
  if (node is Map) {
    for (final entry in node.entries) {
      if (entry.key == r'$ref' && entry.value is String) {
        yield entry.value as String;
      } else {
        yield* _allRefs(entry.value);
      }
    }
  } else if (node is List) {
    for (final item in node) {
      yield* _allRefs(item);
    }
  }
}

void main() {
  group('Documento OpenAPI / Swagger completo', () {
    test('top-level tem openapi, info, paths e components', () {
      final spec = _fullSpec();

      expect(spec['openapi'], equals('3.0.0'));
      expect(spec['info']['title'], equals('Paipfood API'));
      expect(spec['info']['version'], equals('1.0.0'));
      expect(spec['servers'], equals([{'url': 'https://api.paipfood.com'}]));
      expect((spec['paths'] as Map).length, equals(6));
      expect(spec['components'], isA<Map>());
    });

    test('rotas protegidas geram securityScheme BearerAuth', () {
      final spec = _fullSpec();
      final schemes = spec['components']['securitySchemes'] as Map;
      expect(schemes.containsKey('BearerAuth'), isTrue);
      expect(schemes['BearerAuth']['type'], equals('http'));
      expect(schemes['BearerAuth']['scheme'], equals('bearer'));

      // A operação protegida referencia o scheme.
      final post = spec['paths']['/v1/users']['post'] as Map;
      expect(post['security'], equals([{'BearerAuth': <String>[]}]));
    });

    test('todo \$ref do documento resolve para um componente existente', () {
      final spec = _fullSpec();
      final schemas = (spec['components']['schemas'] as Map).keys.toSet();

      final refs = _allRefs(spec).toSet();
      expect(refs, isNotEmpty, reason: 'esperava ao menos um \$ref no doc');

      for (final ref in refs) {
        expect(ref, startsWith('#/components/schemas/'),
            reason: 'ref inesperado: $ref');
        final name = ref.split('/').last;
        expect(schemas.contains(name), isTrue,
            reason: '\$ref pendurado: $ref não existe em components/schemas');
      }
    });

    test('toda response object tem description (exigência OpenAPI)', () {
      final spec = _fullSpec();
      final paths = spec['paths'] as Map;
      for (final pathItem in paths.values) {
        for (final entry in (pathItem as Map).entries) {
          if (entry.key == 'parameters') continue;
          final responses = (entry.value as Map)['responses'] as Map;
          for (final res in responses.values) {
            expect((res as Map).containsKey('description'), isTrue,
                reason: 'response sem description em $entry');
          }
        }
      }
    });

    test('o documento é serializável como arquivo JSON (swagger.json)', () {
      final spec = _fullSpec();

      // jsonEncode falha se houver qualquer valor não serializável.
      final jsonString = jsonEncode(spec);
      expect(jsonString, contains('"openapi":"3.0.0"'));

      // Round-trip preserva a estrutura.
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['paths'].keys.toSet(),
          equals((spec['paths'] as Map).keys.toSet()));
      expect(decoded['components']['schemas'].keys.toSet(),
          equals((spec['components']['schemas'] as Map).keys.toSet()));
    });

    test('todos os DTOs referenciados estão registrados (lista + item + body)', () {
      final spec = _fullSpec();
      final schemas = (spec['components']['schemas'] as Map).keys.toSet();
      expect(
        schemas,
        containsAll(<String>{
          'CreateUserDto',
          'UserResponseDto',
          'UserResponseDtoList',
          'OrderEventDto',
          'WsMessageDto',
        }),
      );
    });
  });
}
