import 'package:test/test.dart';
import 'package:zto/zto.dart';

// ── Schemas (mirrors what zto_generator would produce) ──────────────────────

const $userDtoCreateSchema = ZtoSchema(
  typeName: 'UserDtoCreate',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name'),
      validators: [ZMinLength(2)],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'email'),
      validators: [ZEmail()],
      isNullable: false,
    ),
  ],
);

const $userDtoUpdateSchema = ZtoSchema(
  typeName: 'UserDtoUpdate',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name'),
      validators: [ZMinLength(2)],
      isNullable: true,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'email'),
      validators: [ZEmail()],
      isNullable: true,
    ),
  ],
);

// ── Base UserDto (marker, no fields) ──────────────────────────────────────────

abstract class UserDto {
  const UserDto();
}

// ── UserDtoCreate: all required ─────────────────────────────────────────────

// ignore: deprecated_member_use
@Dto(description: 'Create user')
class UserDtoCreate extends UserDto with ZtoDto<UserDtoCreate> {
  @ZString(mapKey: 'name')
  @ZMinLength(2)
  final String name;

  @ZString(mapKey: 'email')
  @ZEmail()
  final String email;

  const UserDtoCreate({required this.name, required this.email});

  factory UserDtoCreate.fromMap(Map<String, dynamic> map) => UserDtoCreate(
        name: map['name'] as String,
        email: map['email'] as String,
      );
}

// ── UserDtoUpdate: all nullable ─────────────────────────────────────────────

// ignore: deprecated_member_use
@Dto(description: 'Update user')
class UserDtoUpdate extends UserDto with ZtoDto<UserDtoUpdate> {
  @ZString(mapKey: 'name')
  @ZMinLength(2)
  @ZNullable()
  final String? name;

  @ZString(mapKey: 'email')
  @ZEmail()
  @ZNullable()
  final String? email;

  const UserDtoUpdate({this.name, this.email});

  factory UserDtoUpdate.fromMap(Map<String, dynamic> map) => UserDtoUpdate(
        name: map['name'] as String?,
        email: map['email'] as String?,
      );
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    Zto.registerSchemas([
      (UserDtoCreate, $userDtoCreateSchema),
      (UserDtoUpdate, $userDtoUpdateSchema),
    ]);
  });

  group('UserDtoCreate (all required)', () {
    test('parses valid data', () {
      final dto = $userDtoCreateSchema.parse(
        {'name': 'Alice', 'email': 'alice@example.com'},
        UserDtoCreate.fromMap,
      );
      expect(dto.name, 'Alice');
      expect(dto.email, 'alice@example.com');
    });

    test('throws when name is missing', () {
      expect(
        () => $userDtoCreateSchema.parse({'email': 'alice@example.com'}, UserDtoCreate.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });

    test('throws when email is missing', () {
      expect(
        () => $userDtoCreateSchema.parse({'name': 'Alice'}, UserDtoCreate.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });

    test('throws when name is too short', () {
      expect(
        () => $userDtoCreateSchema.parse({'name': 'A', 'email': 'alice@example.com'}, UserDtoCreate.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });

    test('throws when email is invalid', () {
      expect(
        () => $userDtoCreateSchema.parse({'name': 'Alice', 'email': 'not-email'}, UserDtoCreate.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });
  });

  group('UserDtoUpdate (all nullable)', () {
    test('parses full data', () {
      final dto = $userDtoUpdateSchema.parse(
        {'name': 'Alice', 'email': 'alice@example.com'},
        UserDtoUpdate.fromMap,
      );
      expect(dto.name, 'Alice');
      expect(dto.email, 'alice@example.com');
    });

    test('parses empty map (all null)', () {
      final dto = $userDtoUpdateSchema.parse({}, UserDtoUpdate.fromMap);
      expect(dto.name, isNull);
      expect(dto.email, isNull);
    });

    test('parses partial data (only name)', () {
      final dto = $userDtoUpdateSchema.parse({'name': 'Alice'}, UserDtoUpdate.fromMap);
      expect(dto.name, 'Alice');
      expect(dto.email, isNull);
    });

    test('parses partial data (only email)', () {
      final dto = $userDtoUpdateSchema.parse({'email': 'alice@example.com'}, UserDtoUpdate.fromMap);
      expect(dto.name, isNull);
      expect(dto.email, 'alice@example.com');
    });

    test('validates when name is provided but too short', () {
      expect(
        () => $userDtoUpdateSchema.parse({'name': 'A', 'email': 'alice@example.com'}, UserDtoUpdate.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });

    test('validates when email is provided but invalid', () {
      expect(
        () => $userDtoUpdateSchema.parse({'name': 'Alice', 'email': 'not-email'}, UserDtoUpdate.fromMap),
        throwsA(isA<ZtoException>()),
      );
    });
  });
}
