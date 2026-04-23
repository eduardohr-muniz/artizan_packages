import 'package:test/test.dart';
import 'package:zto/zto.dart';

// ── Schema (mirrors what zto_generator would produce) ───────────────────────

const $createUserDtoSchema = ZtoSchema(
  typeName: 'CreateUserDto',
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

// ── Test DTO ─────────────────────────────────────────────────────────────────

@Dto(description: 'Create user')
class CreateUserDto with ZtoDto<CreateUserDto> {
  final String name;
  final int age;
  final String? email;

  const CreateUserDto({required this.name, required this.age, this.email});

  factory CreateUserDto.fromMap(Map<String, dynamic> map) => CreateUserDto(
        name: map['name'] as String,
        age: map['age'] as int,
        email: map['email'] as String?,
      );

  /// Alternative factory (e.g. from API response) — schema is looked up by Type.
  factory CreateUserDto.fromApi(Map<String, dynamic> map) => CreateUserDto(
        name: map['name'] as String,
        age: map['age'] as int,
        email: map['email'] as String?,
      );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('Zto.parse with explicit schema', () {
    test('parses DTO with fromMap factory', () {
      final dto = Zto.parse(
        {'name': 'Alice', 'age': 25},
        CreateUserDto.fromMap,
        schema: $createUserDtoSchema,
      );
      expect(dto.name, 'Alice');
      expect(dto.age, 25);
    });

    test('parses DTO with fromApi factory', () {
      final dto = Zto.parse(
        {'name': 'Alice', 'age': 25},
        CreateUserDto.fromApi,
        schema: $createUserDtoSchema,
      );
      expect(dto.name, 'Alice');
      expect(dto.age, 25);
    });

    test('validates when parsing with schema', () {
      expect(
        () => Zto.parse(
          {'age': 25},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        ),
        throwsA(isA<ZtoException>()),
      );
    });
  });

  group('Zto.parse validates data', () {
    test('returns parsed DTO on valid data', () {
      final dto = Zto.parse(
        {'name': 'Alice', 'age': 25},
        CreateUserDto.fromMap,
        schema: $createUserDtoSchema,
      );
      expect(dto.name, 'Alice');
      expect(dto.age, 25);
    });

    test('email is null when absent in map', () {
      final dto = Zto.parse(
        {'name': 'Alice', 'age': 25},
        CreateUserDto.fromMap,
        schema: $createUserDtoSchema,
      );
      expect(dto.email, isNull);
    });

    test('email is populated when present', () {
      final dto = Zto.parse(
        {'name': 'Alice', 'age': 25, 'email': 'alice@example.com'},
        CreateUserDto.fromMap,
        schema: $createUserDtoSchema,
      );
      expect(dto.email, 'alice@example.com');
    });

    test('throws ZtoException on missing required field', () {
      expect(
        () => Zto.parse(
          {'age': 25},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        ),
        throwsA(isA<ZtoException>()),
      );
    });

    test('exception contains the failing field name', () {
      try {
        Zto.parse(
          {'age': 25},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        );
        fail('should throw');
      } on ZtoException catch (e) {
        expect(e.issues.any((i) => i.field == 'name'), isTrue);
      }
    });

    test('throws ZtoException on type mismatch', () {
      expect(
        () => Zto.parse(
          {'name': 'Alice', 'age': 'not-an-int'},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        ),
        throwsA(isA<ZtoException>()),
      );
    });

    test('throws ZtoException when validator fails', () {
      expect(
        () => Zto.parse(
          {'name': 'A', 'age': 25},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        ),
        throwsA(isA<ZtoException>()),
      );
    });

    test('collects all field errors before throwing', () {
      try {
        Zto.parse(
          {'name': 'A', 'age': 10},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        );
        fail('should throw');
      } on ZtoException catch (e) {
        expect(e.issues.length, greaterThanOrEqualTo(2));
      }
    });

    test('works with inline lambda factory', () {
      final dto = Zto.parse(
        {'name': 'Bob', 'age': 30},
        (map) => CreateUserDto(
          name: map['name'] as String,
          age: map['age'] as int,
        ),
        schema: $createUserDtoSchema,
      );
      expect(dto.name, 'Bob');
    });
  });

  group('Zto.parseList', () {
    test('parses all items in the list', () {
      final dtos = Zto.parseList(
        [
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ],
        CreateUserDto.fromMap,
        schema: $createUserDtoSchema,
      );
      expect(dtos, hasLength(2));
      expect(dtos.first.name, 'Alice');
      expect(dtos.last.name, 'Bob');
    });

    test('throws ZtoException when any item in the list is invalid', () {
      expect(
        () => Zto.parseList(
          [
            {'name': 'Alice', 'age': 25},
            {'name': 'A', 'age': 10}, // fails ZMinLength + ZMin
          ],
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        ),
        throwsA(isA<ZtoException>()),
      );
    });

    test('empty list returns empty list', () {
      final result = Zto.parseList(
        [],
        CreateUserDto.fromMap,
        schema: $createUserDtoSchema,
      );
      expect(result, isEmpty);
    });
  });

  group('ZtoDto.refine', () {
    test('passes when predicate returns true', () {
      final dto = Zto.parse(
        {'name': 'Alice', 'age': 25},
        CreateUserDto.fromMap,
        schema: $createUserDtoSchema,
      ).refine((d) => d.age >= 18, field: 'age', message: 'Must be adult');
      expect(dto.name, 'Alice');
    });

    test('throws ZtoException when predicate returns false', () {
      expect(
        () => Zto.parse(
          {'name': 'Alice', 'age': 25},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        ).refine((d) => d.age > 100, field: 'age', message: 'Unreachable age'),
        throwsA(isA<ZtoException>()),
      );
    });

    test('exception contains custom message', () {
      try {
        Zto.parse(
          {'name': 'Alice', 'age': 25},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        ).refine((_) => false, message: 'Custom error');
        fail('should throw');
      } on ZtoException catch (e) {
        expect(e.issues.first.message, 'Custom error');
      }
    });

    test('can be chained multiple times', () {
      final dto = Zto.parse(
        {'name': 'Alice', 'age': 25},
        CreateUserDto.fromMap,
        schema: $createUserDtoSchema,
      )
          .refine((d) => d.name.isNotEmpty, message: 'Name empty')
          .refine((d) => d.age < 200, message: 'Age too large');
      expect(dto.name, 'Alice');
    });

    test('field is null in issue when not provided', () {
      try {
        Zto.parse(
          {'name': 'Alice', 'age': 25},
          CreateUserDto.fromMap,
          schema: $createUserDtoSchema,
        ).refine((_) => false, message: 'Fail');
        fail('should throw');
      } on ZtoException catch (e) {
        expect(e.issues.first.field, isNull);
      }
    });
  });
}
