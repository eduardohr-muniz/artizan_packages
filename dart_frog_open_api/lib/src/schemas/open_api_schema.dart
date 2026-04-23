import 'package:zto/zto.dart' show DtoToOpenApi, ZtoSchema;

/// Represents an OpenAPI 3.0 JSON Schema, independent of any DTO package.
///
/// Use [OpenApiSchema.fromZto] to convert a [ZtoSchema] from the `zto` package.
class OpenApiSchema {
  const OpenApiSchema({
    required this.typeName,
    required this.jsonSchema,
    this.ztoSchema,
  });

  /// Schema name used in `$ref` (e.g. `#/components/schemas/CreateUserDto`).
  final String typeName;

  /// OpenAPI 3.0 JSON Schema object (type, properties, required, etc.).
  final Map<String, dynamic> jsonSchema;

  /// Original [ZtoSchema] used to build this schema. Used by [OpenApiBuilder]
  /// to recursively discover nested schemas referenced via `$ref`.
  final ZtoSchema? ztoSchema;

  /// Converts a [ZtoSchema] from the `zto` package to [OpenApiSchema].
  ///
  /// Usage in api_config:
  /// ```dart
  /// requestBodySchema: OpenApiSchema.fromZto($CreateUserDtoSchema),
  /// responseSchemas: {200: OpenApiSchema.fromZto($UserResponseDtoSchema)},
  /// ```
  factory OpenApiSchema.fromZto(ZtoSchema zto) => OpenApiSchema(
        typeName: zto.typeName,
        jsonSchema: DtoToOpenApi.convert(zto),
        ztoSchema: zto,
      );
}
