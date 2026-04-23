/// Input sanitization utilities for security-sensitive output contexts.
///
/// All methods are pure functions with no side effects — safe to use in
/// const/static contexts.
abstract final class InputSanitizer {
  /// Escapes [value] for safe embedding inside a JavaScript string literal.
  ///
  /// Prevents XSS when interpolating values into `<script>` blocks or
  /// inline event handlers. Covers:
  /// - Backslash escaping (must come first)
  /// - Double/single quote escaping
  /// - Newline/carriage-return escaping
  /// - `<` / `>` hex-escaped to prevent `</script>` injection
  static String escapeForJs(String value) {
    return value
        .replaceAll(r'\', r'\\') // must be first
        .replaceAll('"', '\\"')
        .replaceAll("'", r"\'")
        .replaceAll('<', r'\x3c')
        .replaceAll('>', r'\x3e')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }

  /// Escapes [value] for safe embedding inside an HTML document.
  ///
  /// Prevents XSS when inserting user-controlled strings into HTML attributes
  /// or text content. Covers the five mandatory HTML escape sequences.
  static String escapeForHtml(String value) {
    return value
        .replaceAll('&', '&amp;') // must be first
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Validates and sanitizes a spec URL for safe use in `SwaggerUIBundle`.
  ///
  /// - Returns [fallback] when [value] is empty or blank.
  /// - Strips characters that could break out of a JS string literal.
  static String sanitizeSpecUrl(String value, {String fallback = '/openapi'}) {
    if (value.trim().isEmpty) return fallback;
    // Remove characters that could inject JS or break HTML attributes
    final sanitized = value
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');
    return sanitized.isEmpty ? fallback : sanitized;
  }
}
