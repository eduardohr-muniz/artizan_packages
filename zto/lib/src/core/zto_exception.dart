import '../core/zto_schema.dart';
import '../reflection/field_descriptor.dart';
import '../validation/field_validator.dart';
import 'zto_issue.dart';

export 'zto_issue.dart';

/// A (Type|factory, ZtoSchema) pair for [Zto.registerSchemas].
///
/// Register by Type and/or by factory (fromMap, fromApi, fromJson). Schema is
/// looked up from the registry so [Zto.parse] works without passing the type.
typedef ZtoSchemaRegistration = (Object, ZtoSchema);

/// Thrown when DTO validation fails.
///
/// Contains every [ZtoIssue] collected during parsing.
class ZtoException implements Exception {
  ZtoException({required this.message, required this.issues});

  final String message;
  final List<ZtoIssue> issues;

  /// Returns the error as a Map using either [Zto.errorFormatter] (if set)
  /// or the built-in default format.
  Map<String, dynamic> toMap() {
    final formatter = Zto.errorFormatter;
    if (formatter != null) return formatter(this);
    return _defaultFormat();
  }

  /// Applies a one-off [formatter] to [issues] and returns the result.
  Map<String, dynamic> format(
    Map<String, dynamic> Function(List<ZtoIssue> issues) formatter,
  ) =>
      formatter(issues);

  Map<String, dynamic> _defaultFormat() => {
        'statusCode': 422,
        'message': message,
        'errors': issues.map((i) => i.toMap()).toList(),
      };

  @override
  String toString() => 'ZtoException: $message (${issues.length} issue(s))';
}

/// Main entry point for the `zto` package.
///
/// ## Parsing a single object (with validation)
///
/// ```dart
/// final dto = Zto.parse(body, CreateUserDto.fromMap);
/// ```
///
/// The schema is auto-registered by `zto_generator` when you run `build_runner`.
///
/// ## Parsing a list
///
/// ```dart
/// final users = Zto.parseList(rows, CreateUserDto.fromMap);
/// ```
///
/// ## Chaining refine (requires the class to use `with ZtoDto<T>`)
///
/// ```dart
/// final dto = Zto.parse(body, CreateUserDto.fromMap)
///     .refine((d) => d.age >= 18, message: 'Must be adult');
/// ```
///
/// ## Custom error formatting
///
/// ```dart
/// Zto.errorFormatter = (e) => {
///   'code': 'VALIDATION_ERROR',
///   'errors': e.issues.map((i) => i.toMap()).toList(),
/// };
/// ```
abstract final class Zto {
  // ── Error formatting ──────────────────────────────────────────────────────

  /// Optional global error formatter used by [ZtoException.toMap()].
  ///
  /// When set, every [ZtoException.toMap()] call uses this formatter instead
  /// of the built-in default (`{statusCode, message, errors}`).
  static Map<String, dynamic> Function(ZtoException)? errorFormatter;

  /// Resets [errorFormatter] to `null` (restores the built-in default format).
  static void resetErrorFormatter() => errorFormatter = null;

  // ── Schema registry ──────────────────────────────────────────────────────

  static final Map<Object, ZtoSchema> _schemaRegistry = {};

  /// Registers [schema] for [key] (Type or factory). Call in app init so [parse]
  /// can validate without passing the schema. Use any factory: fromMap, fromApi, etc.
  static bool registerSchema(Object key, ZtoSchema schema) {
    _schemaRegistry[key] = schema;
    return true;
  }

  /// Returns the registered schema for [key] (Type or factory).
  static ZtoSchema? getSchema(Object key) => _schemaRegistry[key];

  /// Registers all schemas from [registrations].
  static void registerSchemas(List<ZtoSchemaRegistration> registrations) {
    for (final (key, schema) in registrations) {
      registerSchema(key, schema);
    }
  }

  // ── Validation helper ─────────────────────────────────────────────────────

  /// Validates [map] against [descriptors], collecting all field issues.
  ///
  /// Throws [ZtoException] if any field fails validation. Called internally by
  /// [parse] and [parseList] when a [schema] is provided.
  static void validateOrThrow(
    List<FieldDescriptor> descriptors,
    Map<String, dynamic> map,
  ) {
    final issues = <ZtoIssue>[];
    for (final d in descriptors) {
      issues.addAll(FieldValidator.validate(d, map[d.key]));
    }
    if (issues.isNotEmpty) {
      throw ZtoException(message: 'Validation failed', issues: issues);
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  /// Validates [map] with the provided [schema], then calls [factory].
  ///
  /// The schema is required and must be provided explicitly.
  ///
  /// ```dart
  /// final dto = Zto.parse(body, CreateUserDto.fromMap, schema: $CreateUserDtoSchema);
  /// ```
  static T parse<T>(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>) factory, {
    required ZtoSchema schema,
  }) {
    validateOrThrow(schema.descriptors, map);
    return factory(map);
  }

  /// Parses every map in [maps] using [factory]. Validates each with the provided [schema].
  ///
  /// ```dart
  /// final users = Zto.parseList(rows, CreateUserDto.fromMap, schema: $CreateUserDtoSchema);
  /// ```
  static List<T> parseList<T>(
    List<Map<String, dynamic>> maps,
    T Function(Map<String, dynamic>) factory, {
    required ZtoSchema schema,
  }) =>
      maps.map((m) => parse<T>(m, factory, schema: schema)).toList();
}
