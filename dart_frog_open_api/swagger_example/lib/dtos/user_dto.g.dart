// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// ZDtoGenerator
// **************************************************************************

const $CreateUserDtoSchema = ZtoSchema(
  typeName: 'CreateUserDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'name', description: 'Full name', example: 'Alice Silva'),
      validators: [ZMinLength(2), ZMaxLength(100)],
      isNullable: true,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'email',
          description: 'E-mail address',
          example: 'alice@example.com'),
      validators: [ZEmail()],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZEnum(
          mapKey: 'role',
          values: ['admin', 'editor', 'viewer'],
          description: 'User role'),
      validators: [],
      isNullable: false,
    ),
  ],
);
final _ztoRegCreateUserDto =
    Zto.registerSchema(CreateUserDto.fromMap, $CreateUserDtoSchema);
final _ztoRegTypeCreateUserDto =
    Zto.registerSchema(CreateUserDto, $CreateUserDtoSchema);

const $UpdateUserDtoSchema = ZtoSchema(
  typeName: 'UpdateUserDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'name', description: 'Full name', example: 'Alice Silva'),
      validators: [ZMinLength(2)],
      isNullable: true,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'email',
          description: 'E-mail address',
          example: 'alice@example.com'),
      validators: [ZEmail()],
      isNullable: true,
    ),
  ],
);
final _ztoRegUpdateUserDto =
    Zto.registerSchema(UpdateUserDto.fromMap, $UpdateUserDtoSchema);
final _ztoRegTypeUpdateUserDto =
    Zto.registerSchema(UpdateUserDto, $UpdateUserDtoSchema);

const $UserResponseDtoSchema = ZtoSchema(
  typeName: 'UserResponseDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'id', description: 'Unique identifier'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name', description: 'Full name'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'username',
          description: 'Legacy short username — use `name` instead.',
          deprecated: true),
      validators: [],
      isNullable: true,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'email', description: 'E-mail address'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation:
          ZEnum(mapKey: 'role', values: ['admin', 'editor', 'viewer']),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation:
          ZDate(mapKey: 'created_at', description: 'Creation timestamp'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZMetaData(
          mapKey: 'meta_data',
          description: 'Metadata do usuario',
          example: {'key': 'value'}),
      validators: [],
      isNullable: false,
    ),
  ],
);

const $UserListResponseDtoSchema = ZtoSchema(
  typeName: 'UserListResponseDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZListOf(
          mapKey: 'data',
          dtoSchema: $UserResponseDtoSchema,
          description: 'User items'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZInt(
          mapKey: 'total', description: 'Total number of users', example: 10),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZObj(
          mapKey: 'address',
          dtoSchema: $AddressDtoSchema,
          description: 'Address items'),
      validators: [],
      isNullable: false,
    ),
  ],
);

const $AddressDtoSchema = ZtoSchema(
  typeName: 'AddressDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'street', description: 'Street', example: 'Rua das Flores'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation:
          ZString(mapKey: 'city', description: 'City', example: 'São Paulo'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation:
          ZString(mapKey: 'state', description: 'State', example: 'SP'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'zip_code', description: 'Zip code', example: '12345678'),
      validators: [],
      isNullable: false,
    ),
  ],
);
