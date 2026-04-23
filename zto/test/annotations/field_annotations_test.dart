import 'package:test/test.dart';
import 'package:zto/src/core/zto_schema.dart';
import 'package:zto/zto.dart';

void main() {
  group('Field type annotations', () {
    group('@ZString', () {
      test('is const and holds mapKey, description, example', () {
        const a = ZString(mapKey: 'name', description: 'Full name', example: 'John');
        expect(a.mapKey, 'name');
        expect(a.key, 'name');
        expect(a.description, 'Full name');
        expect(a.example, 'John');
      });

      test('mapKey is optional (null when not provided)', () {
        const a = ZString(description: 'A field');
        expect(a.mapKey, isNull);
        expect(a.key, '');
      });

      test('description and example are optional', () {
        const a = ZString(mapKey: 'name');
        expect(a.description, isNull);
        expect(a.example, isNull);
      });

      test('failMessage is optional and stored when provided', () {
        const a = ZString(mapKey: 'name', failMessage: 'Nome deve ser texto');
        expect(a.failMessage, 'Nome deve ser texto');
      });

      test('failMessage is null when not provided', () {
        const a = ZString(mapKey: 'name');
        expect(a.failMessage, isNull);
      });
    });

    group('@ZInt', () {
      test('is const and holds mapKey, description, example', () {
        const a = ZInt(mapKey: 'age', description: 'Age', example: 25);
        expect(a.mapKey, 'age');
        expect(a.key, 'age');
        expect(a.description, 'Age');
        expect(a.example, 25);
      });
    });

    group('@ZDouble', () {
      test('is const and holds mapKey', () {
        const a = ZDouble(mapKey: 'price', description: 'Price', example: 9.99);
        expect(a.mapKey, 'price');
        expect(a.example, 9.99);
      });
    });

    group('@ZNum', () {
      test('is const and holds mapKey', () {
        const a = ZNum(mapKey: 'score');
        expect(a.mapKey, 'score');
        expect(a.key, 'score');
      });
    });

    group('@ZBool', () {
      test('is const and holds mapKey, description, example', () {
        const a = ZBool(mapKey: 'active', description: 'Is active', example: true);
        expect(a.mapKey, 'active');
        expect(a.description, 'Is active');
        expect(a.example, true);
      });
    });

    group('@ZDate', () {
      test('is const and holds mapKey', () {
        const a = ZDate(mapKey: 'createdAt', description: 'Creation date');
        expect(a.mapKey, 'createdAt');
        expect(a.description, 'Creation date');
      });
    });

    group('@ZFile', () {
      test('is const and holds mapKey', () {
        const a = ZFile(mapKey: 'avatar', description: 'Profile picture');
        expect(a.mapKey, 'avatar');
        expect(a.description, 'Profile picture');
      });
    });

    group('@ZEnum', () {
      test('is const and holds mapKey and values', () {
        const a = ZEnum(mapKey: 'role', values: ['admin', 'editor', 'viewer']);
        expect(a.mapKey, 'role');
        expect(a.key, 'role');
        expect(a.values, ['admin', 'editor', 'viewer']);
      });

      test('holds description and example', () {
        const a = ZEnum(mapKey: 'role', values: ['a', 'b'], description: 'Role', example: 'admin');
        expect(a.description, 'Role');
        expect(a.example, 'admin');
      });
    });

    group('@ZList', () {
      test('is const and holds mapKey and itemType', () {
        const a = ZList(mapKey: 'tags', itemType: ZString);
        expect(a.mapKey, 'tags');
        expect(a.key, 'tags');
        expect(a.itemType, ZString);
      });
    });

    group('@ZListOf', () {
      test('is const and holds mapKey and dtoSchema', () {
        const schema = ZtoSchema(typeName: 'AddressDto', descriptors: []);
        const a = ZListOf(mapKey: 'addresses', dtoSchema: schema);
        expect(a.mapKey, 'addresses');
        expect(a.dtoSchema!.typeName, 'AddressDto');
      });

      test('is const and holds mapKey and dtoType', () {
        const a = ZListOf(mapKey: 'addresses', dtoType: String);
        expect(a.mapKey, 'addresses');
        expect(a.dtoType, String);
      });
    });

    group('@ZObj', () {
      test('is const and holds mapKey and dtoSchema', () {
        const schema = ZtoSchema(typeName: 'AddressDto', descriptors: []);
        const a = ZObj(mapKey: 'address', dtoSchema: schema);
        expect(a.mapKey, 'address');
        expect(a.dtoSchema!.typeName, 'AddressDto');
      });

      test('is const and holds mapKey and dtoType', () {
        const a = ZObj(mapKey: 'address', dtoType: String);
        expect(a.mapKey, 'address');
        expect(a.dtoType, String);
      });
    });
  });

  group('Modifier annotations', () {
    test('@ZNullable is const', () {
      const a = ZNullable();
      expect(a, isA<ZNullable>());
    });
  });

  group('ParseType', () {
    test('camelCase value exists', () => expect(ParseType.camelCase, isA<ParseType>()));
    test('snakeCase value exists', () => expect(ParseType.snakeCase, isA<ParseType>()));
    test('pascalCase value exists', () => expect(ParseType.pascalCase, isA<ParseType>()));
    test('kebabCase value exists', () => expect(ParseType.kebabCase, isA<ParseType>()));
  });

  group('@ZDto', () {
    test('is const and holds description', () {
      const a = ZDto(description: 'A user DTO');
      expect(a.description, 'A user DTO');
    });

    test('defaults parseType to camelCase', () {
      const a = ZDto(description: 'X');
      expect(a.parseType, ParseType.camelCase);
    });

    test('accepts parseType snakeCase', () {
      const a = ZDto(description: 'X', parseType: ParseType.snakeCase);
      expect(a.parseType, ParseType.snakeCase);
    });

    test('deprecated defaults to false', () {
      const a = ZDto(description: 'X');
      expect(a.deprecated, isFalse);
    });

    test('can be marked deprecated', () {
      const a = ZDto(description: 'X', deprecated: true);
      expect(a.deprecated, isTrue);
    });
  });

  group('@ZEntity', () {
    test('is const and holds description', () {
      const a = ZEntity(description: 'A user entity');
      expect(a.description, 'A user entity');
    });

    test('defaults parseType to camelCase', () {
      const a = ZEntity(description: 'X');
      expect(a.parseType, ParseType.camelCase);
    });

    test('accepts parseType snakeCase', () {
      const a = ZEntity(description: 'X', parseType: ParseType.snakeCase);
      expect(a.parseType, ParseType.snakeCase);
    });

    test('deprecated defaults to false', () {
      const a = ZEntity(description: 'X');
      expect(a.deprecated, isFalse);
    });

    test('can be marked deprecated', () {
      const a = ZEntity(description: 'X', deprecated: true);
      expect(a.deprecated, isTrue);
    });
  });

  group('@Dto (deprecated, backward compat)', () {
    test('is const and holds description', () {
      // ignore: deprecated_member_use
      const a = Dto(description: 'A user DTO');
      expect(a.description, 'A user DTO');
    });

    test('deprecated defaults to false', () {
      // ignore: deprecated_member_use
      const a = Dto(description: 'X');
      expect(a.deprecated, isFalse);
    });
  });
}
