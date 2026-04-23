import '../annotations/field_annotations.dart';
import '../annotations/validator_annotations.dart';

/// Internal model of a single DTO field, built from its annotations.
class FieldDescriptor {
  const FieldDescriptor({
    required this.fieldAnnotation,
    required this.validators,
    required this.isNullable,
  });

  /// The type annotation (`@ZString`, `@ZInt`, etc.) for this field.
  final ZtoField fieldAnnotation;

  /// All validator annotations (`@ZMin`, `@ZEmail`, etc.) on this field.
  final List<ZtoValidator> validators;

  /// Whether the field is marked `@Nullable()`.
  final bool isNullable;

  /// Shorthand for the JSON key from [fieldAnnotation].
  String get key => fieldAnnotation.key;
}
