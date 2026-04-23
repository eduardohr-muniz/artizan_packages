import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zto/zto.dart';

import 'annotation_encoder.dart';
import 'validator_compatibility.dart';

/// Shared logic to generate ZtoSchema for a [@ZDto], [@ZEntity], or [@Dto] class.
///
/// When [includeRegistration] is true, emits a `final _ztoReg...` line for
/// DTOs with `fromMap`. Set to false when using [Zto.registerSchemas].
String generateSchemaForClass(ClassElement classElement, {bool includeRegistration = true}) {
  final className = classElement.name;
  final schemaName = '\$${className}Schema';
  final parseType = _getParseType(classElement);

  final fields = _annotatedFields(classElement);
  final descriptors = fields.map((f) => _buildDescriptor(f, classElement, parseType)).join(',\n    ');

  final hasFromMap = classElement.constructors.any((c) => c.name == 'fromMap');

  final registration = (includeRegistration && hasFromMap)
      ? '''
final _ztoReg$className = Zto.registerSchema($className.fromMap, $schemaName);
final _ztoRegType$className = Zto.registerSchema($className, $schemaName);'''
      : '';

  return '''
const $schemaName = ZtoSchema(
  typeName: '$className',
  descriptors: [
    $descriptors,
  ],
);$registration''';
}

// ── ParseType helpers ──────────────────────────────────────────────────────

/// Reads the [ParseType] from the class-level @ZDto / @ZEntity annotation.
ParseType _getParseType(ClassElement classElement) {
  for (final meta in classElement.metadata) {
    final obj = meta.computeConstantValue();
    if (obj == null) continue;
    final typeName = obj.type?.element?.name;
    if (typeName != 'ZDto' && typeName != 'ZEntity') continue;

    final parseTypeObj = obj.getField('parseType');
    if (parseTypeObj == null) continue;

    // Prefer index-based lookup (most reliable across analyzer versions).
    final index = parseTypeObj.getField('index')?.toIntValue();
    if (index != null && index >= 0 && index < ParseType.values.length) {
      return ParseType.values[index];
    }

    // Fall back to source-text matching.
    final source = meta.toSource();
    if (source.contains('snakeCase')) return ParseType.snakeCase;
    if (source.contains('pascalCase')) return ParseType.pascalCase;
    if (source.contains('kebabCase')) return ParseType.kebabCase;
  }
  return ParseType.camelCase;
}

/// Converts a Dart field name to the resolved map key using [parseType].
String _applyParseType(String dartFieldName, ParseType parseType) {
  return switch (parseType) {
    ParseType.camelCase => dartFieldName,
    ParseType.snakeCase => _toSnakeCase(dartFieldName),
    ParseType.pascalCase => _toPascalCase(dartFieldName),
    ParseType.kebabCase => _toSnakeCase(dartFieldName).replaceAll('_', '-'),
  };
}

String _toSnakeCase(String s) {
  return s.replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => '_${m.group(1)!.toLowerCase()}').toLowerCase();
}

