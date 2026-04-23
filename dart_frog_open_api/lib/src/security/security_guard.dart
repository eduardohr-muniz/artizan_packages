import 'package:dart_frog/dart_frog.dart';

import 'security_config.dart';

/// Evaluates access control rules from [SecurityConfig] and builds
/// security-related HTTP response headers.
///
/// All methods are pure — they do not mutate state or produce side effects.
abstract final class SecurityGuard {
  /// Returns `true` if the [request] is allowed to access a documentation
  /// endpoint under the given [config].
  ///
  /// Rules applied in order:
  /// 1. If [SecurityConfig.enabled] is `false` → **deny**.
  /// 2. If [SecurityConfig.guard] is set and returns `false` → **deny**.
  /// 3. Otherwise → **allow**.
  static bool isAllowed(Request request, SecurityConfig config) {
    if (!config.enabled) return false;
    final guard = config.guard;
    if (guard != null && !guard(request)) return false;
    return true;
  }

  /// Builds `Access-Control-Allow-Origin` headers for [request] based on
  /// [config].corsOrigins allowlist.
  ///
  /// - Returns an empty map when [SecurityConfig.corsOrigins] is `null`.
  /// - Returns an empty map when the request has no `Origin` header.
  /// - Returns an empty map when the request `Origin` is not in the allowlist.
  /// - **Never** returns a wildcard `*` origin.
  static Map<String, String> corsHeaders(
      Request request, SecurityConfig config) {
    final allowlist = config.corsOrigins;
    if (allowlist == null || allowlist.isEmpty) return {};

    final origin = request.headers['Origin'] ?? request.headers['origin'];
    if (origin == null) return {};
    if (!allowlist.contains(origin)) return {};

    return {'Access-Control-Allow-Origin': origin};
  }

  /// Builds HTTP security response headers based on [config].
  ///
  /// Returns an empty map when [SecurityConfig.securityHeaders] is `false`.
  ///
  /// When enabled, returns:
  /// - `X-Content-Type-Options: nosniff`
  /// - `X-Frame-Options: DENY`
  /// - `Referrer-Policy: strict-origin-when-cross-origin`
  /// - `Permissions-Policy: camera=(), microphone=(), geolocation=()`
  /// - `Content-Security-Policy` (Swagger UI + unpkg CDN safe policy)
  static Map<String, String> securityResponseHeaders(SecurityConfig config) {
    if (!config.securityHeaders) return {};

    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
      'Content-Security-Policy': [
        "default-src 'self'",
        "script-src 'self' 'unsafe-inline' https://unpkg.com https://cdn.jsdelivr.net",
        "style-src 'self' 'unsafe-inline' https://unpkg.com https://cdn.jsdelivr.net https://fonts.googleapis.com",
        "img-src 'self' data: https://unpkg.com https://cdn.jsdelivr.net",
        "font-src 'self' https://unpkg.com https://cdn.jsdelivr.net https://fonts.gstatic.com",
        "connect-src 'self'",
        "frame-ancestors 'none'",
      ].join('; '),
    };
  }
}
