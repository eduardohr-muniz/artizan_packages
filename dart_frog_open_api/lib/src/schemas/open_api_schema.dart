import 'package:zto/zto.dart' show DtoToOpenApi, ZtoSchema;

/// Represents an OpenAPI 3.0 JSON Schema, independent of any DTO package.
///
/// Use [OpenApiSchema.fromZto] to convert a [ZtoSchema] from the `zto` package.
class OpenApiSchema {
  const OpenApiSchema({
    required this.typeName,
    required this.jsonSchema,
    this.ztoSchema,
    this.isInline = false,
  });

  /// Schema name used in `$ref` (e.g. `#/components/schemas/CreateUserDto`).
  ///
  /// Empty for [isInline] schemas, which are emitted at the use site instead
  /// of being registered as a reusable component.
  final String typeName;

  /// OpenAPI 3.0 JSON Schema object (type, properties, required, etc.).
  final Map<String, dynamic> jsonSchema;

  /// Original [ZtoSchema] used to build this schema. Used by [OpenApiBuilder]
  /// to recursively discover nested schemas referenced via `$ref`.
  final ZtoSchema? ztoSchema;

  /// When `true`, [jsonSchema] is emitted directly at the use site (e.g.
  /// `responses.200.content.application/json.schema`) instead of being hoisted
  /// into `components/schemas` and referenced via `$ref`.
  final bool isInline;

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

  /// Creates an array schema wrapping a [ZtoSchema] item type.
  factory OpenApiSchema.arrayOf(ZtoSchema itemSchema) => OpenApiSchema(
        typeName: '${itemSchema.typeName}List',
        jsonSchema: {
          'type': 'array',
          'items': {r'$ref': '#/components/schemas/${itemSchema.typeName}'},
        },
        ztoSchema: itemSchema,
      );

  /// Creates an inline schema from a raw OpenAPI 3.0 JSON Schema [jsonSchema].
  ///
  /// The map is emitted as-is at the use site (no `$ref`, no component entry).
  /// Use this for ad-hoc shapes that are not backed by a `zto` DTO.
  factory OpenApiSchema.inline(Map<String, dynamic> jsonSchema) => OpenApiSchema(
        typeName: '',
        jsonSchema: jsonSchema,
        isInline: true,
      );
}
