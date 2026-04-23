import 'dart:io';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';

import 'paths.dart';
import 'security_refs.dart';

const apiInfo = OpenApiInfo(
  title: 'Swagger Example API',
  description: 'Dart Frog + Zto DTO annotations demo.',
  servers: [
    'http://localhost:8182',
    'https://api.sandbox.minhaempresa.com',
    'https://api.minhaempresa.com'
  ],
);

/// OpenAPI config for [DartFrogOpenApi.initialize]. Use in main.dart init.
final openApiConfig = OpenApiConfig(
  info: apiInfo,
  declaredSecuritySchemes: openapiDeclaredSecuritySchemes,
  securitySchemes: const {},
  globalSecurity: [openapiBearer.componentKey],
  pathSchemas: apiPathSchemas,
  specUrl: '/swagger/json',
  brunoOutputDir: Directory('bruno_collection'),
  security: SecurityConfig(
    enabled: true,
    corsOrigins: ['http://localhost:8080'],
    securityHeaders: true,
    cacheTtl: const Duration(minutes: 5),
  ),
  scalarEnvironments: const [
    ScalarEnvironment(
      name: 'local',
      description: 'Local development',
      color: '#00e5c0',
      variables: {
        'token': ScalarEnvironmentVariable(
          defaultValue: '',
          description: 'JWT obtido no endpoint POST /v1/auth/login',
        ),
        'userId': ScalarEnvironmentVariable(defaultValue: '1'),
      },
    ),
    ScalarEnvironment(
      name: 'sandbox',
      description: 'Sandbox',
      color: '#f59e0b',
      variables: {
        'token': ScalarEnvironmentVariable(defaultValue: ''),
        'userId': ScalarEnvironmentVariable(defaultValue: '1'),
      },
    ),
  ],
  scalarActiveEnvironment: 'local',
);
