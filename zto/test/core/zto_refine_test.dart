import 'package:test/test.dart';
import 'package:zto/zto.dart';

// ── Schema (mirrors what zto_generator would produce) ───────────────────────

const $plainDtoSchema = ZtoSchema(
  typeName: 'PlainDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name'),
      validators: [ZMinLength(2)],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZInt(mapKey: 'age'),
      validators: [],
      isNullable: false,
    ),
  ],
);

// ── DTO SEM o mixin ZtoDto — o ponto da extension é justamente cobrir estes ───

class PlainDto {
  const PlainDto({required this.name, required this.age});

  final String name;
  final int age;

  factory PlainDto.fromMap(Map<String, dynamic> map) => PlainDto(
        name: map['name'] as String,
        age: map['age'] as int,
      );
}

void main() {
  group('ZtoRefineExtension.refine (sem mixin)', () {
    test('retorna a própria instância quando o predicado é verdadeiro', () {
      final dto = $plainDtoSchema
          .parse({'name': 'Alice', 'age': 25}, PlainDto.fromMap).refine(
        (d) => d.age >= 18,
        message: 'Must be adult',
      );
      expect(dto, isA<PlainDto>());
      expect(dto.name, 'Alice');
      expect(dto.age, 25);
    });

    test('lança ZtoException quando o predicado é falso', () {
      expect(
        () => $plainDtoSchema
            .parse({'name': 'Alice', 'age': 25}, PlainDto.fromMap).refine(
                (d) => d.age > 100,
                message: 'Unreachable age'),
        throwsA(isA<ZtoException>()),
      );
    });

    test('a exception carrega a mensagem customizada', () {
      try {
        $plainDtoSchema
            .parse({'name': 'Alice', 'age': 25}, PlainDto.fromMap).refine(
          (_) => false,
          message: 'Custom error',
        );
        fail('deveria lançar');
      } on ZtoException catch (e) {
        expect(e.issues.first.message, 'Custom error');
      }
    });

    test('o issue carrega o field quando informado', () {
      try {
        $plainDtoSchema
            .parse({'name': 'Alice', 'age': 25}, PlainDto.fromMap).refine(
          (_) => false,
          field: 'age',
          message: 'Fail',
        );
        fail('deveria lançar');
      } on ZtoException catch (e) {
        expect(e.issues.first.field, 'age');
      }
    });

    test('o field é null no issue quando não informado', () {
      try {
        $plainDtoSchema
            .parse({'name': 'Alice', 'age': 25}, PlainDto.fromMap).refine(
          (_) => false,
          message: 'Fail',
        );
        fail('deveria lançar');
      } on ZtoException catch (e) {
        expect(e.issues.first.field, isNull);
      }
    });

    test('pode ser encadeado múltiplas vezes', () {
      final dto = $plainDtoSchema
          .parse({'name': 'Alice', 'age': 25}, PlainDto.fromMap)
          .refine((d) => d.name.isNotEmpty, message: 'Name empty')
          .refine((d) => d.age < 200, message: 'Age too large');
      expect(dto.name, 'Alice');
    });

    test('funciona em qualquer tipo, não só DTOs (não exige mixin)', () {
      expect(42.refine((n) => n > 0, message: 'positivo'), 42);
      expect(
        () => 'x'.refine((s) => s.length > 1, message: 'curto'),
        throwsA(isA<ZtoException>()),
      );
    });
  });
}
