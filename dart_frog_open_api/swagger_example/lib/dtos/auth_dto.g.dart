// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// ZDtoGenerator
// **************************************************************************

const $LoginRequestDtoSchema = ZtoSchema(
  typeName: 'LoginRequestDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'email',
          description: 'E-mail address',
          example: 'exemplo@email.com'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'password', description: 'Password', example: '123456'),
      validators: [],
      isNullable: false,
    ),
  ],
);

const $LoginResponseDtoSchema = ZtoSchema(
  typeName: 'LoginResponseDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'token', description: 'JWT Token'),
      validators: [],
      isNullable: false,
    ),
  ],
);