String _toPascalCase(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

// ── Key resolution ─────────────────────────────────────────────────────────

/// Determines the JSON map key for [field]:
/// 1. Explicit `mapKey: '...'` in the annotation source → use it.
/// 2. Fallback: infer from Dart field name + [parseType].
String _resolveFieldMapKey(FieldElement field, ParseType parseType) {
  for (final meta in field.metadata) {
    if (!AnnotationEncoder.isFieldType(meta)) continue;
    final source = meta.toSource().substring(1); // strip '@'

    // Explicit mapKey: '...' named param
    final mapKeyMatch = RegExp(r"mapKey:\s*'([^']+)'").firstMatch(source);
    if (mapKeyMatch != null) return mapKeyMatch.group(1)!;

    // ZObject might have mapKey too
    if (source.startsWith('ZObject(')) {
      // No explicit mapKey → fall through to inference
      break;
    }
    break;
  }
  return _applyParseType(field.name, parseType);
}

/// Rewrites the field annotation source to always include `mapKey: 'key'`
/// as the first named argument. Removes any previous positional key or
/// existing `mapKey:` before injecting the resolved key.
///
/// Special case: `@ZObject(...)` is translated to `ZObj(mapKey: ..., dtoType: TypeName)`.
String _encodeFieldAnnotationWithKey(FieldElement field, String resolvedKey) {
  for (final meta in field.metadata) {
    if (!AnnotationEncoder.isFieldType(meta)) continue;
    final source = meta.toSource().substring(1); // strip '@'
    final typeName = source.substring(0, source.indexOf('('));

    // ZEnum without values: infer from EnumElement
    if (typeName == 'ZEnum' && !source.contains('values:')) {
      final element = field.type.element;
      if (element is EnumElement) {
        final enumValues = element.fields.where((f) => f.isEnumConstant).map((f) => f.name).toList();
        final valuesArg = enumValues.map((v) => "'$v'").join(', ');
        return "ZEnum(values: [$valuesArg], mapKey: '$resolvedKey')";
      }
      return _injectMapKeyIntoSource(source, resolvedKey);
    }

    // ZObject → translate to ZObj with direct schema reference (no registry lookup)
    if (typeName == 'ZObject') {
      final dartTypeName = field.type.element?.name ?? 'dynamic';
      final schemaRef = '\$${dartTypeName}Schema';
      final descMatch = RegExp(r"description:\s*'([^']+)'").firstMatch(source);
      final desc = descMatch != null ? ", description: '${descMatch.group(1)}'" : '';
      return "ZObj(mapKey: '$resolvedKey', dtoSchema: $schemaRef$desc)";
    }

    // ZList with a @ZDto/@ZEntity itemType → use ZListOf(dtoSchema: ...) for direct reference
    if (typeName == 'ZList') {
      final itemElement = _getListItemElement(field);
      if (itemElement != null && _isDtoAnnotated(itemElement)) {
        final schemaRef = '\$${itemElement.name}Schema';
        final descMatch = RegExp(r"description:\s*'([^']+)'").firstMatch(source);
        final desc = descMatch != null ? ", description: '${descMatch.group(1)}'" : '';
        return "ZListOf(mapKey: '$resolvedKey', dtoSchema: $schemaRef$desc)";
      }
    }

    // @ZListOf(dtoType: ItemDto) — same as ZList+DTO: embed schema const so OpenAPI
    // does not depend on Zto.registerSchemas at doc-build time.
    if (typeName == 'ZListOf') {
      final itemElement = _getListItemElement(field);
      if (itemElement != null && _isDtoAnnotated(itemElement)) {
        final schemaRef = '\$${itemElement.name}Schema';
        final descMatch = RegExp(r"description:\s*'([^']+)'").firstMatch(source);
        final desc = descMatch != null ? ", description: '${descMatch.group(1)}'" : '';
        return "ZListOf(mapKey: '$resolvedKey', dtoSchema: $schemaRef$desc)";
      }
    }

    return _injectMapKeyIntoSource(source, resolvedKey);
  }

  // Fallback: infer ZObj for unannotated @ZDto/@ZEntity fields
  if (_fieldTypeIsDtoAnnotated(field)) {
    final dartTypeName = field.type.element?.name ?? 'dynamic';
    return "ZObj(mapKey: '$resolvedKey', dtoType: $dartTypeName)";
  }

  // Fallback: infer ZEnum for unannotated enum fields
  if (field.type.element is EnumElement) {
    final element = field.type.element as EnumElement;
    final enumValues = element.fields.where((f) => f.isEnumConstant).map((f) => f.name).toList();
    final valuesArg = enumValues.map((v) => "'$v'").join(', ');
    return "ZEnum(values: [$valuesArg], mapKey: '$resolvedKey')";
  }

  throw InvalidGenerationSourceError(
    'No recognised @Z* annotation found on field "${field.name}".',
    element: field,
  );
}

/// Injects `mapKey: 'key'` into an annotation source string.
///
/// - Removes any existing positional string argument (old API)
/// - Removes any existing `mapKey: '...'` (avoids duplicates)
/// - Prepends the resolved `mapKey: 'key'` as first named argument
String _injectMapKeyIntoSource(String source, String resolvedKey) {
  final parenIdx = source.indexOf('(');
  final typeName = source.substring(0, parenIdx);
  var inner = source.substring(parenIdx + 1, source.lastIndexOf(')'));

  // Remove existing positional string key (e.g. 'email', or 'email' followed by comma+space)
  inner = inner.replaceFirst(RegExp(r"^'[^']*',?\s*"), '');

  // Remove existing mapKey: '...' (with optional trailing comma+space)
  inner = inner.replaceFirst(RegExp(r"mapKey:\s*'[^']*',?\s*"), '');

  // Clean up any leading comma left after removal
  inner = inner.trim();
  if (inner.startsWith(',')) inner = inner.substring(1).trim();

  final newArgs = inner.isEmpty ? "mapKey: '$resolvedKey'" : "mapKey: '$resolvedKey', $inner";
  return '$typeName($newArgs)';
}

// ── Field collection ───────────────────────────────────────────────────────

List<FieldElement> _annotatedFields(ClassElement classElement) {
  return classElement.fields.where((f) {
    // Include fields with explicit @Z* annotation
    if (f.metadata.any(AnnotationEncoder.isFieldType)) return true;
    // Include unannotated fields whose type is @ZDto/@ZEntity (infer ZObj)
    if (_fieldTypeIsDtoAnnotated(f)) return true;
    // Include unannotated enum fields (infer ZEnum)
    if (f.type.element is EnumElement) return true;
    return false;
  }).toList();
}

/// Checks if a field's type is a class annotated with @ZDto or @ZEntity.
bool _fieldTypeIsDtoAnnotated(FieldElement field) {
  final element = field.type.element;
  if (element is! ClassElement) return false;
  return element.metadata.any((m) {
    final obj = m.computeConstantValue();
    final name = obj?.type?.element?.name;
    return name == 'ZDto' || name == 'ZEntity';
  });
}

// ── Descriptor generation ──────────────────────────────────────────────────

String _buildDescriptor(FieldElement field, ClassElement classElement, ParseType parseType) {
  _validateFieldValidators(field, classElement);
  final resolvedKey = _resolveFieldMapKey(field, parseType);
  final fieldAnnotation = _encodeFieldAnnotationWithKey(field, resolvedKey);
  final validators = _encodeValidators(field);
  final isNullable = _hasNullable(field);

  return '''FieldDescriptor(
      fieldAnnotation: $fieldAnnotation,
      validators: [$validators],
      isNullable: $isNullable,
    )''';
}

void _validateFieldValidators(FieldElement field, ClassElement classElement) {
  final fieldTypeName = _getZtoFieldTypeName(field);
  if (fieldTypeName == null) return;

  final allowed = validatorCompatibility[fieldTypeName];
  if (allowed == null) return;

  for (final meta in field.metadata) {
    if (!AnnotationEncoder.isValidator(meta)) continue;
    final source = meta.toSource();
    if (!source.startsWith('@')) continue;
    final code = source.substring(1);
    final parenIdx = code.indexOf('(');
    final validatorName = parenIdx > 0 ? code.substring(0, parenIdx) : code;

    if (allowed.contains(validatorName)) continue;

    final allowedTypes = allowedFieldTypesForValidator(validatorName);
    final key = _resolveFieldMapKey(field, ParseType.camelCase);
    throw InvalidGenerationSourceError(
      '❌ @$validatorName() applies only to $allowedTypes fields. '
      'Field "$key" uses @$fieldTypeName — remove @$validatorName or use a compatible validator.',
      element: classElement,
    );
  }
}

String _encodeValidators(FieldElement field) {
  return field.metadata.where(AnnotationEncoder.isValidator).map(AnnotationEncoder.encode).whereType<String>().join(', ');
}

bool _hasNullable(FieldElement field) {
  // Check Dart's type system first (? suffix)
  if (field.type.nullabilitySuffix == NullabilitySuffix.question) return true;
  // Fallback to annotation for backward compatibility
  return field.metadata.any((m) {
    final source = m.toSource();
    return source == '@ZNullable()' || source == '@ZNullable' || source == '@Nullable()' || source == '@Nullable';
  });
}

String? _getZtoFieldTypeName(FieldElement field) {
  for (final meta in field.metadata) {
    if (AnnotationEncoder.isFieldType(meta)) {
      final source = meta.toSource();
      if (!source.startsWith('@')) return null;
      final code = source.substring(1);
      final parenIdx = code.indexOf('(');
      if (parenIdx > 0) return code.substring(0, parenIdx);
    }
  }
  return null;
}

/// Returns the [ClassElement] for the List item type when [field] is `List<T>`.
ClassElement? _getListItemElement(FieldElement field) {
  final type = field.type;
  if (type is InterfaceType && type.typeArguments.isNotEmpty) {
    final itemElement = type.typeArguments.first.element;
    if (itemElement is ClassElement) return itemElement;
  }
  return null;
}

/// Returns true if [element] is annotated with `@ZDto` or `@ZEntity`.
bool _isDtoAnnotated(ClassElement element) {
  return element.metadata.any((m) {
    final obj = m.computeConstantValue();
    final name = obj?.type?.element?.name;
    return name == 'ZDto' || name == 'ZEntity';
  });
}
