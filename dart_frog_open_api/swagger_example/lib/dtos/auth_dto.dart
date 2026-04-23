import 'package:zto/zto.dart';

part 'auth_dto.g.dart';

@ZDto(description: 'Login Request DTO')
class LoginRequestDto {
  LoginRequestDto({
    required this.email,
    required this.password,
  });

  @ZString(description: 'E-mail address', example: 'exemplo@email.com')
  final String email;

  @ZString(description: 'Password', example: '123456')
  final String password;
}

@ZDto(description: 'Login Response DTO')
class LoginResponseDto {
  LoginResponseDto({
    required this.token,
  });

  @ZString(description: 'JWT Token')
  final String token;
}
