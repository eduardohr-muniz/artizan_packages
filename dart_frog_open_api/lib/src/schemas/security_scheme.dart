/// Defines an OpenAPI 3.0 security scheme shown in the Swagger UI "Authorize"
/// dialog.
///
/// Use the static factories to build the most common scheme types:
///
/// ```dart
/// securitySchemes: {
///   'BearerAuth': SecurityScheme.bearer,
///   'ApiKey':     SecurityScheme.apiKeyHeader('X-API-Key'),
///   'BasicAuth':  SecurityScheme.basic,
/// }
/// ```
abstract class SecurityScheme {
  const SecurityScheme();

  Map<String, dynamic> toJson();

  /// Returns the Postman header entry for this scheme using [varName] as the
  /// collection variable name, or `null` for schemes that don't produce headers
  /// (e.g. query-param API keys, OAuth2).
  ///
  /// Example: `BearerAuth.postmanHeader('bearerToken')` →
  /// `{'key': 'Authorization', 'value': 'Bearer {{bearerToken}}'}`
  Map<String, String>? postmanHeader(String varName) => null;

  /// JWT / Bearer token via the `Authorization: Bearer <token>` header.
  static const SecurityScheme bearer = BearerScheme();

  /// HTTP Basic authentication (`Authorization: Basic <base64>`).
  static const SecurityScheme basic = BasicScheme();

  /// API key passed in a **request header**.
  ///
  /// [name] is the header name, e.g. `'X-API-Key'`.
  static SecurityScheme apiKeyHeader(String name) =>
      ApiKeyScheme(name: name, location: 'header');

  /// API key passed as a **query parameter**.
  ///
  /// [name] is the query param name, e.g. `'api_key'`.
  static SecurityScheme apiKeyQuery(String name) =>
      ApiKeyScheme(name: name, location: 'query');

  /// API key passed in a **cookie**.
  ///
  /// [name] is the cookie name.
  static SecurityScheme apiKeyCookie(String name) =>
      ApiKeyScheme(name: name, location: 'cookie');

  /// OAuth 2.0 — Authorization Code flow.
  ///
  /// [authorizationUrl] is the authorization endpoint.
  /// [tokenUrl] is the token endpoint.
  /// [scopes] maps scope name → description.
  static SecurityScheme oauth2AuthorizationCode({
    required String authorizationUrl,
    required String tokenUrl,
    Map<String, String> scopes = const {},
  }) =>
      _OAuth2Scheme(
        flows: {
          'authorizationCode': {
            'authorizationUrl': authorizationUrl,
            'tokenUrl': tokenUrl,
            'scopes': scopes,
          },
        },
      );

  /// OAuth 2.0 — Client Credentials flow (machine-to-machine).
  ///
  /// [tokenUrl] is the token endpoint.
  /// [scopes] maps scope name → description.
  static SecurityScheme oauth2ClientCredentials({
    required String tokenUrl,
    Map<String, String> scopes = const {},
  }) =>
      _OAuth2Scheme(
        flows: {
          'clientCredentials': {
            'tokenUrl': tokenUrl,
            'scopes': scopes,
          },
        },
      );

  /// OAuth 2.0 — Implicit flow.
  ///
  /// [authorizationUrl] is the authorization endpoint.
  /// [scopes] maps scope name → description.
  static SecurityScheme oauth2Implicit({
    required String authorizationUrl,
    Map<String, String> scopes = const {},
  }) =>
      _OAuth2Scheme(
        flows: {
          'implicit': {
            'authorizationUrl': authorizationUrl,
            'scopes': scopes,
          },
        },
      );

  /// Raw security scheme for advanced or non-standard schemes.
  ///
  /// [spec] must be a valid OpenAPI 3.0 Security Scheme Object.
  static SecurityScheme raw(Map<String, dynamic> spec) => _RawScheme(spec);
}

/// JWT / Bearer token security scheme (`Authorization: Bearer <token>`).
///
/// Can be used in a `const` context:
/// ```dart
/// const BearerScheme()
/// ```
class BearerScheme extends SecurityScheme {
  const BearerScheme();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'http',
        'scheme': 'bearer',
        'bearerFormat': 'JWT',
      };

  @override
  Map<String, String>? postmanHeader(String varName) =>
      {'key': 'Authorization', 'value': 'Bearer {{$varName}}'};
}

/// HTTP Basic authentication security scheme.
///
/// Can be used in a `const` context:
/// ```dart
/// const BasicScheme()
/// ```
class BasicScheme extends SecurityScheme {
  const BasicScheme();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'http',
        'scheme': 'basic',
      };

  @override
  Map<String, String>? postmanHeader(String varName) =>
      {'key': 'Authorization', 'value': 'Basic {{$varName}}'};
}

/// API key security scheme (header, query, or cookie).
///
/// Can be used in a `const` context:
/// ```dart
/// const ApiKeyScheme(name: 'X-API-Key', location: 'header')
/// ```
class ApiKeyScheme extends SecurityScheme {
  const ApiKeyScheme({required this.name, required this.location});

  final String name;
  final String location;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'apiKey',
        'name': name,
        'in': location,
      };

  @override
  Map<String, String>? postmanHeader(String varName) {
    if (location != 'header') return null;
    return {'key': name, 'value': '{{$varName}}'};
  }
}

class _OAuth2Scheme extends SecurityScheme {
  const _OAuth2Scheme({required this.flows});

  final Map<String, dynamic> flows;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'oauth2',
        'flows': flows,
      };
}

class _RawScheme extends SecurityScheme {
  const _RawScheme(this._spec);

  final Map<String, dynamic> _spec;

  @override
  Map<String, dynamic> toJson() => _spec;
}
