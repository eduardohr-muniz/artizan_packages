import '../annotations/field_annotations.dart';
import '../annotations/validator_annotations.dart';
import '../core/zto_exception.dart';
import '../core/zto_schema.dart';
import '../reflection/field_descriptor.dart';

ZtoSchemaBase? _resolvedDtoSchema(ZtoSchemaBase? dtoSchema, Type? dtoType) =>
    dtoSchema ?? (dtoType != null ? Zto.getSchema(dtoType) : null);

/// Converts a [ZtoSchema] into an OpenAPI 3.0 JSON Schema `object` definition.
///
/// No runtime reflection — all information comes from the pre-generated schema.
abstract final class DtoToOpenApi {
  /// Tracks schemas currently being converted to prevent circular recursion.
  static final Set<String> _seen = {};

  /// Converts [schema] to an OpenAPI 3.0 JSON Schema `object` map.
  ///
  /// Returns a map with `type`, `properties`, and optionally `required`.
  /// Circular references are detected by [typeName] and short-circuited to
  /// `{'type': 'object'}`.
  static Map<String, dynamic> convert(ZtoSchema schema) {
    // Guard against circular references
    if (_seen.contains(schema.typeName)) {
      return {'type': 'object'};
    }
    _seen.add(schema.typeName);

    try {
      final properties = <String, dynamic>{};
      final required = <String>[];

      for (final d in schema.descriptors) {
        if (!d.isNullable) required.add(d.key);
        properties[d.key] = _buildProperty(d);
      }

      return {
        'type': 'object',
        'properties': properties,
        if (required.isNotEmpty) 'required': required,
      };
    } finally {
      _seen.remove(schema.typeName);
    }
  }

  static Map<String, dynamic> _buildProperty(FieldDescriptor d) {
    var base = _baseSchema(d.fieldAnnotation);
    if (!d.isNullable) {
      final ann = d.fieldAnnotation;
      if (ann is ZList || ann is ZListOf) {
        base = {...base, 'minItems': 1};
      }
    }

    // Apply validators to the base schema
    final withValidators = _applyValidators(base, d.validators);

    if (d.isNullable) {
      final firstItem = <String, dynamic>{
        ...withValidators,
        if (d.fieldAnnotation.description != null) 'description': d.fieldAnnotation.description,
        if (d.fieldAnnotation.example != null) 'example': d.fieldAnnotation.example,
        if (d.fieldAnnotation.deprecated) 'deprecated': true,
      };
      return {
        'oneOf': [
          firstItem,
          {'type': 'null'},
        ],
      };
    }

    return <String, dynamic>{
      ...withValidators,
      if (d.fieldAnnotation.description != null) 'description': d.fieldAnnotation.description,
      if (d.fieldAnnotation.example != null) 'example': d.fieldAnnotation.example,
      if (d.fieldAnnotation.deprecated) 'deprecated': true,
    };
  }

  /// Applies OpenAPI keyword constraints derived from [validators] to [base].
  static Map<String, dynamic> _applyValidators(
    Map<String, dynamic> base,
    List<ZtoValidator> validators,
  ) {
    if (validators.isEmpty) return base;
    final result = Map<String, dynamic>.from(base);
    for (final v in validators) {
      switch (v) {
        case ZMinLength(:final n):
          result['minLength'] = n;
        case ZMaxLength(:final n):
          result['maxLength'] = n;
        case ZLength(:final n):
          result['minLength'] = n;
          result['maxLength'] = n;
        case ZMin(:final n):
          result['minimum'] = n;
        case ZMax(:final n):
          result['maximum'] = n;
        case ZMultipleOf(:final n):
          result['multipleOf'] = n;
        case ZPattern(:final regex):
          result['pattern'] = regex;
        case ZEmail():
          if (!result.containsKey('format')) result['format'] = 'email';
        case ZUuid():
          result['format'] = 'uuid';
        case ZUrl():
          if (!result.containsKey('format')) result['format'] = 'uri';
        case ZHttpUrl():
          if (!result.containsKey('format')) result['format'] = 'uri';
        case ZPositive():
          result['exclusiveMinimum'] = 0;
        case ZNonNegative():
          result['minimum'] = 0;
        case ZNegative():
          result['exclusiveMaximum'] = 0;
        case ZNonPositive():
          result['maximum'] = 0;
        default:
          break;
      }
    }
    return result;
  }

  static Map<String, dynamic> _baseSchema(ZtoField annotation) {
    return switch (annotation) {
      ZString() => {'type': 'string'},
      ZInt() => {'type': 'integer'},
      ZDouble() => {'type': 'number'},
      ZNum() => {'type': 'number'},
      ZBool() => {'type': 'boolean'},
      ZDate() => {'type': 'string', 'format': 'date-time'},
      ZFile() => {'type': 'string', 'format': 'binary'},
      ZEnum(:final values) => {'type': 'string', 'enum': values},
      ZList(:final itemType) => {
          'type': 'array',
          'items': _itemSchema(itemType),
        },
      ZMap() => {'type': 'object'},
      ZMetaData() => {'type': 'object'},
      ZListOf(:final dtoSchema, :final dtoType) => {
          'type': 'array',
          'items': () {
            final s = _resolvedDtoSchema(dtoSchema, dtoType);
            if (s != null) {
              return {r'$ref': '#/components/schemas/${s.typeName}'};
            }
            return {'type': 'object'};
          }(),
        },
      ZObj(:final dtoSchema, :final dtoType) => () {
          final s = _resolvedDtoSchema(dtoSchema, dtoType);
          if (s != null) {
            return {r'$ref': '#/components/schemas/${s.typeName}'};
          }
          return {'type': 'object'};
        }(),
      _ => {'type': 'object'},
    };
  }

  static Map<String, dynamic> _itemSchema(Type itemType) {
    return switch (itemType) {
      const (ZString) => {'type': 'string'},
      const (ZInt) => {'type': 'integer'},
      const (ZDouble) => {'type': 'number'},
      const (ZNum) => {'type': 'number'},
      const (ZBool) => {'type': 'boolean'},
      const (ZDate) => {'type': 'string', 'format': 'date-time'},
      _ => () {
          final s = Zto.getSchema(itemType);
          if (s != null) return {r'$ref': '#/components/schemas/${s.typeName}'};
          return {'type': 'object'};
        }(),
    };
  }
}
