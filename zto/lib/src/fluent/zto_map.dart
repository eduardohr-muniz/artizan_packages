import '../core/zto_exception.dart';
import 'zto_rule.dart';

/// Fluent Zod-like validation map for use without code generation.
///
/// Define your schema once and reuse it across `fromMap` factories.
/// All field issues are collected before throwing.
///
/// Example:
/// ```dart
/// final _userSchema = ZtoMap({
///   'name': z.string().nullable().min(3).max(100),
///   'age':  z.int().nullable().max(120),
///   'address': z.object({
///     'street': z.string(),
///     'city': z.string(),
///   }),
/// });
///
/// factory User.fromMap(Map<String, dynamic> map) {
///   _userSchema.parse(map).refine((data) {
///     if ((data['age'] as int?) != null && (data['age'] as int) < 18) {
///       throw ZtoException(message: 'Must be 18+', issues: []);
///     }
///   });
///   return User(name: map['name'], age: map['age']);
/// }
/// ```
class ZtoMap {
  const ZtoMap(this._rules);

  final Map<String, ZtoRule> _rules;

  /// Validates [map] against all rules, collecting every issue before throwing.
  ///
  /// Throws [ZtoException] if any field fails. Returns a [ZtoMapResult] for
  /// optional further `.refine()` validation.
  ZtoMapResult parse(Map<String, dynamic> map) {
    final issues = <ZtoIssue>[];
    for (final entry in _rules.entries) {
      issues.addAll(entry.value.validate(entry.key, map[entry.key]));
    }
    if (issues.isNotEmpty) {
      throw ZtoException(message: 'Validation failed', issues: issues);
    }
    return ZtoMapResult(data: map);
  }
}

/// The result of a successful [ZtoMap.parse] call.
///
/// Use [refine] to add cross-field or business-rule validation that runs
/// after all field-level checks have passed.
class ZtoMapResult {
  ZtoMapResult({required this.data});

  /// The validated map data.
  final Map<String, dynamic> data;

  /// Runs [check] with the validated [data].
  ///
  /// [check] should throw (e.g. [ZtoException] or [Exception]) if validation
  /// fails. Returns `this` for chaining.
  ZtoMapResult refine(void Function(Map<String, dynamic> data) check) {
    check(data);
    return this;
  }
}
