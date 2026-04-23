import 'package:dart_frog/dart_frog.dart';

/// Security configuration for `dart_frog_open_api` handlers.
///
/// All fields default to the **most restrictive** option so that an
/// unconfigured package is safe out-of-the-box.
///
/// ```dart
/// // Minimal — fully locked down (Swagger never served):
/// const SecurityConfig();
///
/// // Dev — open locally:
/// SecurityConfig(enabled: true);
///
/// // Production — enabled with guard + CORS:
/// SecurityConfig(
///   enabled: true,
///   guard: (req) => req.headers['X-Admin-Key'] == adminKey,
///   corsOrigins: ['https://admin.example.com'],
/// );
/// ```
class SecurityConfig {
  const SecurityConfig({
    this.enabled = false,
    this.guard,
    this.corsOrigins,
    this.securityHeaders = true,
    this.cacheTtl = const Duration(minutes: 5),
    this.logAccess = false,
  });

  /// Whether the Swagger / OpenAPI endpoints are active.
  ///
  /// When `false` (the default), every handler returns **404 Not Found**.
  /// This prevents accidental exposure in production.
  ///
  /// The value can be driven by an environment variable so that deployment
  /// controls the switch without code changes:
  ///
  /// ```dart
  /// SecurityConfig(
  ///   enabled: Platform.environment['OPEN_API_ENABLED'] == 'true',
  /// )
  /// ```
  final bool enabled;

  /// Optional access guard evaluated on every request to a documentation
  /// endpoint. Return `true` to allow, `false` to deny (→ 403 Forbidden).
  ///
  /// When `null` (the default), no extra guard is applied beyond [enabled].
  ///
  /// Examples:
  /// ```dart
  /// // IP allowlist
  /// guard: (req) => req.connectionInfo?.remoteAddress.address == '127.0.0.1',
  ///
  /// // Admin header key
  /// guard: (req) => req.headers['X-Admin-Key'] == Platform.environment['ADMIN_KEY'],
  /// ```
  final bool Function(Request request)? guard;

  /// Allowed CORS origins for documentation endpoints.
  ///
  /// - `null` (default) → No `Access-Control-Allow-Origin` header is added.
  /// - Non-null list → Only requests whose `Origin` header matches one of
  ///   the listed strings receive a `Access-Control-Allow-Origin` response
  ///   header with that specific origin (never a wildcard `*`).
  ///
  /// Example:
  /// ```dart
  /// corsOrigins: ['http://localhost:3000', 'https://admin.example.com'],
  /// ```
  final List<String>? corsOrigins;

  /// When `true` (the default), the following HTTP security headers are added
  /// to every documentation response:
  ///
  /// - `X-Content-Type-Options: nosniff`
  /// - `X-Frame-Options: DENY`
  /// - `Referrer-Policy: strict-origin-when-cross-origin`
  /// - `Permissions-Policy: camera=(), microphone=(), geolocation=()`
  /// - `Content-Security-Policy` (Swagger UI + unpkg CDN safe policy)
  final bool securityHeaders;

  /// How long the generated OpenAPI spec is cached in memory.
  ///
  /// Defaults to 5 minutes. Set to [Duration.zero] to disable caching
  /// (not recommended in production — regenerates on every request).
  ///
  /// Caching prevents CPU/IO spikes when many requests arrive at once,
  /// acting as a basic DoS mitigation for documentation endpoints.
  final Duration cacheTtl;

  /// When `true`, prints a one-line log to `stdout` for each request to a
  /// documentation endpoint. Useful during development. Defaults to `false`.
  final bool logAccess;
}
