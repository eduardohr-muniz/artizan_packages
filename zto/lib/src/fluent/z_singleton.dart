import 'zto_rule.dart';

/// Global singleton providing factory methods for fluent [ZtoRule] builders.
///
/// Use `z` to build field rules for [ZtoMap] schemas:
///
/// ```dart
/// final schema = ZtoMap({
///   'name':    z.string().min(2).max(100),
///   'age':     z.int().nullable().max(120),
///   'active':  z.bool(),
///   'address': z.object({
///     'street': z.string(),
///     'city':   z.string(),
///   }),
/// });
/// ```
const z = _Z._();

class _Z {
  const _Z._();

  /// A string field rule. Chain `.nullable()`, `.min()`, `.max()`, `.email()`.
  ZtoStringRule string() => ZtoStringRule();

  /// An integer field rule. Chain `.nullable()`, `.min()`, `.max()`.
  ZtoIntRule int() => ZtoIntRule();

  /// A double/num field rule. Chain `.nullable()`, `.min()`, `.max()`.
  ZtoDoubleRule double() => ZtoDoubleRule();

  /// A boolean field rule. Chain `.nullable()`.
  ZtoBoolRule bool() => ZtoBoolRule();

  /// A nested object rule with its own [shape] of rules.
  /// Chain `.nullable()`.
  ZtoObjectRule object(Map<String, ZtoRule> shape) => ZtoObjectRule(shape);
}
