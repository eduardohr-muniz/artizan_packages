/// build_runner code generator for the `zto` package.
///
/// Reads `@Dto`-annotated classes and generates:
/// - A `const $classNameSchema = ZtoSchema(...)` constant with all field descriptors.
///
/// ## Usage
///
/// 1. Add `zto_generator` as a `dev_dependency` in your `pubspec.yaml`.
/// 2. Add `build_runner` as a `dev_dependency`.
/// 3. Annotate DTO classes with `@Dto(description: '...')`.
/// 4. Add `part 'your_file.g.dart';` to your DTO file.
/// 5. Run `dart run build_runner build`.
library;

export 'src/dto_generator.dart' show ztoBuilder;
export 'src/zto_dtos_generator.dart' show ZtoDtosGenerator;
