import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';

import '../../../lib/dtos/auth_dto.dart';

final v1AuthLoginApiDoc = Api.path()
    .post((op) => op
        .summary('Endpoint de autenticação')
        .tag('Auth')
        .public()
        .body($LoginRequestDtoSchema)
        .returns(200, schema: $LoginResponseDtoSchema)
        .postman('''
          if (pm.response.code === 200) {
            const body = pm.response.json();
            pm.environment.set("token", body.token);
          }
        '''))
    .build();

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  // Simula um delay
  await Future<void>.delayed(const Duration(milliseconds: 500));

  return Response.json(
    body: {
      'token':
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwibmFtZSI6Ik1vY2sgVXNlciIsImlhdCI6MTUxNjIzOTAyMn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
    },
  );
}
