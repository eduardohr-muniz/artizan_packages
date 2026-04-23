/// Annotation-based DTO validation and OpenAPI schema generation for Dart.
///
/// ## Quickstart
///
/// ```dart
/// @Dto(description: 'Create user')
/// class CreateUserDto with ZtoDto<CreateUserDto> {
///   @ZString('name') @ZMinLength(2) final String name;
///   @ZInt('age')  @ZMin(18)      final int age;
///
///   const CreateUserDto({required this.name, required this.age});
///
///   static CreateUserDto fromMap(Map<String, dynamic> map) =>
///       CreateUserDto(name: map['name'] as String, age: map['age'] as int);
/// }
///
/// // In a route:
/// final dto = Zto.parse(body, CreateUserDto.fromMap)
///     .refine((d) => d.age < 120, message: 'Unrealistic age');
/// ```
library;

export 'src/annotations/field_annotations.dart';
export 'src/annotations/validator_annotations.dart';
export 'src/core/zto_dto.dart';
export 'src/core/zto_exception.dart'; // exports ZtoIssue, ZtoException, Zto
export 'src/core/zto_issue.dart';
export 'src/core/zto_schema.dart';
export 'src/fluent/z_singleton.dart';
export 'src/fluent/zto_map.dart';
export 'src/fluent/zto_rule.dart';
export 'src/reflection/field_descriptor.dart';
export 'src/schema/dto_to_open_api.dart';
export 'src/validation/field_validator.dart';
