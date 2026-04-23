// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_dto.dart';

// **************************************************************************
// ZDtoGenerator
// **************************************************************************

const $CreateProductDtoSchema = ZtoSchema(
  typeName: 'CreateProductDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'name', description: 'Product name', example: 'Widget Pro'),
      validators: [ZMinLength(2)],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation:
          ZDouble(mapKey: 'price', description: 'Price in USD', example: 29.99),
      validators: [ZPositive()],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'sku', description: 'Stock-keeping unit', example: 'WGT-001'),
      validators: [],
      isNullable: true,
    ),
  ],
);
final _ztoRegCreateProductDto =
    Zto.registerSchema(CreateProductDto.fromMap, $CreateProductDtoSchema);
final _ztoRegTypeCreateProductDto =
    Zto.registerSchema(CreateProductDto, $CreateProductDtoSchema);

const $ProductResponseDtoSchema = ZtoSchema(
  typeName: 'ProductResponseDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'id', description: 'Unique identifier'),
      validators: [ZUuid()],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name', description: 'Product name'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZDouble(mapKey: 'price', description: 'Price in USD'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'sku'),
      validators: [],
      isNullable: true,
    ),
  ],
);

const $ProductListResponseDtoSchema = ZtoSchema(
  typeName: 'ProductListResponseDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZListOf(
          mapKey: 'data',
          dtoSchema: $ProductResponseDtoSchema,
          description: 'Product items'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation:
          ZInt(mapKey: 'total', description: 'Total number of products'),
      validators: [],
      isNullable: false,
    ),
  ],
);
