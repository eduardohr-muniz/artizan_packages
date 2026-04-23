import 'package:analyzer/dart/element/element.dart';

/// Reconstructs a `@Z*` or `@ZtoValidator` annotation as a Dart source string
/// by reading the annotation's source code directly.
///
/// Used by [DtoGenerator] to embed the annotation literal inside the generated
/// `ZtoSchema` descriptor list — enabling a fully `const` schema.
abstract final class AnnotationEncoder {
  // Field type annotation names — used to classify annotations.
  static const _fieldTypes = {
    'ZString',
    'ZInt',
    'ZDouble',
    'ZNum',
    'ZBool',
    'ZDate',
    'ZFile',
    'ZEnum',
    'ZList',
    'ZListOf',
    'ZObj',
    'ZMap',
    'ZMetaData',
    'ZObject',
  };

  // Validator annotation names.
  static const _validators = {
    'ZMinLength',
    'ZMaxLength',
    'ZLength',
    'ZMin',
    'ZMax',
    'ZMultipleOf',
    'ZPattern',
    'ZStartsWith',
    'ZEndsWith',
    'ZIncludes',
    'ZEmail',
    'ZUuid',
    'ZUrl',
    'ZBase64',
    'ZHex',
    'ZIpv4',
    'ZIpv6',
    'ZHttpUrl',
    'ZJwt',
    'ZIsoDate',
    'ZIsoDateTime',
    'ZUppercase',
    'ZLowercase',
    'ZSlug',
    'ZAlphanumeric',
    'ZPositive',
    'ZNegative',
    'ZNonNegative',
    'ZNonPositive',
    'ZFinite',
    'ZSafeInt',
    'ZInteger',
  };

  /// Returns true if [annotation] is a recognised Zto field type annotation.
  static bool isFieldType(ElementAnnotation annotation) => _matchesAny(annotation, _fieldTypes);

  /// Returns true if [annotation] is a recognised Zto validator annotation.
  static bool isValidator(ElementAnnotation annotation) => _matchesAny(annotation, _validators);

  /// Encodes [annotation] into its Dart source representation (without the `@`).
  ///
  /// Returns `null` when the annotation is not a recognised Zto annotation
  /// (e.g. `@ZNullable`, `@Dto`, `@override`).
  static String? encode(ElementAnnotation annotation) {
    final source = annotation.toSource();
    if (!source.startsWith('@')) return null;
    final code = source.substring(1); // strip the leading '@'

    if (_startsWithAny(code, _fieldTypes) || _startsWithAny(code, _validators)) {
      return code;
    }
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _matchesAny(ElementAnnotation annotation, Set<String> names) {
    final source = annotation.toSource();
    if (!source.startsWith('@')) return false;
    return _startsWithAny(source.substring(1), names);
  }

  static bool _startsWithAny(String code, Set<String> names) {
    for (final name in names) {
      if (code.startsWith('$name(') || code == name) return true;
    }
    return false;
  }
}
