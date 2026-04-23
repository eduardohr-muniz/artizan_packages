import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zto/zto.dart';

import 'schema_generator.dart';

/// Generates a single `zto.g.dart` with all schemas and `$ZtoSchemas` for [Zto.registerSchemas].
///
/// All DTOs listed in [@ZtoDtos] get their schema generated and registered by Type.
/// Use any factory in [Zto.parse]: fromMap, fromApi, fromJson, etc.
class ZtoDtosGenerator extends GeneratorForAnnotation<ZtoDtos> {
  const ZtoDtosGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final dtosList = annotation.read('dtos').listValue;
    if (dtosList.isEmpty) return '';

    final schemas = <String>[];
    final registrations = <_DtoReg>[];

    for (final item in dtosList) {
      final type = item.toTypeValue();
      if (type == null) continue;
      final classElem = type.element;
      if (classElem is! ClassElement) continue;

      final schemaCode = generateSchemaForClass(classElem, includeRegistration: false);
      schemas.add(schemaCode);

      final className = classElem.name;
      final schemaName = '\$${className}Schema';
      registrations.add(_DtoReg(className: className, schemaName: schemaName));
    }

    final schemaBlocks = schemas.join('\n\n');
    final entries = registrations.map((r) => '  (${r.className}, ${r.schemaName}),').join('\n');

    return '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: dart run build_runner build

const List<ZtoSchemaRegistration> \$ZtoSchemas = [
$entries
];

$schemaBlocks
''';
  }
}

class _DtoReg {
  final String className;
  final String schemaName;

  _DtoReg({required this.className, required this.schemaName});
}
