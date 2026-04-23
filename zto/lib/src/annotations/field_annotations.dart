/// Abstract base for generated DTO schema objects.
///
/// Defined here (rather than in `zto_schema.dart`) to avoid a circular
/// dependency: `field_annotations.dart` <- `field_descriptor.dart` <-
/// `zto_schema.dart`. Concrete implementation is [ZtoSchema].
abstract class ZtoSchemaBase {
  const ZtoSchemaBase();

  /// The class name of the DTO (e.g. `'CreateUserDto'`).
  String get typeName;
}

/// Defines how Dart field names are converted to JSON map keys
/// when no explicit [ZtoField.mapKey] is provided.
enum ParseType {
  /// No transformation — Dart field name is used as-is (e.g. `myField` -> `myField`).
  camelCase,

  /// Converts camelCase to snake_case (e.g. `myField` -> `my_field`).
  snakeCase,

  /// Uppercases the first letter (e.g. `myField` -> `MyField`).
  pascalCase,

  /// Converts camelCase to kebab-case (e.g. `myField` -> `my-field`).
  kebabCase,
}

/// Base class for all Zto field type annotations.
///
/// All parameters are named. Provide [mapKey] to explicitly set the JSON key,
/// or omit it so the generator can infer it from the field name and the DTO's
/// [ParseType]. When neither is provided, [key] returns an empty string.
abstract class ZtoField {
  const ZtoField({this.mapKey, this.description, this.example, this.failMessage, this.deprecated = false});

  /// Explicit JSON map key for this field. Takes precedence over inference.
  final String? mapKey;

  /// Description shown in OpenAPI / Swagger UI.
  final String? description;

  /// Example value shown in OpenAPI / Swagger UI.
  final Object? example;

  /// Custom message when type validation fails. If null, a default is used.
  final String? failMessage;

  /// Marks this field as deprecated in the OpenAPI schema.
  final bool deprecated;

  /// The resolved JSON map key — [mapKey] if set, otherwise `''`.
  String get key => mapKey ?? '';
}

