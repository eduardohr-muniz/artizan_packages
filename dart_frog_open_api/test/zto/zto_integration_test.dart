import 'dart:io';

import 'package:test/test.dart';
import 'package:zto/zto.dart';

import '../../lib/dart_frog_open_api.dart';

// ── Schemas (mirrors what zto_generator would produce) ──────────────────────

const $createProductDtoSchema = ZtoSchema(
  typeName: 'CreateProductDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name', description: 'Product name', example: 'Widget'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZDouble(mapKey: 'price', description: 'Price in USD', example: 9.99),
      validators: [ZPositive()],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZEnum(mapKey: 'category', values: ['electronics', 'clothing', 'food']),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'description'),
      validators: [],
      isNullable: true,
    ),
  ],
);

const $productResponseDtoSchema = ZtoSchema(
  typeName: 'ProductResponseDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'id'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZDouble(mapKey: 'price'),
      validators: [],
      isNullable: false,
    ),
  ],
);

// ── Helpers ─────────────────────────────────────────────────────────────────

Directory _fakeRoutes() {
  final dir = Directory.systemTemp.createTempSync('zto_test_');
  File('${dir.path}/index.dart').writeAsStringSync(
    'import "package:dart_frog/dart_frog.dart";\n'
    'FutureOr<Response> onRequest(RequestContext c) {\n'
    '  return switch (c.request.method) {\n'
    '    HttpMethod.get => Response(),\n'
    '    HttpMethod.post => Response(),\n'
    '    _ => Response(statusCode: 405),\n'
    '  };\n'
    '}\n',
  );
  return dir;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('OpenApiBuilder with zto DTO schemas', () {
    test(r'requestBody uses $ref to components/schemas', () {
      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {
          '/': PathSchema(
            post: OperationSchema(
              requestBodySchema: OpenApiSchema.fromZto($createProductDtoSchema),
            ),
          ),
        },
      ).build();

      final post = spec['paths']['/']['post'] as Map;
      expect(post.containsKey('requestBody'), isTrue);

      final schema = post['requestBody']['content']['application/json']['schema'] as Map;
      expect(schema[r'$ref'], '#/components/schemas/CreateProductDto');
    });

    test('components/schemas contains the DTO schema with correct properties', () {
      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {
          '/': PathSchema(
            post: OperationSchema(requestBodySchema: OpenApiSchema.fromZto($createProductDtoSchema)),
          ),
        },
      ).build();

      final componentSchema = spec['components']['schemas']['CreateProductDto'] as Map;
      expect(componentSchema['type'], 'object');
      expect((componentSchema['properties'] as Map).containsKey('name'), isTrue);
      expect((componentSchema['properties'] as Map).containsKey('price'), isTrue);
    });

    test('required list excludes nullable fields from DTO', () {
      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {
          '/': PathSchema(
            post: OperationSchema(requestBodySchema: OpenApiSchema.fromZto($createProductDtoSchema)),
          ),
        },
      ).build();

      final componentSchema = spec['components']['schemas']['CreateProductDto'] as Map;
      final required = componentSchema['required'] as List;
      expect(required, contains('name'));
      expect(required, isNot(contains('description')));
    });

    test('ZEnum field has enum values in schema', () {
      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {
          '/': PathSchema(
            post: OperationSchema(requestBodySchema: OpenApiSchema.fromZto($createProductDtoSchema)),
          ),
        },
      ).build();

      final componentSchema = spec['components']['schemas']['CreateProductDto'] as Map;
      final props = componentSchema['properties'] as Map;
      expect(props['category']['enum'], ['electronics', 'clothing', 'food']);
    });

    test(r'response uses $ref to components/schemas', () {
      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {
          '/': PathSchema(
            get: OperationSchema(
              responseSchemas: {200: OpenApiSchema.fromZto($productResponseDtoSchema)},
            ),
          ),
        },
      ).build();

      final get = spec['paths']['/']['get'] as Map;
      final responses = get['responses'] as Map;
      expect(responses.containsKey('200'), isTrue);

      final schema = responses['200']['content']['application/json']['schema'] as Map;
      expect(schema[r'$ref'], '#/components/schemas/ProductResponseDto');
    });

    test('returns(buildExamples) serializes DTO examples to OpenAPI examples', () {
      final path = Api.path()
          .get(
            (op) => op.returns(
              400,
              schema: $productResponseDtoSchema,
              description: 'Validation error',
              buildResponse: (ctx) {
                expect(ctx.status, 400);
                return const [
                  OpenApiResponseExample(
                    name: 'missing_name',
                    summary: 'Missing name',
                    value: {
                      'error': {'code': 'invalid_request', 'message': 'name is required'}
                    },
                  ),
                  {
                    'error': {'code': 'invalid_request', 'message': 'price must be > 0'}
                  },
                ];
              },
            ),
          )
          .build();

      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {'/': path},
      ).build();

      final get = spec['paths']['/']['get'] as Map;
      final responses = get['responses'] as Map;
      final content = responses['400']['content']['application/json'] as Map;
      final examples = content['examples'] as Map;
      expect(examples.containsKey('missing_name'), isTrue);
      expect(examples.containsKey('example_1'), isTrue);
      expect(examples['missing_name']['value']['error']['code'], 'invalid_request');
    });

    test('returns(buildExamples) supports ctx.add().add() fluent style', () {
      final path = Api.path()
          .get(
            (op) => op.returns(
              400,
              schema: $productResponseDtoSchema,
              description: 'Validation error',
              buildResponse: (ctx) {
                ctx.add(
                  response: const {
                    'error': {'code': 'missing_q', 'message': 'q is required'}
                  },
                  name: 'missing_q',
                  summary: 'Missing query',
                ).add(
                  response: const {
                    'error': {'code': 'q_too_short', 'message': 'q too short'}
                  },
                  name: 'q_too_short',
                );
                return null;
              },
            ),
          )
          .build();

      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {'/': path},
      ).build();

      final get = spec['paths']['/']['get'] as Map;
      final responses = get['responses'] as Map;
      final content = responses['400']['content']['application/json'] as Map;
      final examples = content['examples'] as Map;
      expect(examples.containsKey('missing_q'), isTrue);
      expect(examples.containsKey('q_too_short'), isTrue);
      expect(examples['missing_q']['summary'], 'Missing query');
    });

    test('components/schemas contains response DTO schema', () {
      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {
          '/': PathSchema(
            get: OperationSchema(
              responseSchemas: {200: OpenApiSchema.fromZto($productResponseDtoSchema)},
            ),
          ),
        },
      ).build();

      final componentSchema = spec['components']['schemas']['ProductResponseDto'] as Map;
      expect(componentSchema['type'], 'object');
      expect((componentSchema['properties'] as Map).containsKey('id'), isTrue);
    });

    test('OperationSchema supports both requestBodySchema and responseSchemas', () {
      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {
          '/': PathSchema(
            post: OperationSchema(
              requestBodySchema: OpenApiSchema.fromZto($createProductDtoSchema),
              responseSchemas: {201: OpenApiSchema.fromZto($productResponseDtoSchema)},
            ),
          ),
        },
      ).build();

      final post = spec['paths']['/']['post'] as Map;
      expect(post.containsKey('requestBody'), isTrue);
      expect((post['responses'] as Map).containsKey('201'), isTrue);

      final schemas = spec['components']['schemas'] as Map;
      expect(schemas.containsKey('CreateProductDto'), isTrue);
      expect(schemas.containsKey('ProductResponseDto'), isTrue);
    });

    test('multiple DTOs across paths all appear in components/schemas', () {
      final spec = OpenApiBuilder(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
        pathSchemas: {
          '/': PathSchema(
            post: OperationSchema(
              requestBodySchema: OpenApiSchema.fromZto($createProductDtoSchema),
              responseSchemas: {201: OpenApiSchema.fromZto($productResponseDtoSchema)},
            ),
          ),
        },
      ).build();

      final schemas = spec['components']['schemas'] as Map;
      expect(schemas.containsKey('CreateProductDto'), isTrue);
      expect(schemas.containsKey('ProductResponseDto'), isTrue);
    });
  });

  // ── Gap 10a — ZBool, ZFile, ZMetaData, ZList, ZListOf coverage ─────────────

  group('ZBool field', () {
    test('generates type: boolean', () {
      const schema = ZtoSchema(
        typeName: 'BoolDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZBool(mapKey: 'active', description: 'Active flag', example: true),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['active']['type'], 'boolean');
      expect(props['active']['description'], 'Active flag');
      expect(props['active']['example'], true);
    });

    test('nullable ZBool generates oneOf', () {
      const schema = ZtoSchema(
        typeName: 'NullableBoolDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZBool(mapKey: 'flag'),
            validators: [],
            isNullable: true,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      final oneOf = props['flag']['oneOf'] as List;
      expect(oneOf, hasLength(2));
      expect(oneOf[0]['type'], 'boolean');
      expect(oneOf[1]['type'], 'null');
    });
  });

  group('ZFile field', () {
    test('generates type: string, format: binary', () {
      const schema = ZtoSchema(
        typeName: 'FileDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZFile(mapKey: 'avatar', description: 'Profile image'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['avatar']['type'], 'string');
      expect(props['avatar']['format'], 'binary');
      expect(props['avatar']['description'], 'Profile image');
    });
  });

  group('ZMetaData field', () {
    test('generates type: object', () {
      const schema = ZtoSchema(
        typeName: 'MetaDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZMetaData(mapKey: 'meta', description: 'User metadata'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['meta']['type'], 'object');
      expect(props['meta']['description'], 'User metadata');
    });
  });

  group('ZList field', () {
    test('ZList with ZString itemType generates type: array, items: {type: string}', () {
      const schema = ZtoSchema(
        typeName: 'ListStringDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZList(itemType: ZString, mapKey: 'tags'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['tags']['type'], 'array');
      expect(props['tags']['minItems'], 1);
      expect(props['tags']['items']['type'], 'string');
    });

    test('ZList with ZInt itemType generates type: array, items: {type: integer}', () {
      const schema = ZtoSchema(
        typeName: 'ListIntDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZList(itemType: ZInt, mapKey: 'scores'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['scores']['type'], 'array');
      expect(props['scores']['items']['type'], 'integer');
    });

    test('ZList with ZBool itemType generates type: array, items: {type: boolean}', () {
      const schema = ZtoSchema(
        typeName: 'ListBoolDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZList(itemType: ZBool, mapKey: 'flags'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['flags']['type'], 'array');
      expect(props['flags']['items']['type'], 'boolean');
    });

    test('ZList with ZDate itemType generates type: array, items with format: date-time', () {
      const schema = ZtoSchema(
        typeName: 'ListDateDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZList(itemType: ZDate, mapKey: 'dates'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['dates']['type'], 'array');
      expect(props['dates']['items']['type'], 'string');
      expect(props['dates']['items']['format'], 'date-time');
    });
  });

  group('ZListOf field', () {
    test('ZListOf without dtoSchema generates type: array with object items', () {
      const schema = ZtoSchema(
        typeName: 'ListOfDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZListOf(mapKey: 'items'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['items']['type'], 'array');
      expect(props['items']['minItems'], 1);
      expect(props['items']['items']['type'], 'object');
    });

    test(r'ZListOf with dtoSchema generates $ref to nested schema', () {
      const nestedSchema = ZtoSchema(
        typeName: 'NestedDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'name'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      const schema = ZtoSchema(
        typeName: 'ListOfNestedDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZListOf(dtoSchema: nestedSchema, mapKey: 'nested'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final props = result['properties'] as Map;
      expect(props['nested']['type'], 'array');
      expect(props['nested']['minItems'], 1);
      final items = props['nested']['items'] as Map;
      expect(items[r'$ref'], '#/components/schemas/NestedDto');
    });
  });

  // ── Gap 2 — Validators reflected in OpenAPI schema ──────────────────────────

  group('Validators reflected in OpenAPI schema', () {
    test('ZMinLength → minLength', () {
      const schema = ZtoSchema(
        typeName: 'MinLengthDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'name'),
            validators: [ZMinLength(3)],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['name']['minLength'], 3);
    });

    test('ZMaxLength → maxLength', () {
      const schema = ZtoSchema(
        typeName: 'MaxLengthDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'bio'),
            validators: [ZMaxLength(500)],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['bio']['maxLength'], 500);
    });

    test('ZLength → minLength AND maxLength igual', () {
      const schema = ZtoSchema(
        typeName: 'LengthDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'code'),
            validators: [ZLength(4)],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['code']['minLength'], 4);
      expect(result['properties']['code']['maxLength'], 4);
    });

    test('ZMin → minimum', () {
      const schema = ZtoSchema(
        typeName: 'MinDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZInt(mapKey: 'age'),
            validators: [ZMin(18)],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['age']['minimum'], 18);
    });

    test('ZMax → maximum', () {
      const schema = ZtoSchema(
        typeName: 'MaxDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZInt(mapKey: 'age'),
            validators: [ZMax(120)],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['age']['maximum'], 120);
    });

    test('ZMultipleOf → multipleOf', () {
      const schema = ZtoSchema(
        typeName: 'MultipleOfDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZInt(mapKey: 'qty'),
            validators: [ZMultipleOf(5)],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['qty']['multipleOf'], 5);
    });

    test('ZPattern → pattern', () {
      const schema = ZtoSchema(
        typeName: 'PatternDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'code'),
            validators: [ZPattern(r'^\d{4}$')],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['code']['pattern'], r'^\d{4}$');
    });

    test('ZEmail → format: email', () {
      const schema = ZtoSchema(
        typeName: 'EmailDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'email'),
            validators: [ZEmail()],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['email']['format'], 'email');
    });

    test('ZUuid → format: uuid', () {
      const schema = ZtoSchema(
        typeName: 'UuidDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'id'),
            validators: [ZUuid()],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['id']['format'], 'uuid');
    });

    test('ZUrl → format: uri', () {
      const schema = ZtoSchema(
        typeName: 'UrlDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'website'),
            validators: [ZUrl()],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['website']['format'], 'uri');
    });

    test('ZPositive → exclusiveMinimum: 0', () {
      const schema = ZtoSchema(
        typeName: 'PositiveDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZDouble(mapKey: 'price'),
            validators: [ZPositive()],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['price']['exclusiveMinimum'], 0);
    });

    test('ZNonNegative → minimum: 0', () {
      const schema = ZtoSchema(
        typeName: 'NonNegativeDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZInt(mapKey: 'count'),
            validators: [ZNonNegative()],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['count']['minimum'], 0);
    });

    test('ZNegative → exclusiveMaximum: 0', () {
      const schema = ZtoSchema(
        typeName: 'NegativeDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZDouble(mapKey: 'temp'),
            validators: [ZNegative()],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['temp']['exclusiveMaximum'], 0);
    });

    test('ZNonPositive → maximum: 0', () {
      const schema = ZtoSchema(
        typeName: 'NonPositiveDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZInt(mapKey: 'delta'),
            validators: [ZNonPositive()],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['delta']['maximum'], 0);
    });

    test('validators combined (ZMin + ZMax)', () {
      const schema = ZtoSchema(
        typeName: 'CombinedDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZInt(mapKey: 'age'),
            validators: [ZMin(18), ZMax(120)],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['age']['minimum'], 18);
      expect(result['properties']['age']['maximum'], 120);
    });

    test('validators on nullable field appear inside oneOf', () {
      const schema = ZtoSchema(
        typeName: 'NullableValidatedDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'name'),
            validators: [ZMinLength(2), ZMaxLength(100)],
            isNullable: true,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final oneOf = result['properties']['name']['oneOf'] as List;
      expect(oneOf[0]['minLength'], 2);
      expect(oneOf[0]['maxLength'], 100);
      expect(oneOf[1]['type'], 'null');
    });
  });

  // ── Gap 8 — Field-level deprecated ──────────────────────────────────────────

  group('Field-level deprecated', () {
    test('deprecated: true field gets deprecated: true in schema property', () {
      const schema = ZtoSchema(
        typeName: 'DeprecatedFieldDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'legacyField', deprecated: true),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['legacyField']['deprecated'], isTrue);
    });

    test('field without deprecated does not get deprecated key', () {
      const schema = ZtoSchema(
        typeName: 'NonDeprecatedDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'normalField'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      expect(result['properties']['normalField'].containsKey('deprecated'), isFalse);
    });

    test('deprecated nullable field puts deprecated inside oneOf', () {
      const schema = ZtoSchema(
        typeName: 'NullableDeprecatedDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'oldField', deprecated: true),
            validators: [],
            isNullable: true,
          ),
        ],
      );
      final result = DtoToOpenApi.convert(schema);
      final oneOf = result['properties']['oldField']['oneOf'] as List;
      expect(oneOf[0]['deprecated'], isTrue);
    });
  });

  // ── Gap 9 — Circular reference guard ────────────────────────────────────────

  group('Circular reference protection', () {
    test('DtoToOpenApi.convert does not stack overflow on circular DTOs', () {
      // Two schemas that reference each other: A -> B via ZObj, B -> A via ZObj
      const schemaA = ZtoSchema(
        typeName: 'CircularA',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'name'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      const schemaB = ZtoSchema(
        typeName: 'CircularB',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZObj(dtoSchema: schemaA, mapKey: 'a'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      // Register both so getSchema works
      Zto.registerSchema('CircularA', schemaA);
      Zto.registerSchema('CircularB', schemaB);
      // This should not stack overflow
      expect(() => DtoToOpenApi.convert(schemaA), returnsNormally);
      expect(() => DtoToOpenApi.convert(schemaB), returnsNormally);
    });

    test('OpenApiBuilder._collectSchemas does not loop on mutually referencing DTOs', () {
      // A references B via ZObj, B references A via ZObj — would loop without seenTypeNames guard
      const schemaA = ZtoSchema(
        typeName: 'MutualA',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'value'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      const schemaB = ZtoSchema(
        typeName: 'MutualB',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZObj(dtoSchema: schemaA, mapKey: 'a'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      Zto.registerSchema(Object, schemaA); // use Object as dummy key
      // Build spec — must not hang or throw StackOverflow
      expect(
        () => OpenApiBuilder(
          info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
          pathSchemas: {
            '/': PathSchema(
              get: OperationSchema(
                responseSchemas: {200: OpenApiSchema.fromZto(schemaB)},
              ),
            ),
          },
        ).build(),
        returnsNormally,
      );
    });
  });
}
