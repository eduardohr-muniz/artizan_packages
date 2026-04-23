import 'dart:convert';

import '../annotations/field_annotations.dart';
import '../annotations/validator_annotations.dart';
import '../core/zto_dto.dart';
import '../core/zto_exception.dart';
import '../core/zto_issue.dart';
import '../core/zto_schema.dart';
import '../reflection/field_descriptor.dart';

/// Validates a single field value against its [FieldDescriptor].
///
/// Returns a (possibly empty) list of [ZtoIssue]s — never throws.
/// For [ZObj] fields, validates nested objects recursively.
abstract final class FieldValidator {
  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  static final _isoDateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _hexRegex = RegExp(r'^[0-9a-fA-F]+$');
  static final _ipv4Regex = RegExp(
    r'^((25[0-5]|2[0-4]\d|1?\d{1,2})\.){3}(25[0-5]|2[0-4]\d|1?\d{1,2})$',
  );
  static final _ipv6Regex = RegExp(
    r'^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]+)$',
  );

  static List<ZtoIssue> validate(FieldDescriptor descriptor, dynamic value) {
    final key = descriptor.key;

    if (value == null) {
      if (descriptor.isNullable) return const [];
      return [ZtoIssue(message: '"$key" is required', field: key)];
    }

    final typeIssue = _checkType(descriptor.fieldAnnotation, value, key);
    if (typeIssue != null) return [typeIssue];

    final issues = <ZtoIssue>[];
    for (final v in descriptor.validators) {
      final issue = _runValidator(v, value, key);
      if (issue != null) issues.add(issue);
    }

    if (descriptor.fieldAnnotation is ZObj && value is Map<String, dynamic>) {
      final obj = descriptor.fieldAnnotation as ZObj;
      final schema = obj.dtoSchema ?? (obj.dtoType != null ? Zto.getSchema(obj.dtoType!) : null);
      if (schema != null) {
        issues.addAll(_validateNested(key, schema as ZtoSchema, value));
      }
    }

    if (descriptor.fieldAnnotation is ZListOf && value is List) {
      final listOf = descriptor.fieldAnnotation as ZListOf;
      final schema = listOf.dtoSchema ?? (listOf.dtoType != null ? Zto.getSchema(listOf.dtoType!) : null);

      if (schema != null) {
        final List list = value;
        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is! Map<String, dynamic>) {
            issues.add(ZtoIssue(
              message: '"$key.$i" must be an object (got ${item.runtimeType})',
              field: '$key.$i',
            ));
            continue;
          }
          issues.addAll(_validateNested('$key.$i', schema as ZtoSchema, item));
        }
      }
    }

    return issues;
  }

  static List<ZtoIssue> _validateNested(String prefix, ZtoSchema schema, Map<String, dynamic> map) {
    final issues = <ZtoIssue>[];
    for (final d in schema.descriptors) {
      final nestedIssues = validate(d, map[d.key]);
      for (final i in nestedIssues) {
        issues.add(ZtoIssue(
          message: i.message,
          field: i.field != null ? '$prefix.${i.field}' : prefix,
        ));
      }
    }
    return issues;
  }

  static bool _isValidBase64(String s) {
    try {
      base64Decode(s);
      return true;
    } on FormatException {
      return false;
    }
  }

  static ZtoIssue? _checkType(ZtoField annotation, dynamic value, String key) {
    final ok = switch (annotation) {
      ZString() => value is String,
      ZInt() => value is int,
      ZDouble() => value is num,
      ZNum() => value is num,
      ZBool() => value is bool,
      ZDate() => value is String || value is DateTime,
      ZFile() => true,
      ZEnum(:final values) => value is String && values.contains(value),
      ZList() => value is List,
      ZListOf() => value is List,
      ZObj() => value is Map,
      ZMap() => value is Map,
      ZMetaData() => value is Map,
      _ => true,
    };

    if (ok) return null;

    final defaultMessage = switch (annotation) {
      ZString() => '"$key" must be a string (got ${value.runtimeType})',
      ZInt() => '"$key" must be an integer (got ${value.runtimeType})',
      ZDouble() => '"$key" must be a number (got ${value.runtimeType})',
      ZNum() => '"$key" must be a number (got ${value.runtimeType})',
      ZBool() => '"$key" must be a boolean (got ${value.runtimeType})',
      ZDate() => '"$key" must be a date-time (got ${value.runtimeType})',
      ZEnum(:final values) => '"$key" must be one of [${values.join(', ')}] (got ${value.runtimeType})',
      ZList() => '"$key" must be an array (got ${value.runtimeType})',
      ZListOf() => '"$key" must be an array (got ${value.runtimeType})',
      ZObj() => '"$key" must be an object (got ${value.runtimeType})',
      ZMap() => '"$key" must be a map (got ${value.runtimeType})',
      ZMetaData() => '"$key" must be a map (got ${value.runtimeType})',
      _ => '"$key" must be a valid value (got ${value.runtimeType})',
    };

    return ZtoIssue(
      message: annotation.failMessage ?? defaultMessage,
      field: key,
    );
  }

  static ZtoIssue? _runValidator(ZtoValidator v, dynamic value, String key) {
    return switch (v) {
      ZMinLength(:final n, :final message) => value is String && value.length < n
          ? ZtoIssue(
              message: message ?? '"$key" must be at least $n characters',
              field: key,
            )
          : null,
      ZMaxLength(:final n, :final message) => value is String && value.length > n
          ? ZtoIssue(
              message: message ?? '"$key" must be at most $n characters',
              field: key,
            )
          : null,
      ZLength(:final n, :final message) => value is String && value.length != n
          ? ZtoIssue(
              message: message ?? '"$key" must be exactly $n characters',
              field: key,
            )
          : null,
      ZEmail(:final message) =>
        value is String && !_emailRegex.hasMatch(value) ? ZtoIssue(message: message ?? '"$key" must be a valid email', field: key) : null,
      ZUuid(:final message) =>
        value is String && !_uuidRegex.hasMatch(value.toLowerCase()) ? ZtoIssue(message: message ?? '"$key" must be a valid UUID', field: key) : null,
      ZUrl(:final message) =>
        value is String && Uri.tryParse(value)?.hasScheme != true ? ZtoIssue(message: message ?? '"$key" must be a valid URL', field: key) : null,
      ZPattern(:final regex, :final message) => value is String && !RegExp(regex).hasMatch(value)
          ? ZtoIssue(
              message: message ?? '"$key" must match pattern $regex',
              field: key,
            )
          : null,
      ZStartsWith(:final prefix, :final message) => value is String && !value.startsWith(prefix)
          ? ZtoIssue(
              message: message ?? '"$key" must start with "$prefix"',
              field: key,
            )
          : null,
      ZEndsWith(:final suffix, :final message) => value is String && !value.endsWith(suffix)
          ? ZtoIssue(
              message: message ?? '"$key" must end with "$suffix"',
              field: key,
            )
          : null,
      ZIncludes(:final substring, :final message) => value is String && !value.contains(substring)
          ? ZtoIssue(
              message: message ?? '"$key" must contain "$substring"',
              field: key,
            )
          : null,
      ZBase64(:final message) =>
        value is String && !_isValidBase64(value) ? ZtoIssue(message: message ?? '"$key" must be valid Base64', field: key) : null,
      ZHex(:final message) =>
        value is String && !_hexRegex.hasMatch(value) ? ZtoIssue(message: message ?? '"$key" must be valid hexadecimal', field: key) : null,
      ZIpv4(:final message) =>
        value is String && !_ipv4Regex.hasMatch(value) ? ZtoIssue(message: message ?? '"$key" must be a valid IPv4 address', field: key) : null,
      ZIpv6(:final message) =>
        value is String && !_ipv6Regex.hasMatch(value) ? ZtoIssue(message: message ?? '"$key" must be a valid IPv6 address', field: key) : null,
      ZHttpUrl(:final message) => () {
          if (value is! String) return null;
          final uri = Uri.tryParse(value);
          final ok = uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasScheme;
          return ok
              ? null
              : ZtoIssue(
                  message: message ?? '"$key" must be a valid HTTP or HTTPS URL',
                  field: key,
                );
        }(),
      ZJwt(:final message) => () {
          if (value is! String) return null;
          final parts = value.split('.');
          final invalid = parts.length != 3 || parts.any((p) => p.isEmpty);
          return invalid ? ZtoIssue(message: message ?? '"$key" must be a valid JWT', field: key) : null;
        }(),
      ZIsoDate(:final message) => () {
          if (value is! String) return null;
          final p = DateTime.tryParse(value);
          final ok = _isoDateRegex.hasMatch(value) && p != null && p.toIso8601String().startsWith(value);
          return ok
              ? null
              : ZtoIssue(
                  message: message ?? '"$key" must be a valid ISO date (YYYY-MM-DD)',
                  field: key,
                );
        }(),
      ZIsoDateTime(:final message) => value is String && (!value.contains('T') || DateTime.tryParse(value) == null)
          ? ZtoIssue(
              message: message ?? '"$key" must be a valid ISO 8601 datetime',
              field: key,
            )
          : null,
      ZMin(:final n, :final message) => value is num && value < n ? ZtoIssue(message: message ?? '"$key" must be >= $n', field: key) : null,
      ZMax(:final n, :final message) => value is num && value > n ? ZtoIssue(message: message ?? '"$key" must be <= $n', field: key) : null,
      ZPositive(:final message) => value is num && value <= 0 ? ZtoIssue(message: message ?? '"$key" must be positive', field: key) : null,
      ZNegative(:final message) => value is num && value >= 0 ? ZtoIssue(message: message ?? '"$key" must be negative', field: key) : null,
      ZMultipleOf(:final n, :final message) =>
        value is num && value % n != 0 ? ZtoIssue(message: message ?? '"$key" must be a multiple of $n', field: key) : null,
      ZInteger(:final message) =>
        value is num && value != value.truncateToDouble() ? ZtoIssue(message: message ?? '"$key" must be an integer', field: key) : null,
      ZNonNegative(:final message) => value is num && value < 0 ? ZtoIssue(message: message ?? '"$key" must be >= 0', field: key) : null,
      ZNonPositive(:final message) => value is num && value > 0 ? ZtoIssue(message: message ?? '"$key" must be <= 0', field: key) : null,
      ZFinite(:final message) => value is num && (value == double.infinity || value == double.negativeInfinity || value != value)
          ? ZtoIssue(message: message ?? '"$key" must be finite', field: key)
          : null,
      ZSafeInt(:final message) => value is num && (value < -9007199254740991 || value > 9007199254740991 || value != value.truncateToDouble())
          ? ZtoIssue(
              message: message ?? '"$key" must be a safe integer',
              field: key,
            )
          : null,
      ZUppercase(:final message) =>
        value is String && value != value.toUpperCase() ? ZtoIssue(message: message ?? '"$key" must be uppercase', field: key) : null,
      ZLowercase(:final message) =>
        value is String && value != value.toLowerCase() ? ZtoIssue(message: message ?? '"$key" must be lowercase', field: key) : null,
      ZSlug(:final message) => value is String && !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)
          ? ZtoIssue(message: message ?? '"$key" must be a valid slug', field: key)
          : null,
      ZAlphanumeric(:final message) => value is String && !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)
          ? ZtoIssue(message: message ?? '"$key" must be alphanumeric', field: key)
          : null,
      _ => null,
    };
  }
}
