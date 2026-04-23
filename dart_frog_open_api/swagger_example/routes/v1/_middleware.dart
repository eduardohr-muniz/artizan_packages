import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final path = context.request.uri.path;

    // Lista de rotas que ignoram a autenticação
    final publicRoutes = [
      '/v1/auth/login',
      '/scalar', // A própria documentação
      '/swagger',
    ];

    if (publicRoutes.any((route) => path.startsWith(route))) {
      return handler(context);
    }

    // Pega o header de Authorization
    final authHeader = context.request.headers['Authorization'] ?? context.request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Acesso negado. Token Bearer ausente ou inválido.'},
      );
    }

    // Para fins de teste, aceitamos qualquer token que comece com 'eyJ' (JWT mock)
    final token = authHeader.substring(7);
    if (!token.startsWith('eyJ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Token inválido. Use o token retornado pelo endpoint de login.'},
      );
    }

    // Segue para a rota
    return handler(context);
  };
}
