import 'package:dart_frog_open_api/dart_frog_open_api.dart';

/// Shared refs for route docs — same declarations as [openApiConfig.declaredSecuritySchemes].
final openapiBearer = OpenApiSecurity.bearer();
final openapiApiKey = OpenApiSecurity.apiKeyHeader(header: 'X-API-Key');

final openapiDeclaredSecuritySchemes = [
  openapiBearer,
  openapiApiKey,
];
