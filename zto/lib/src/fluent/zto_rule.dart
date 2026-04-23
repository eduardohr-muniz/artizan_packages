import '../core/zto_issue.dart';

/// Abstract base for fluent validation rules used with [ZtoMap].
abstract class ZtoRule {
  /// Validates [value] for the field named [key].
  ///
  /// Returns a (possibly empty) list of [ZtoIssue]s — never throws.
  List<ZtoIssue> validate(String key, dynamic value);
}

// ── String ─────────────────────────────────────────────────────────────────

class ZtoStringRule extends ZtoRule {
  ZtoStringRule._({
    bool nullable = false,
    int? min,
    int? max,
    bool email = false,
    RegExp? pattern,
  })  : _nullable = nullable,
        _min = min,
        _max = max,
        _email = email,
        _pattern = pattern;

  ZtoStringRule() : this._();

  final bool _nullable;
  final int? _min;
  final int? _max;
  final bool _email;
  final RegExp? _pattern;

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  ZtoStringRule nullable() => ZtoStringRule._(nullable: true, min: _min, max: _max, email: _email, pattern: _pattern);
  ZtoStringRule min(int n) => ZtoStringRule._(nullable: _nullable, min: n, max: _max, email: _email, pattern: _pattern);
  ZtoStringRule max(int n) => ZtoStringRule._(nullable: _nullable, min: _min, max: n, email: _email, pattern: _pattern);
  ZtoStringRule email() => ZtoStringRule._(nullable: _nullable, min: _min, max: _max, email: true, pattern: _pattern);
  ZtoStringRule matches(RegExp regex) => ZtoStringRule._(nullable: _nullable, min: _min, max: _max, email: _email, pattern: regex);

  @override
  List<ZtoIssue> validate(String key, dynamic value) {
    if (value == null) {
      if (_nullable) return const [];
      return [ZtoIssue(message: '"$key" is required', field: key)];
    }
    if (value is! String) {
      return [ZtoIssue(message: '"$key" must be a string (got ${value.runtimeType})', field: key)];
    }
    final issues = <ZtoIssue>[];
    if (_min != null && value.length < _min) {
      issues.add(ZtoIssue(message: '"$key" must be at least $_min characters', field: key));
    }
    if (_max != null && value.length > _max) {
      issues.add(ZtoIssue(message: '"$key" must be at most $_max characters', field: key));
    }
    if (_email && !_emailRegex.hasMatch(value)) {
      issues.add(ZtoIssue(message: '"$key" must be a valid email', field: key));
    }
    if (_pattern != null && !_pattern.hasMatch(value)) {
      issues.add(ZtoIssue(message: '"$key" must match pattern ${_pattern.pattern}', field: key));
    }
    return issues;
  }
}

// ── Int ────────────────────────────────────────────────────────────────────

class ZtoIntRule extends ZtoRule {
  ZtoIntRule._({bool nullable = false, num? min, num? max})
      : _nullable = nullable,
        _min = min,
        _max = max;

  ZtoIntRule() : this._();

  final bool _nullable;
  final num? _min;
  final num? _max;

  ZtoIntRule nullable() => ZtoIntRule._(nullable: true, min: _min, max: _max);
  ZtoIntRule min(num n) => ZtoIntRule._(nullable: _nullable, min: n, max: _max);
  ZtoIntRule max(num n) => ZtoIntRule._(nullable: _nullable, min: _min, max: n);

  @override
  List<ZtoIssue> validate(String key, dynamic value) {
    if (value == null) {
      if (_nullable) return const [];
      return [ZtoIssue(message: '"$key" is required', field: key)];
    }
    if (value is! int) {
      return [ZtoIssue(message: '"$key" must be an integer (got ${value.runtimeType})', field: key)];
    }
    final issues = <ZtoIssue>[];
    if (_min != null && value < _min) issues.add(ZtoIssue(message: '"$key" must be >= $_min', field: key));
    if (_max != null && value > _max) issues.add(ZtoIssue(message: '"$key" must be <= $_max', field: key));
    return issues;
  }
}

// ── Double ─────────────────────────────────────────────────────────────────

class ZtoDoubleRule extends ZtoRule {
  ZtoDoubleRule._({bool nullable = false, num? min, num? max})
      : _nullable = nullable,
        _min = min,
        _max = max;

  ZtoDoubleRule() : this._();

  final bool _nullable;
  final num? _min;
  final num? _max;

  ZtoDoubleRule nullable() => ZtoDoubleRule._(nullable: true, min: _min, max: _max);
  ZtoDoubleRule min(num n) => ZtoDoubleRule._(nullable: _nullable, min: n, max: _max);
  ZtoDoubleRule max(num n) => ZtoDoubleRule._(nullable: _nullable, min: _min, max: n);

  @override
  List<ZtoIssue> validate(String key, dynamic value) {
    if (value == null) {
      if (_nullable) return const [];
      return [ZtoIssue(message: '"$key" is required', field: key)];
    }
    if (value is! num) {
      return [ZtoIssue(message: '"$key" must be a number (got ${value.runtimeType})', field: key)];
    }
    final issues = <ZtoIssue>[];
    if (_min != null && value < _min) issues.add(ZtoIssue(message: '"$key" must be >= $_min', field: key));
    if (_max != null && value > _max) issues.add(ZtoIssue(message: '"$key" must be <= $_max', field: key));
    return issues;
  }
}

// ── Bool ───────────────────────────────────────────────────────────────────

class ZtoBoolRule extends ZtoRule {
  ZtoBoolRule._({bool nullable = false}) : _nullable = nullable;
  ZtoBoolRule() : this._();

  final bool _nullable;

  ZtoBoolRule nullable() => ZtoBoolRule._(nullable: true);

  @override
  List<ZtoIssue> validate(String key, dynamic value) {
    if (value == null) {
      if (_nullable) return const [];
      return [ZtoIssue(message: '"$key" is required', field: key)];
    }
    if (value is! bool) {
      return [ZtoIssue(message: '"$key" must be a boolean (got ${value.runtimeType})', field: key)];
    }
    return const [];
  }
}

// ── Object ─────────────────────────────────────────────────────────────────

class ZtoObjectRule extends ZtoRule {
  ZtoObjectRule(this._shape, {bool nullable = false}) : _nullable = nullable;

  final Map<String, ZtoRule> _shape;
  final bool _nullable;

  ZtoObjectRule nullable() => ZtoObjectRule(_shape, nullable: true);

  @override
  List<ZtoIssue> validate(String key, dynamic value) {
    if (value == null) {
      if (_nullable) return const [];
      return [ZtoIssue(message: '"$key" is required', field: key)];
    }
    if (value is! Map<String, dynamic>) {
      return [ZtoIssue(message: '"$key" must be an object (got ${value.runtimeType})', field: key)];
    }
    final issues = <ZtoIssue>[];
    for (final entry in _shape.entries) {
      issues.addAll(entry.value.validate('$key.${entry.key}', value[entry.key]));
    }
    return issues;
  }
}
