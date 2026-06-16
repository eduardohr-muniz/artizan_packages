# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0]

### Added

- Initial release
- File-system based route scanning for Dart Frog (`routes/`)
- OpenAPI 3.0 JSON spec generation (`openApiJsonHandler`)
- Swagger UI and Scalar UI handlers (`swaggerUiHandler`, `scalarUiHandler`)
- Fluent route documentation API (`Api.path()`) and direct constructors
  (`PathSchema` / `OperationSchema`)
- Automatic DTO schemas via [`zto`](https://pub.dev/packages/zto), with
  recursive `$ref` resolution for nested DTOs
- Postman v2.1 and Bruno collection export (with test / pre-request scripts)
- `SecurityConfig` — secure by default (404 until explicitly enabled), optional
  guard, CORS allowlist, security headers and spec caching
- Declarative security schemes (`OpenApiSecurity.bearer`, `apiKey*`, `oauth2*`)
