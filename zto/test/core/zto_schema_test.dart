import 'package:test/test.dart';
import 'package:zto/zto.dart';

void main() {
  group('ZtoSchema', () {
    test('holds typeName', () {
      const schema = ZtoSchema(typeName: 'MyDto', descriptors: []);
      expect(schema.typeName, 'MyDto');
    });

    test('holds descriptors list', () {
      const descriptor = FieldDescriptor(
        fieldAnnotation: ZString(mapKey: 'name'),
        validators: [],
        isNullable: false,
      );
      const schema = ZtoSchema(typeName: 'MyDto', descriptors: [descriptor]);
      expect(schema.descriptors, hasLength(1));
      expect(schema.descriptors.first.key, 'name');
    });

    test('is const-constructable with empty descriptors', () {
      const schema = ZtoSchema(typeName: 'EmptyDto', descriptors: []);
      expect(schema.typeName, 'EmptyDto');
      expect(schema.descriptors, isEmpty);
    });

    test('is const-constructable with multiple descriptors', () {
      const schema = ZtoSchema(
        typeName: 'RichDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'name'),
            validators: [ZMinLength(2)],
            isNullable: false,
          ),
          FieldDescriptor(
            fieldAnnotation: ZInt(mapKey: 'age'),
            validators: [ZMin(18)],
            isNullable: false,
          ),
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'email'),
            validators: [ZEmail()],
            isNullable: true,
          ),
        ],
      );
      expect(schema.typeName, 'RichDto');
      expect(schema.descriptors, hasLength(3));
    });

    test('ZtoSchema can be used in annotation position (dtoSchema param)', () {
      const nestedSchema = ZtoSchema(
        typeName: 'AddressDto',
        descriptors: [
          FieldDescriptor(
            fieldAnnotation: ZString(mapKey: 'street'),
            validators: [],
            isNullable: false,
          ),
        ],
      );
      const listOf = ZListOf(mapKey: 'addresses', dtoSchema: nestedSchema);
      expect(listOf.dtoSchema!.typeName, 'AddressDto');
    });
  });

  group('ZtoSchema.parse()', () {
    const schema = ZtoSchema(
      typeName: 'UserDto',
      descriptors: [
        FieldDescriptor(
          fieldAnnotation: ZString(mapKey: 'name'),
          validators: [ZMinLength(2)],
          isNullable: false,
        ),
        FieldDescriptor(
          fieldAnnotation: ZInt(mapKey: 'age'),
          validators: [ZMin(18)],
          isNullable: false,
        ),
      ],
    );

    test('parses and validates map with factory', () {
      final dto = schema.parse(
        {'name': 'Alice', 'age': 25},
        (map) => {'name': map['name'], 'age': map['age']},
      );
      expect(dto['name'], 'Alice');
      expect(dto['age'], 25);
    });

    test('throws ZtoException on validation failure', () {
      expect(
        () => schema.parse(
          {'name': 'A', 'age': 15},
          (map) => {'name': map['name'], 'age': map['age']},
        ),
        throwsA(isA<ZtoException>()),
      );
    });

    test('works with map results', () {
      final result = schema.parse(
        {'name': 'Bob', 'age': 30},
        (map) => Map<String, dynamic>.from(map),
      );
      expect(result['name'], 'Bob');
      expect(result['age'], 30);
    });
  });

  group('ZtoSchema.parseList()', () {
    const schema = ZtoSchema(
      typeName: 'UserDto',
      descriptors: [
        FieldDescriptor(
          fieldAnnotation: ZString(mapKey: 'name'),
          validators: [ZMinLength(2)],
          isNullable: false,
        ),
      ],
    );

    test('parses and validates all maps', () {
      final results = schema.parseList(
        [
          {'name': 'Alice'},
          {'name': 'Bob'},
        ],
        (map) => map['name'] as String,
      );
      expect(results, ['Alice', 'Bob']);
    });

    test('throws ZtoException if any item is invalid', () {
      expect(
        () => schema.parseList(
          [
            {'name': 'Alice'},
            {'name': 'A'}, // too short
          ],
          (map) => map['name'] as String,
        ),
        throwsA(isA<ZtoException>()),
      );
    });

    test('returns empty list for empty input', () {
      final results = schema.parseList(
        [],
        (map) => map['name'] as String,
      );
      expect(results, isEmpty);
    });
  });
}
