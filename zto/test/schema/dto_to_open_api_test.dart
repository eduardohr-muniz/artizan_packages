import 'package:test/test.dart';
import 'package:zto/zto.dart';

// ── Schemas (mirrors what zto_generator would produce) ──────────────────────

const $fullUserDtoSchema = ZtoSchema(
  typeName: 'FullUserDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name', description: 'Full name', example: 'Alice'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZInt(mapKey: 'age', description: 'Age in years', example: 25),
      validators: [ZMin(18)],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZDouble(mapKey: 'score', description: 'Score'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZBool(mapKey: 'active', description: 'Is active'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZDate(mapKey: 'createdAt', description: 'Created at'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZFile(mapKey: 'avatar', description: 'Profile picture'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZEnum(mapKey: 'role', values: ['admin', 'viewer'], description: 'User role'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'email'),
      validators: [],
      isNullable: true,
    ),
    FieldDescriptor(
      fieldAnnotation: ZList(mapKey: 'tags', itemType: ZString, description: 'Tags'),
      validators: [],
      isNullable: false,
    ),
  ],
);

const $minimalDtoSchema = ZtoSchema(
  typeName: 'MinimalDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'title'),
      validators: [],
      isNullable: false,
    ),
  ],
);

const $lineItemDtoSchema = ZtoSchema(
  typeName: 'LineItemDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'sku', description: 'SKU'),
      validators: [],
      isNullable: false,
    ),
  ],
);

const $orderWithLinesDtoSchema = ZtoSchema(
  typeName: 'OrderWithLinesDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZListOf(
        mapKey: 'lines',
        dtoSchema: $lineItemDtoSchema,
        description: 'Itens (prod + impostos)',
      ),
      validators: [],
      isNullable: false,
    ),
  ],
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('DtoToOpenApi.convert', () {
    group('root schema structure', () {
      test('returns type: object', () {
        final schema = DtoToOpenApi.convert($minimalDtoSchema);
        expect(schema['type'], 'object');
      });

      test('has properties map', () {
        final schema = DtoToOpenApi.convert($minimalDtoSchema);
        expect(schema['properties'], isA<Map>());
      });

      test('required list contains non-nullable fields', () {
        final schema = DtoToOpenApi.convert($fullUserDtoSchema);
        final required = schema['required'] as List;
        expect(required, contains('name'));
        expect(required, contains('age'));
        expect(required, contains('role'));
      });

      test('nullable field is NOT in required list', () {
        final schema = DtoToOpenApi.convert($fullUserDtoSchema);
        final required = schema['required'] as List;
        expect(required, isNot(contains('email')));
      });
    });

    group('type mapping', () {
      late Map<String, dynamic> props;

      setUpAll(() {
        props = (DtoToOpenApi.convert($fullUserDtoSchema)['properties'] as Map).cast();
      });

      test('ZString -> type: string', () {
        expect(props['name']['type'], 'string');
      });

      test('ZInt -> type: integer', () {
        expect(props['age']['type'], 'integer');
      });

      test('ZDouble -> type: number', () {
        expect(props['score']['type'], 'number');
      });

      test('ZBool -> type: boolean', () {
        expect(props['active']['type'], 'boolean');
      });

      test('ZDate -> type: string, format: date-time', () {
        expect(props['createdAt']['type'], 'string');
        expect(props['createdAt']['format'], 'date-time');
      });

      test('ZFile -> type: string, format: binary', () {
        expect(props['avatar']['type'], 'string');
        expect(props['avatar']['format'], 'binary');
      });

      test('ZEnum -> type: string with enum values', () {
        expect(props['role']['type'], 'string');
        expect(props['role']['enum'], ['admin', 'viewer']);
      });

      test('ZList -> type: array', () {
        expect(props['tags']['type'], 'array');
        expect(props['tags']['items'], isA<Map>());
      });
    });

    group('ZListOf nested DTO + minItems', () {
      test('ZListOf(dtoSchema: …) emits array with \$ref items and minItems: 1', () {
        final schema = DtoToOpenApi.convert($orderWithLinesDtoSchema);
        final props = (schema['properties'] as Map).cast<String, dynamic>();
        final lines = props['lines'] as Map<String, dynamic>;
        expect(lines['type'], 'array');
        expect(lines['minItems'], 1);
        expect(lines['description'], 'Itens (prod + impostos)');
        final items = lines['items'] as Map<String, dynamic>;
        expect(items[r'$ref'], '#/components/schemas/LineItemDto');
      });

      test('nullable ZListOf has no minItems on the array branch', () {
        const nullableLines = ZtoSchema(
          typeName: 'OrderNullableLinesDto',
          descriptors: [
            FieldDescriptor(
              fieldAnnotation: ZListOf(
                mapKey: 'lines',
                dtoSchema: $lineItemDtoSchema,
              ),
              validators: [],
              isNullable: true,
            ),
          ],
        );
        final schema = DtoToOpenApi.convert(nullableLines);
        final props = (schema['properties'] as Map).cast<String, dynamic>();
        final lines = props['lines'] as Map<String, dynamic>;
        expect(lines.containsKey('oneOf'), isTrue);
        final oneOf = lines['oneOf'] as List<dynamic>;
        final arrayBranch = oneOf.cast<Map<String, dynamic>>().firstWhere(
              (m) => m['type'] == 'array',
            );
        expect(arrayBranch.containsKey('minItems'), isFalse);
      });
    });

    group('nullable fields', () {
      test('nullable field uses oneOf with null type', () {
        final props = (DtoToOpenApi.convert($fullUserDtoSchema)['properties'] as Map).cast<String, dynamic>();
        final email = props['email'] as Map;
        expect(email.containsKey('oneOf'), isTrue);
        final oneOf = email['oneOf'] as List;
        expect(oneOf.any((e) => e['type'] == 'null'), isTrue);
        expect(oneOf.any((e) => e['type'] == 'string'), isTrue);
      });
    });

    group('description and example', () {
      test('description is included in property when present', () {
        final props = (DtoToOpenApi.convert($fullUserDtoSchema)['properties'] as Map).cast<String, dynamic>();
        expect(props['name']['description'], 'Full name');
      });

      test('example is included in property when present', () {
        final props = (DtoToOpenApi.convert($fullUserDtoSchema)['properties'] as Map).cast<String, dynamic>();
        expect(props['name']['example'], 'Alice');
      });

      test('description is absent when not provided', () {
        final props = (DtoToOpenApi.convert($minimalDtoSchema)['properties'] as Map).cast<String, dynamic>();
        expect(props['title'].containsKey('description'), isFalse);
      });
    });
  });
}
