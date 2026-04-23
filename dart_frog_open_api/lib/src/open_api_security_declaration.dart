import 'schemas/security_scheme.dart';

/// One entry in OpenAPI `components.securitySchemes`: a component [componentKey]
/// and its [scheme] definition.
///
/// Build instances via [OpenApiSecurity] factories.
class DeclaredSecurityScheme {
  const DeclaredSecurityScheme({
    required this.componentKey,
    required this.scheme,
  });

  /// Key in `components.securitySchemes` (and in `security` arrays on operations).
  final String componentKey;

  final SecurityScheme scheme;

  /// Builds the map passed to OpenAPI `components.securitySchemes`.
  static Map<String, SecurityScheme> toMap(List<DeclaredSecurityScheme> declarations) {
    final out = <String, SecurityScheme>{};
    for (final d in declarations) {
      if (out.containsKey(d.componentKey)) {
        throw ArgumentError.value(
          d.componentKey,
          'declarations',
          'Duplicate security scheme component key: ${d.componentKey}',
        );
      }
      out[d.componentKey] = d.scheme;
    }
    return out;
  }
}

/// Declarative factories for common OpenAPI security schemes.
///
/// Example:
/// ```dart
/// OpenApiConfig(
///   declaredSecuritySchemes: [
///     OpenApiSecurity.bearer(),
///     OpenApiSecurity.apiKeyHeader(header: 'X-API-Key'),
///   ],
/// )
/// ```
abstract final class OpenApiSecurity {
  OpenApiSecurity._();

  /// JWT / Bearer (`Authorization: Bearer`).
  static DeclaredSecurityScheme bearer([String name = 'BearerAuth']) =>
      DeclaredSecurityScheme(componentKey: name, scheme: SecurityScheme.bearer);

  /// HTTP Basic authentication.
  static DeclaredSecurityScheme basic([String name = 'BasicAuth']) =>
      DeclaredSecurityScheme(componentKey: name, scheme: SecurityScheme.basic);

  /// API key sent in a request header.
  static DeclaredSecurityScheme apiKeyHeader({
    String name = 'ApiKey',
    required String header,
  }) =>
      DeclaredSecurityScheme(
        componentKey: name,
        scheme: SecurityScheme.apiKeyHeader(header),
      );

  /// API key sent as a query parameter.
  static DeclaredSecurityScheme apiKeyQuery({
    String name = 'ApiKey',
    required String param,
  }) =>
      DeclaredSecurityScheme(
        componentKey: name,
        scheme: SecurityScheme.apiKeyQuery(param),
      );

  /// API key sent in a cookie.
  static DeclaredSecurityScheme apiKeyCookie({
    String name = 'ApiKey',
    required String cookie,
  }) =>
      DeclaredSecurityScheme(
        componentKey: name,
        scheme: SecurityScheme.apiKeyCookie(cookie),
      );

  /// OAuth 2.0 — Authorization Code flow.
  static DeclaredSecurityScheme oauth2AuthorizationCode({
    required String name,
    required String authorizationUrl,
    required String tokenUrl,
    Map<String, String> scopes = const {},
  }) =>
      DeclaredSecurityScheme(
        componentKey: name,
        scheme: SecurityScheme.oauth2AuthorizationCode(
          authorizationUrl: authorizationUrl,
          tokenUrl: tokenUrl,
          scopes: scopes,
        ),
      );

  /// OAuth 2.0 — Client Credentials flow.
  static DeclaredSecurityScheme oauth2ClientCredentials({
    required String name,
    required String tokenUrl,
    Map<String, String> scopes = const {},
  }) =>
      DeclaredSecurityScheme(
        componentKey: name,
        scheme: SecurityScheme.oauth2ClientCredentials(
          tokenUrl: tokenUrl,
          scopes: scopes,
        ),
      );

  /// OAuth 2.0 — Implicit flow.
  static DeclaredSecurityScheme oauth2Implicit({
    required String name,
    required String authorizationUrl,
    Map<String, String> scopes = const {},
  }) =>
      DeclaredSecurityScheme(
        componentKey: name,
        scheme: SecurityScheme.oauth2Implicit(
          authorizationUrl: authorizationUrl,
          scopes: scopes,
        ),
      );

  /// Any [SecurityScheme] under a custom component name.
  static DeclaredSecurityScheme scheme({
    required String name,
    required SecurityScheme definition,
  }) =>
      DeclaredSecurityScheme(componentKey: name, scheme: definition);

  /// Raw OpenAPI Security Scheme Object.
  static DeclaredSecurityScheme raw({
    required String name,
    required Map<String, dynamic> spec,
  }) =>
      DeclaredSecurityScheme(
        componentKey: name,
        scheme: SecurityScheme.raw(spec),
      );

  /// Component keys for use in [ApiOperationBuilder.security] / `globalSecurity`.
  static List<String> componentKeys(List<DeclaredSecurityScheme> declarations) =>
      declarations.map((d) => d.componentKey).toList(growable: false);
}
