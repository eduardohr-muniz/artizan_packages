import 'zto_exception.dart';
import '../annotations/field_annotations.dart' show ZtoSchemaBase;
import '../reflection/field_descriptor.dart';

/// Describes a Zto DTO: its class name and the list of field descriptors
/// generated from its `@Z*` annotations.
///
/// Instances are produced by the `zto_generator` build_runner package and
/// stored as top-level `const` values in the generated `.g.dart` file.
///
/// ```dart
/// // Generated in create_user_dto.g.dart:
/// const $createUserDtoSchema = ZtoSchema(
///   typeName: 'CreateUserDto',
///   descriptors: [
///     FieldDescriptor(fieldAnnotation: ZString('name'), validators: [ZMinLength(2)], isNullable: false),
///   ],
/// );
/// ```
///
/// Used by [DtoToOpenApi.convert] and [OperationSchema.requestBodySchema] to
/// build OpenAPI specs without runtime reflection.
class ZtoSchema extends ZtoSchemaBase {
  const ZtoSchema({
    required this.typeName,
    required this.descriptors,
  });

  /// The class name of the DTO (e.g. `'CreateUserDto'`).
  ///
  /// Used as the key under `components/schemas` in the OpenAPI spec.
  @override
  final String typeName;

  /// Field descriptors extracted from the DTO's `@Z*` annotations.
  final List<FieldDescriptor> descriptors;

  /// Validates [map] with this schema, then calls [factory].
  ///
  /// Convenience method equivalent to [Zto.parse] with this schema.
  ///
  /// ```dart
  /// final dto = $CreateUserDtoSchema.parse(body, CreateUserDto.fromMap);
  /// ```
  T parse<T>(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>) factory,
  ) {
    Zto.validateOrThrow(descriptors, map);
    return factory(map);
  }

  /// Validates each map in [maps] with this schema, then calls [factory] for each.
  ///
  /// Convenience method equivalent to [Zto.parseList] with this schema.
  ///
  /// ```dart
  /// final dtos = $CreateUserDtoSchema.parseList(rows, CreateUserDto.fromMap);
  /// ```
  List<T> parseList<T>(
    List<Map<String, dynamic>> maps,
    T Function(Map<String, dynamic>) factory,
  ) =>
      maps.map((m) => parse<T>(m, factory)).toList();
}