class ZString extends ZtoField {
  /// Marks a field as a JSON string.
  ///
  /// The value must be a [String] at runtime.
  ///
  /// Example:
  /// ```dart
  /// @ZString(description: 'Full name', example: 'Alice')
  /// @ZMinLength(2)
  /// @ZMaxLength(100)
  /// final String name;
  /// ```
  ///
  /// Available validators:
  ///
  /// ```dart
  /// @ZMinLength(3)   // 'abc' -> passed | 'ab' -> fail
  /// @ZMaxLength(10)  // 'hello' -> passed | 'hello world!' -> fail
  /// @ZLength(5)      // '12345' -> passed | '1234', '123456' -> fail
  /// @ZEmail()        // 'a@b.com' -> passed | 'invalid' -> fail
  /// @ZUuid()         // '550e8400-e29b-41d4-a716-446655440000' -> passed | 'x' -> fail
  /// @ZUrl()          // 'https://example.com' -> passed | 'not-a-url' -> fail
  /// @ZPattern(r'^[a-z]+$')  // 'abc' -> passed | 'Abc' -> fail
  /// @ZStartsWith('https://') // 'https://x.com' -> passed | 'http://x.com' -> fail
  /// @ZEndsWith('.com')      // 'site.com' -> passed | 'site.org' -> fail
  /// @ZIncludes('foo')       // 'hello foo' -> passed | 'hello bar' -> fail
  /// @ZBase64()       // 'SGVsbG8=' -> passed | '!!!' -> fail
  /// @ZHex()          // 'deadbeef' -> passed | 'ghijk' -> fail
  /// @ZIpv4()         // '192.168.1.1' -> passed | '256.1.1.1' -> fail
  /// @ZIpv6()         // '2001:0db8::1' -> passed | 'invalid' -> fail
  /// @ZHttpUrl()      // 'https://x.com' -> passed | 'ftp://x.com' -> fail
  /// @ZJwt()          // 'a.b.c' -> passed | 'a.b' -> fail
  /// @ZIsoDate()      // '2024-03-15' -> passed | '2024-13-01' -> fail
  /// @ZIsoDateTime()  // '2024-03-15T10:00:00Z' -> passed | '2024-03-15' -> fail
  /// @ZUppercase()    // 'ABC' -> passed | 'Abc' -> fail
  /// @ZLowercase()    // 'abc' -> passed | 'Abc' -> fail
  /// @ZSlug()         // 'my-blog-post' -> passed | 'Invalid Slug!' -> fail
  /// @ZAlphanumeric() // 'abc123' -> passed | 'abc-123' -> fail
  /// ```
  const ZString({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

class ZInt extends ZtoField {
  /// Marks a field as a JSON integer.
  ///
  /// The value must be an [int] at runtime.
  ///
  /// Example:
  /// ```dart
  /// @ZInt(description: 'Age in years', example: 25)
  /// @ZMin(18)
  /// @ZMax(120)
  /// final int age;
  /// ```
  ///
  /// Available validators:
  ///
  /// ```dart
  /// @ZMin(18)        // 18, 25 -> passed | 17 -> fail
  /// @ZMax(120)       // 100, 120 -> passed | 121 -> fail
  /// @ZPositive()     // 1 -> passed | 0, -1 -> fail
  /// @ZNegative()    // -5 -> passed | 5 -> fail
  /// @ZNonNegative()  // 0, 1 -> passed | -1 -> fail
  /// @ZNonPositive() // 0, -5 -> passed | 1 -> fail
  /// @ZMultipleOf(5)  // 10, 15 -> passed | 12 -> fail
  /// @ZInteger()      // 10 -> passed | 9.99 -> fail
  /// @ZFinite()       // 42 -> passed | infinity, nan -> fail
  /// @ZSafeInt()      // 9007199254740991 -> passed | 9007199254740992 -> fail
  /// ```
  const ZInt({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

class ZDouble extends ZtoField {
  /// Marks a field as a JSON floating-point number (double).
  ///
  /// The value must be a [num] at runtime (int or double).
  ///
  /// Example:
  /// ```dart
  /// @ZDouble(description: 'Unit price', example: 9.99)
  /// @ZPositive()
  /// @ZFinite()
  /// final double price;
  /// ```
  ///
  /// Available validators: same as [ZInt].
  const ZDouble({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

class ZNum extends ZtoField {
  /// Marks a field as a JSON number (int or double).
  ///
  /// Accepts both integer and floating-point values.
  ///
  /// Example:
  /// ```dart
  /// @ZNum(description: 'Numeric score')
  /// @ZMin(0)
  /// @ZMax(100)
  /// final num score;
  /// ```
  ///
  /// Available validators: same as [ZInt].
  const ZNum({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

class ZBool extends ZtoField {
  /// Marks a field as a JSON boolean.
  ///
  /// The value must be a [bool] at runtime. No validators available.
  ///
  /// Example:
  /// ```dart
  /// @ZBool(description: 'Whether the item is active')
  /// final bool active;
  /// ```
  const ZBool({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

class ZMap extends ZtoField {
  /// Marks a field as a JSON object (map).
  ///
  /// The value must be a [Map] at runtime. No validators available.
  ///
  /// Example:
  /// ```dart
  /// @ZMap(description: 'Additional metadata')
  /// final Map<String, dynamic> metadata;
  /// ```
  const ZMap({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

class ZDate extends ZtoField {
  /// Marks a field as a date-time value.
  ///
  /// In JSON this is typically an ISO 8601 string. At runtime accepts
  /// [String] or [DateTime].
  ///
  /// Example:
  /// ```dart
  /// @ZDate(description: 'Creation timestamp')
  /// final DateTime createdAt;
  /// ```
  ///
  /// Available validators:
  ///
  /// ```dart
  /// @ZMin(timestamp)  // date >= min -> passed | date < min -> fail
  /// @ZMax(timestamp)  // date <= max -> passed | date > max -> fail
  /// ```
  const ZDate({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

class ZFile extends ZtoField {
  /// Marks a field as a binary file upload (multipart).
  ///
  /// No validators available.
  ///
  /// Example:
  /// ```dart
  /// @ZFile(description: 'Profile image')
  /// final dynamic avatar;
  /// ```
  const ZFile({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

class ZEnum<T> extends ZtoField {
  /// Marks a field as a string enum with allowed [values].
  ///
  /// The value must be one of the strings in [values]. No validators available.
  ///
  /// Example:
  /// ```dart
  /// @ZEnum(values: ['admin', 'editor', 'viewer'])
  /// final String role;
  /// ```
  const ZEnum({required this.values, super.mapKey, super.description, super.example, super.failMessage, super.deprecated});

  /// The list of allowed string values.
  final List<T> values;
}

class ZList extends ZtoField {
  /// Marks a field as an array whose items match [itemType].
  ///
  /// [itemType] must be a [ZtoField] type (e.g. [ZString], [ZInt]).
  /// No validators available.
  ///
  /// Example:
  /// ```dart
  /// @ZList(itemType: ZString, description: 'List of tags')
  /// final List<String> tags;
  /// ```
  const ZList({required this.itemType, super.mapKey, super.description, super.example, super.failMessage, super.deprecated});

  /// The [ZtoField] type of each item in the list.
  final Type itemType;
}

class ZListOf extends ZtoField {
  /// Marks a field as an array of nested DTO objects.
  ///
  /// Provide either [dtoSchema] (the generated schema object) or [dtoType]
  /// (the DTO class type itself, which must be registered with [Zto.registerSchemas]).
  ///
  /// Each item in the list is validated recursively.
  ///
  /// Example:
  /// ```dart
  /// @ZListOf(dtoType: AddressDto)
  /// final List<AddressDto> addresses;
  /// ```
  const ZListOf({this.dtoSchema, this.dtoType, super.mapKey, super.description, super.example, super.failMessage, super.deprecated});

  /// The [ZtoSchemaBase] for each item in the list.
  final ZtoSchemaBase? dtoSchema;

  /// The DTO class type for each item. If provided, the schema will be looked
  /// up from the [Zto] registry.
  final Type? dtoType;
}

class ZObj extends ZtoField {
  /// Marks a field as a nested DTO object.
  ///
  /// Provide either [dtoSchema] (the generated schema object) or [dtoType]
  /// (the DTO class type itself, which must be registered with [Zto.registerSchemas]).
  ///
  /// Example:
  /// ```dart
  /// @ZObj(dtoType: AddressDto)
  /// final AddressDto address;
  /// ```
  const ZObj({this.dtoSchema, this.dtoType, super.mapKey, super.description, super.example, super.failMessage, super.deprecated});

  /// The [ZtoSchemaBase] for the nested object.
  final ZtoSchemaBase? dtoSchema;

  /// The DTO class type. If provided, the schema will be looked up from
  /// the [Zto] registry.
  final Type? dtoType;
}

class ZMetaData extends ZtoField {
  /// Marks a field as a free-form metadata map (`Map<String, dynamic>`).
  ///
  /// Use this for arbitrary key-value metadata. No validators available.
  ///
  /// Example:
  /// ```dart
  /// @ZMetaData(description: 'User metadata', example: {'plan': 'pro'})
  /// final Map<String, dynamic> metaData;
  /// ```
  const ZMetaData({super.mapKey, super.description, super.example, super.failMessage, super.deprecated});
}

/// Annotation for nested DTO object fields.
///
/// Unlike [ZObj], you do NOT need to pass [dtoType] or [dtoSchema] — the
/// generator infers the type from the Dart field declaration.
/// The map key is inferred from the field name and the DTO's [ParseType],
/// or override it with [mapKey].
///
/// Example:
/// ```dart
/// @ZObject(description: 'User address')
/// final AddressDto address;
/// ```
class ZObject {
  const ZObject({this.description, this.mapKey});

  final String? description;
  final String? mapKey;
}

/// Marks a field as nullable and optional.
///
/// A `@ZNullable()` field may be absent from the request body or explicitly
/// null — both are treated identically.
///
/// Example:
/// ```dart
/// @ZString(description: 'Nickname')
/// @ZNullable()
/// final String? nickname;
/// ```
@Deprecated('Nullability is now inferred from Dart\'s ? type suffix. Remove this annotation.')
class ZNullable {
  const ZNullable();
}

/// @deprecated Use [ZNullable] instead.
@Deprecated('Use @ZNullable()')
class Nullable {
  const Nullable();
}

/// Marks a class as a Zto DTO with optional [parseType] for key inference.
///
/// [description] is shown in OpenAPI / Swagger UI. [parseType] controls how
/// Dart field names are mapped to JSON keys when no explicit [ZtoField.mapKey]
/// is given. Defaults to [ParseType.camelCase] (no transformation).
///
/// Example:
/// ```dart
/// @ZDto(description: 'Create user request', parseType: ParseType.snakeCase)
/// class CreateUserDto with ZtoDto<CreateUserDto> { ... }
/// ```
class ZDto {
  const ZDto({required this.description, this.parseType = ParseType.camelCase, this.deprecated = false});

  final String description;
  final ParseType parseType;
  final bool deprecated;
}

/// Marks a class as a Zto Entity. Semantically equivalent to [ZDto].
///
/// Use [ZEntity] for domain entities and [ZDto] for data transfer objects.
///
/// Example:
/// ```dart
/// @ZEntity(description: 'User entity', parseType: ParseType.snakeCase)
/// class UserEntity with ZtoDto<UserEntity> { ... }
/// ```
class ZEntity {
  const ZEntity({required this.description, this.parseType = ParseType.camelCase, this.deprecated = false});

  final String description;
  final ParseType parseType;
  final bool deprecated;
}

/// @deprecated Use [@ZDto] instead.
@Deprecated('Use @ZDto()')
class Dto {
  const Dto({required this.description, this.deprecated = false});

  final String description;
  final bool deprecated;
}

/// Lists DTO classes to include in generated `$ZtoSchemas` for [Zto.registerSchemas].
///
/// Only DTOs with [fromMap] are registered. Use in a file with `part 'x.g.dart';`.
///
/// Example:
/// ```dart
/// @ZtoGenerateSchemas([CreateUserDto, UpdateUserDto])
/// const _ztoSchemas = null;
/// ```
class ZtoGenerateSchemas {
  const ZtoGenerateSchemas([this.dtos = const []]);

  /// DTO classes to register. If empty, auto-discovers from library imports.
  final List<Type> dtos;
}

/// @deprecated Use [ZtoGenerateSchemas] instead.
@Deprecated('Use @ZtoGenerateSchemas([...]) with library; part "x.g.dart";')
class ZtoDtos {
  const ZtoDtos({required this.dtos});

  final List<Type> dtos;
}
