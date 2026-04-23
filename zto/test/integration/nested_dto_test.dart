import 'package:test/test.dart';
import 'package:zto/zto.dart';

// ── Schemas (mirrors what zto_generator would produce) ──────────────────────

const $addressDtoSchema = ZtoSchema(
  typeName: 'AddressDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'street'),
      validators: [ZMinLength(1)],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'city'),
      validators: [ZMinLength(2)],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZInt(mapKey: 'zipCode'),
      validators: [ZMin(0)],
      isNullable: false,
    ),
  ],
);

const $userWithAddressDtoSchema = ZtoSchema(
  typeName: 'UserWithAddressDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name'),
      validators: [ZMinLength(2)],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZObj(mapKey: 'address', dtoSchema: $addressDtoSchema),
      validators: [],
      isNullable: false,
    ),
  ],
);

const $userWithAddressesDtoSchema = ZtoSchema(
  typeName: 'UserWithAddressesDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name'),
      validators: [ZMinLength(2)],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZObj(mapKey: 'primaryAddress', dtoSchema: $addressDtoSchema),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZListOf(mapKey: 'secondaryAddresses', dtoSchema: $addressDtoSchema),
      validators: [],
      isNullable: false,
    ),
  ],
);

// ── AddressDto (nested) ─────────────────────────────────────────────────────

@ZDto(description: 'Address')
class AddressDto with ZtoDto<AddressDto> {
  final String street;
  final String city;
  final int zipCode;

  const AddressDto({
    required this.street,
    required this.city,
    required this.zipCode,
  });

  factory AddressDto.fromMap(Map<String, dynamic> m) => AddressDto(
        street: m['street'] as String,
        city: m['city'] as String,
        zipCode: m['zipCode'] as int,
      ).refine((d) => d.street.startsWith('Main St'), message: 'Street must start with "Main St"');
}

// ── UserDto with single Address (ZObj) ─────────────────────────────────────

@ZDto(description: 'User with address')
class UserWithAddressDto with ZtoDto<UserWithAddressDto> {
  final String name;
  final AddressDto address;

  const UserWithAddressDto({
    required this.name,
    required this.address,
  });

  factory UserWithAddressDto.fromMap(Map<String, dynamic> m) => UserWithAddressDto(
        name: m['name'] as String,
        address: AddressDto.fromMap(m['address'] as Map<String, dynamic>),
      ).refine((dto) => dto.name.startsWith('Alice'), message: 'Name must start with "Alice"');
}

// ── UserDto with primary address + list of secondary addresses ──────────────

@ZDto(description: 'User with primary and secondary addresses')
class UserWithAddressesDto {
  final String name;
  final AddressDto primaryAddress;
  final List<AddressDto> secondaryAddresses;

  const UserWithAddressesDto({
    required this.name,
    required this.primaryAddress,
    required this.secondaryAddresses,
  });

  factory UserWithAddressesDto.fromMap(Map<String, dynamic> m) => UserWithAddressesDto(
        name: m['name'] as String,
        primaryAddress: AddressDto.fromMap(m['primaryAddress'] as Map<String, dynamic>),
        secondaryAddresses: (m['secondaryAddresses'] as List?)?.map((e) => AddressDto.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      );
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    Zto.registerSchemas([
      (UserWithAddressDto, $userWithAddressDtoSchema),
      (UserWithAddressesDto, $userWithAddressesDtoSchema),
    ]);
  });

  group('UserDto with embedded AddressDto (ZObj)', () {
    test('passes when address has valid nested fields', () {
      final map = {
        'name': 'Alice',
        'address': {
          'street': 'Main St',
          'city': 'NYC',
          'zipCode': 10001,
        },
      };
      final dto = $userWithAddressDtoSchema.parse(map, UserWithAddressDto.fromMap);
      expect(dto.name, 'Alice');
      expect(dto.address.street, 'Main St');
      expect(dto.address.city, 'NYC');
      expect(dto.address.zipCode, 10001);
    });

    test('rejects when address is wrong type (string)', () {
      expect(
        () => $userWithAddressDtoSchema.parse(
          {
            'name': 'Alice',
            'address': 'invalid',
          },
          UserWithAddressDto.fromMap,
        ),
        throwsA(isA<ZtoException>()),
      );
    });

    test('rejects when nested address has invalid street (empty)', () {
      final map = {
        'name': 'Alice',
        'address': {
          'street': '',
          'city': 'NYC',
          'zipCode': 10001,
        },
      };
      expect(
        () => $userWithAddressDtoSchema.parse(map, UserWithAddressDto.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });

    test('rejects when nested address has invalid zipCode (negative)', () {
      final map = {
        'name': 'Alice',
        'address': {
          'street': 'Main St',
          'city': 'NYC',
          'zipCode': -1,
        },
      };
      expect(
        () => $userWithAddressDtoSchema.parse(map, UserWithAddressDto.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });

    test('rejects when UserWithAddressDto refine fails (name must start with "Alice")', () {
      final map = {
        'name': 'Bob',
        'address': {
          'street': 'Main St',
          'city': 'NYC',
          'zipCode': 10001,
        },
      };
      try {
        $userWithAddressDtoSchema.parse(map, UserWithAddressDto.fromMap);
        fail('should throw');
      } on ZtoException catch (e) {
        expect(e.issues.first.message, 'Name must start with "Alice"');
      }
    });

    test('rejects when AddressDto refine fails (street must start with "Main St")', () {
      final map = {
        'name': 'Alice',
        'address': {
          'street': 'Oak Ave',
          'city': 'NYC',
          'zipCode': 10001,
        },
      };
      try {
        $userWithAddressDtoSchema.parse(map, UserWithAddressDto.fromMap);
        fail('should throw');
      } on ZtoException catch (e) {
        expect(e.issues.first.message, 'Street must start with "Main St"');
      }
    });
  });

  group('UserDto with primary address + secondary addresses list', () {
    test('passes when primary and list of addresses are valid', () {
      final map = {
        'name': 'Bob',
        'primaryAddress': {
          'street': 'Main St',
          'city': 'LA',
          'zipCode': 90001,
        },
        'secondaryAddresses': [
          {'street': 'Main St 2', 'city': 'LA', 'zipCode': 90002},
        ],
      };
      final dto = $userWithAddressesDtoSchema.parse(map, UserWithAddressesDto.fromMap);
      expect(dto.name, 'Bob');
      expect(dto.primaryAddress.street, 'Main St');
      expect(dto.secondaryAddresses, hasLength(1));
      expect(dto.secondaryAddresses.first.street, 'Main St 2');
    });

    test('rejects when primaryAddress has invalid nested field', () {
      final map = {
        'name': 'Bob',
        'primaryAddress': {
          'street': '',
          'city': 'LA',
          'zipCode': 90001,
        },
        'secondaryAddresses': [],
      };
      expect(
        () => $userWithAddressesDtoSchema.parse(map, UserWithAddressesDto.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });

    test('rejects when secondaryAddresses item has invalid nested field', () {
      final map = {
        'name': 'Bob',
        'primaryAddress': {
          'street': 'Main St',
          'city': 'LA',
          'zipCode': 90001,
        },
        'secondaryAddresses': [
          {'street': 'Main St', 'city': 'LA', 'zipCode': 90001},
          {'street': '', 'city': 'NYC', 'zipCode': 10001},
        ],
      };
      expect(
        () => $userWithAddressesDtoSchema.parse(map, UserWithAddressesDto.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });
  });
}
