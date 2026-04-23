import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zto/zto.dart';

import 'annotation_encoder.dart';
import 'schema_generator.dart';
import 'validator_compatibility.dart';
import 'zto_dtos_generator.dart';
import 'zto_generate_schemas_generator.dart';

/// Factory function registered in `build.yaml`.
Builder ztoBuilder(BuilderOptions options) => PartBuilder(
      [
        const DtoGenerator(),
        const ZDtoGenerator(),
        const ZEntityGenerator(),
        const ZtoDtosGenerator(),
        const ZtoGenerateSchemasGenerator(),
      ],
      '.g.dart',
    );

/// Generates a `ZtoSchema` constant for every class annotated with `@Dto()`.
///
/// @deprecated Use [@ZDto] instead. This generator is kept for backward compat.
class DtoGenerator extends GeneratorForAnnotation<Dto> {
  const DtoGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Dto can only be applied to classes.',
        element: element,
      );
    }
    final classElement = element;
    final className = classElement.name;
    final schemaName = '\$${className}Schema';

    final fields = _annotatedFields(classElement);
    final descriptors = fields.map((f) => _buildDescriptorLegacy(f, classElement)).join(',\n    ');

    final hasFromMap = classElement.constructors.any((c) => c.name == 'fromMap');

    final registration = hasFromMap
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

  List<FieldElement> _annotatedFields(ClassElement classElement) {
    return classElement.fields.where((f) => f.metadata.any(AnnotationEncoder.isFieldType)).toList();
  }

  /// Legacy descriptor builder — keeps backward compat with @Dto classes
  /// that use the old positional-key syntax (e.g. @ZString('name')).
  /// New @ZDto classes go through schema_generator.dart which injects mapKey.
  String _buildDescriptorLegacy(FieldElement field, ClassElement classElement) {
    _validateFieldValidatorsLegacy(field, classElement);
    final fieldAnnotation = _encodeFieldAnnotationLegacy(field);
    final validators = _encodeValidators(field);
    final isNullable = _hasNullable(field);

    return '''FieldDescriptor(
      fieldAnnotation: $fieldAnnotation,
      validators: [$validators],
      isNullable: $isNullable,
    )''';
  }

  void _validateFieldValidatorsLegacy(FieldElement field, ClassElement classElement) {
    // Delegate to schema_generator validation helper via inline copy
    // to avoid changing the shared function's signature.
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
      throw InvalidGenerationSourceError(
        '❌ @$validatorName() applies only to $allowedTypes fields. '
        'Field "${field.name}" uses @$fieldTypeName — remove @$validatorName.',
        element: field,
      );
    }
  }

  String _encodeFieldAnnotationLegacy(FieldElement field) {
    for (final meta in field.metadata) {
      if (!AnnotationEncoder.isFieldType(meta)) continue;
      final encoded = AnnotationEncoder.encode(meta);
      if (encoded != null) return encoded;
    }
    throw InvalidGenerationSourceError(
      'No recognised @Z* annotation found on field "${field.name}".',
      element: field,
    );
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
      return source == '@ZNullable()' ||
          source == '@ZNullable' ||
          source == '@Nullable()' ||
          source == '@Nullable';
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
}

/// Generates a `ZtoSchema` constant for every class annotated with `@ZDto()`.
class ZDtoGenerator extends GeneratorForAnnotation<ZDto> {
  const ZDtoGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ZDto can only be applied to classes.',
        element: element,
      );
    }
    return generateSchemaForClass(element);
  }
}

/// Generates a `ZtoSchema` constant for every class annotated with `@ZEntity()`.
class ZEntityGenerator extends GeneratorForAnnotation<ZEntity> {
  const ZEntityGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ZEntity can only be applied to classes.',
        element: element,
      );
    }
    return generateSchemaForClass(element);
  }
}
