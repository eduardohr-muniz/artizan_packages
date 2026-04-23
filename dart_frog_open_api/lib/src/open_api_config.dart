import 'dart:io';

import 'open_api_builder/open_api_info.dart';
import 'open_api_builder/scalar_options.dart';
import 'open_api_security_declaration.dart';
import 'schemas/path_schema.dart';
import 'schemas/security_scheme.dart';
import 'security/security_config.dart';

/// Configuration for [DartFrogOpenApi].
///
/// Holds all settings used by the OpenAPI JSON and Swagger UI handlers.
///
/// **Security**: by default [security] has `enabled: false`, which means all
/// documentation endpoints return 404. You must explicitly enable them:
///
/// ```dart
/// // Development:
/// security: const SecurityConfig(enabled: true),
/// ```
class OpenApiConfig {
  const OpenApiConfig({
    required this.info,
    this.pathSchemas = const {},
    this.securitySchemes = const {},
    this.declaredSecuritySchemes,
    this.globalSecurity,
    this.specUrl = '/openapi',
    this.baseUrl = 'http://localhost:8080',
    this.brunoOutputDir,
    this.security = const SecurityConfig(),
    this.scalarEnvironments = const [],
    this.scalarActiveEnvironment,
  });

  /// Base API info.
  final OpenApiInfo info;

  /// The manually registered map of path schemas.
  /// Example: `'/v1/users': v1UsersApiDoc`
  final Map<String, PathSchema> pathSchemas;

  /// Map of security schemes when [declaredSecuritySchemes] is null or empty.
  final Map<String, SecurityScheme> securitySchemes;

  /// Declarative list; when non-null and non-empty, [resolvedSecuritySchemes]
  /// is built from it and replaces [securitySchemes] for spec generation.
  final List<DeclaredSecurityScheme>? declaredSecuritySchemes;

  /// Effective `components.securitySchemes` map for handlers and builders.
  Map<String, SecurityScheme> get resolvedSecuritySchemes {
    if (declaredSecuritySchemes != null &&
        declaredSecuritySchemes!.isNotEmpty) {
      return DeclaredSecurityScheme.toMap(declaredSecuritySchemes!);
    }
    return securitySchemes;
  }

  /// List of globally applied security schemes.
  final List<String>? globalSecurity;

  /// The URL for the OpenAPI JSON spec.
  final String specUrl;

  /// The base URL for your API.
  final String baseUrl;

  /// When set, enables Bruno download and writes collection to this directory.
  final Directory? brunoOutputDir;

  /// Security configuration for all documentation endpoints.
  ///
  /// Defaults to [SecurityConfig] with [SecurityConfig.enabled] = `false`,
  /// meaning all handlers return 404 until explicitly enabled.
  final SecurityConfig security;

  /// Named environments for Scalar's environment switcher.
  ///
  /// Variables defined here become available as `{{variableName}}` in any
  /// URL, header, query param, or request body inside Scalar's "Try it" panel.
  ///
  /// Example:
  /// ```dart
  /// scalarEnvironments: [
  ///   ScalarEnvironment(
  ///     name: 'Local',
  ///     variables: {
  ///       'token': ScalarEnvironmentVariable(value: '', description: 'JWT from login'),
  ///       'userId': ScalarEnvironmentVariable(value: '1'),
  ///     },
  ///   ),
  /// ]
  /// ```
  final List<ScalarEnvironment> scalarEnvironments;

  /// The environment key to activate by default (must match a [ScalarEnvironment.name]).
  /// If null, Scalar picks the first environment automatically.
  final String? scalarActiveEnvironment;
}
