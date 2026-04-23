import 'dart:convert';

import 'package:zto/zto.dart';

part 'product_dto.g.dart';

@ZDto(description: 'Create a new product', parseType: ParseType.snakeCase)
class CreateProductDto with ZtoDto<CreateProductDto> {
  @ZString(description: 'Product name', example: 'Widget Pro')
  @ZMinLength(2)
  final String name;

  @ZDouble(description: 'Price in USD', example: 29.99)
  @ZPositive()
  final double price;

  @ZString(description: 'Stock-keeping unit', example: 'WGT-001')
  final String? sku;

  const CreateProductDto({required this.name, required this.price, this.sku});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'sku': sku,
    };
  }

  factory CreateProductDto.fromMap(Map<String, dynamic> map) {
    return CreateProductDto(
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      sku: map['sku'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CreateProductDto.fromJson(String source) => CreateProductDto.fromMap(json.decode(source));
}

@ZDto(description: 'Product response', parseType: ParseType.snakeCase)
class ProductResponseDto {
  @ZString(description: 'Unique identifier')
  @ZUuid()
  final String id;

  @ZString(description: 'Product name')
  final String name;

  @ZDouble(description: 'Price in USD')
  final double price;

  @ZString()
  @ZNullable()
  final String? sku;

  const ProductResponseDto({
    required this.id,
    required this.name,
    required this.price,
    this.sku,
  });
}

@ZDto(description: 'Paginated list of products')
class ProductListResponseDto {
  @ZList(itemType: ZObj, description: 'Product items')
  final List<ProductResponseDto> data;

  @ZInt(description: 'Total number of products')
  final int total;

  const ProductListResponseDto({required this.data, required this.total});
}
