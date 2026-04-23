import 'zto_exception.dart';

/// Optional mixin that adds cross-field validation (`refine`) to any Dart class.
///
/// Combine with [Zto.parse] for a clean, instance-free parsing API.
///
/// ```dart
/// @Dto(description: 'Create user')
/// class CreateUserDto with ZtoDto<CreateUserDto> {
///   @ZString('name') @ZMinLength(2) final String name;
///   @ZInt('age')  @ZMin(18)      final int age;
///
///   const CreateUserDto({required this.name, required this.age});
///
///   // Static factory used by Zto.parse (no validation inside — use schema in Zto.parse)
///   static CreateUserDto fromMap(Map<String, dynamic> map) =>
///       CreateUserDto(name: map['name'] as String, age: map['age'] as int);
/// }
///
/// // In a route handler:
/// final dto = Zto.parse(body, CreateUserDto.fromMap)
///     .refine((d) => d.age < 120, field: 'age', message: 'Unrealistic age');
/// ```
///
/// If you also want to extend another class (e.g. `Equatable`):
/// ```dart
/// class CreateUserDto extends Equatable with ZtoDto<CreateUserDto> { ... }
/// ```
mixin ZtoDto<T> {
  /// Applies a cross-field validation predicate to this instance.
  ///
  /// Returns `this` as [T] if [predicate] returns `true`.
  /// Throws [ZtoException] with [message] (and optional [field]) otherwise.
  ///
  /// Designed to be chained after [Zto.parse]:
  /// ```dart
  /// final dto = Zto.parse(body, CreateUserDto.fromMap)
  ///     .refine((d) => d.age >= 18, message: 'Must be adult')
  ///     .refine((d) => d.name != d.email, message: 'Name and email must differ');
  /// ```
  T refine(
    bool Function(T dto) predicate, {
    required String message,
    String? field,
  }) {
    if (predicate(this as T)) return this as T;
    throw ZtoException(
      message: 'Validation failed',
      issues: [ZtoIssue(message: message, field: field)],
    );
  }
}
