import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zto/zto.dart';

/// @deprecated @ZtoGenerateSchemas is no longer supported.
/// Schema is now required in [Zto.parse(schema: $DtoSchema)].
class ZtoGenerateSchemasGenerator extends GeneratorForAnnotation<ZtoGenerateSchemas> {
  const ZtoGenerateSchemasGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // No longer generates anything - schema required in Zto.parse()
    return '';
  }
}
