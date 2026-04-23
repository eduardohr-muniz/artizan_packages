import 'package:zto/zto.dart';

part 'user_dto.g.dart';

@ZDto(description: 'Create a new user', parseType: ParseType.snakeCase)
class CreateUserDto with ZtoDto<CreateUserDto> {
  @ZString(description: 'Full name', example: 'Alice Silva')
  @ZMinLength(2)
  @ZMaxLength(100)
  @ZNullable()
  final String? name;

  @ZString(description: 'E-mail address', example: 'alice@example.com')
  @ZEmail()
  final String email;

  @ZEnum(values: ['admin', 'editor', 'viewer'], description: 'User role')
  final String role;

  const CreateUserDto({required this.name, required this.email, required this.role});

  factory CreateUserDto.fromMap(Map<String, dynamic> map) => CreateUserDto(
        name: map['name'] as String?,
        email: map['email'] as String,
        role: map['role'] as String,
      );
}

@ZDto(description: 'Update an existing user (all fields optional)', parseType: ParseType.snakeCase)
class UpdateUserDto with ZtoDto<UpdateUserDto> {
  @ZString(description: 'Full name', example: 'Alice Silva')
  @ZMinLength(2)
  @ZNullable()
  final String? name;

  @ZString(description: 'E-mail address', example: 'alice@example.com')
  @ZEmail()
  @ZNullable()
  final String? email;

  const UpdateUserDto({this.name, this.email});

  factory UpdateUserDto.fromMap(Map<String, dynamic> map) => UpdateUserDto(
        name: map['name'] as String?,
        email: map['email'] as String?,
      );
}

@ZDto(description: 'User response', parseType: ParseType.snakeCase)
class UserResponseDto {
  @ZString(description: 'Unique identifier')
  final String id;

  @ZString(description: 'Full name')
  final String name;

  /// Deprecated alias for [name]. Kept for backwards compatibility.
  @ZString(
    description: 'Legacy short username — use `name` instead.',
    deprecated: true,
  )
  final String? username;

  @ZString(description: 'E-mail address')
  final String email;

  @ZEnum(values: ['admin', 'editor', 'viewer'])
  final String role;

  @ZDate(description: 'Creation timestamp')
  final DateTime createdAt;

  @ZMetaData(description: 'Metadata do usuario', example: {'key': 'value'})
  final Map<String, dynamic> metaData;

  const UserResponseDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.metaData,
    this.username,
  });
}

@ZDto(description: 'Paginated list of users', parseType: ParseType.snakeCase)
class UserListResponseDto {
  @ZList(itemType: UserResponseDto, description: 'User items')
  final List<UserResponseDto> data;

  @ZInt(description: 'Total number of users', example: 10)
  final int total;

  @ZObject(description: 'Address items')
  final AddressDto address;

  const UserListResponseDto({required this.data, required this.total, required this.address});
}

@ZDto(description: 'Address response', parseType: ParseType.snakeCase)
class AddressDto {
  @ZString(description: 'Street', example: 'Rua das Flores')
  final String street;

  @ZString(description: 'City', example: 'São Paulo')
  final String city;

  @ZString(description: 'State', example: 'SP')
  final String state;

  @ZString(description: 'Zip code', example: '12345678')
  final String zipCode;

  const AddressDto({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
  });
}
