/// Base for all Zto validator annotations.
///
/// Validators are applied to fields after type checking. Each validator
/// may define an optional [message] for custom error output.
abstract class ZtoValidator {
  const ZtoValidator({this.message});

  /// Optional custom error message. If null, a default is used.
  final String? message;
}

// ── String validators ──────────────────────────────────────────────────────

/// Enforces minimum string length.
///
/// Validation fails when the string has fewer than [n] characters.
///
/// Example:
/// ```dart
/// @ZString('name')
/// @ZMinLength(2)
/// final String name; // 'John' -> passes; 'J' -> fails
/// ```
class ZMinLength extends ZtoValidator {
  const ZMinLength(this.n, {super.message});
  final int n;
}

/// Enforces maximum string length.
///
/// Validation fails when the string has more than [n] characters.
///
/// Example:
/// ```dart
/// @ZString('bio')
/// @ZMaxLength(500)
/// final String bio; // 'Short' -> passes; 501 chars -> fails
/// ```
class ZMaxLength extends ZtoValidator {
  const ZMaxLength(this.n, {super.message});
  final int n;
}

/// Enforces exact string length.
///
/// Validation fails when the string length differs from [n].
///
/// Example:
/// ```dart
/// @ZString('code')
/// @ZLength(4)
/// final String code; // '1234' -> passes; '123' or '12345' -> fails
/// ```
class ZLength extends ZtoValidator {
  const ZLength(this.n, {super.message});
  final int n;
}

/// Validates e-mail format.
///
/// Uses a regex that accepts common e-mail patterns.
///
/// Example:
/// ```dart
/// @ZString('email')
/// @ZEmail()
/// final String email; // 'a@b.com' -> passes; 'invalid' -> fails
/// ```
class ZEmail extends ZtoValidator {
  const ZEmail({super.message});
}

/// Validates UUID v4 format.
///
/// Accepts lowercase and uppercase hex with standard hyphenation.
///
/// Example:
/// ```dart
/// @ZString('id')
/// @ZUuid()
/// final String id; // '550e8400-...' -> passes; 'x' -> fails
/// ```
class ZUuid extends ZtoValidator {
  const ZUuid({super.message});
}

/// Validates URL format.
///
/// Requires a scheme (e.g. `http`, `https`, `ftp`).
///
/// Example:
/// ```dart
/// @ZString('website')
/// @ZUrl()
/// final String website; // 'https://example.com' -> passes; 'not-a-url' -> fails
/// ```
class ZUrl extends ZtoValidator {
  const ZUrl({super.message});
}

/// Validates that the value matches the given [regex] pattern.
///
/// [regex] is a string passed to [RegExp].
///
/// Example:
/// ```dart
/// @ZString('code')
/// @ZPattern(r'^\d{4}$')
/// final String code; // '1234' -> passes; 'abc' -> fails
/// ```
class ZPattern extends ZtoValidator {
  const ZPattern(this.regex, {super.message});
  final String regex;
}

/// Validates that the string starts with [prefix].
///
/// Example:
/// ```dart
/// @ZString('url')
/// @ZStartsWith('https://')
/// final String url; // 'https://x.com' -> passes; 'http://x.com' -> fails
/// ```
class ZStartsWith extends ZtoValidator {
  const ZStartsWith(this.prefix, {super.message});
  final String prefix;
}

/// Validates that the string ends with [suffix].
///
/// Example:
/// ```dart
/// @ZString('domain')
/// @ZEndsWith('.com')
/// final String domain; // 'example.com' -> passes; 'example.org' -> fails
/// ```
class ZEndsWith extends ZtoValidator {
  const ZEndsWith(this.suffix, {super.message});
  final String suffix;
}

/// Validates that the string contains [substring].
///
/// Example:
/// ```dart
/// @ZString('text')
/// @ZIncludes('foo')
/// final String text; // 'hello foo' -> passes; 'hello bar' -> fails
/// ```
class ZIncludes extends ZtoValidator {
  const ZIncludes(this.substring, {super.message});
  final String substring;
}

/// Validates Base64 encoded string.
///
/// Uses [base64Decode] to verify the format.
///
/// Example:
/// ```dart
/// @ZString('data')
/// @ZBase64()
/// final String data; // 'SGVsbG8=' -> passes; '!!!' -> fails
/// ```
class ZBase64 extends ZtoValidator {
  const ZBase64({super.message});
}

/// Validates hexadecimal string.
///
/// Accepts only `0-9` and `a-f` (case insensitive).
///
/// Example:
/// ```dart
/// @ZString('hash')
/// @ZHex()
/// final String hash; // 'deadbeef' -> passes; 'ghijk' -> fails
/// ```
class ZHex extends ZtoValidator {
  const ZHex({super.message});
}

/// Validates IPv4 address format.
///
/// Each octet must be 0–255.
///
/// Example:
/// ```dart
/// @ZString('ip')
/// @ZIpv4()
/// final String ip; // '192.168.1.1' -> passes; '256.1.1.1' -> fails
/// ```
class ZIpv4 extends ZtoValidator {
  const ZIpv4({super.message});
}

/// Validates IPv6 address format.
///
/// Supports full and compressed notation.
///
/// Example:
/// ```dart
/// @ZString('ip')
/// @ZIpv6()
/// final String ip; // '2001:0db8::1' -> passes; 'invalid' -> fails
/// ```
class ZIpv6 extends ZtoValidator {
  const ZIpv6({super.message});
}

/// Validates HTTP or HTTPS URL.
///
/// Rejects other schemes (e.g. `ftp`, `file`).
///
/// Example:
/// ```dart
/// @ZString('callback')
/// @ZHttpUrl()
/// final String callback; // 'https://x.com' -> passes; 'ftp://x.com' -> fails
/// ```
class ZHttpUrl extends ZtoValidator {
  const ZHttpUrl({super.message});
}

/// Validates JWT format.
///
/// Requires exactly three dot-separated, non-empty parts.
///
/// Example:
/// ```dart
/// @ZString('token')
/// @ZJwt()
/// final String token; // 'a.b.c' (3 parts) -> passes; 'a.b' -> fails
/// ```
class ZJwt extends ZtoValidator {
  const ZJwt({super.message});
}

/// Validates ISO 8601 date string (YYYY-MM-DD).
///
/// Rejects invalid dates (e.g. 2024-13-01).
///
/// Example:
/// ```dart
/// @ZString('birthDate')
/// @ZIsoDate()
/// final String birthDate; // '2024-03-15' -> passes; '2024-13-01' -> fails
/// ```
class ZIsoDate extends ZtoValidator {
  const ZIsoDate({super.message});
}

/// Validates ISO 8601 datetime string.
///
/// Requires the `T` separator between date and time.
///
/// Example:
/// ```dart
/// @ZString('timestamp')
/// @ZIsoDateTime()
/// final String timestamp; // '2024-03-15T10:00:00Z' -> passes; '2024-03-15' -> fails
/// ```
class ZIsoDateTime extends ZtoValidator {
  const ZIsoDateTime({super.message});
}

// ── Numeric validators ─────────────────────────────────────────────────────

/// Validates that the value is an integer (no fractional part).
///
/// Accepts both [int] and [double] with zero fractional part.
///
/// Example:
/// ```dart
/// @ZDouble('qty')
/// @ZInteger()
/// final double qty; // 10.0 -> passes; 9.99 -> fails
/// ```
class ZInteger extends ZtoValidator {
  const ZInteger({super.message});
}

/// Validates that the value is greater than or equal to zero.
///
/// Example:
/// ```dart
/// @ZInt('count')
/// @ZNonNegative()
/// final int count; // 0, 1 -> passes; -1 -> fails
/// ```
class ZNonNegative extends ZtoValidator {
  const ZNonNegative({super.message});
}

/// Enforces minimum numeric value (inclusive).
///
/// Validation fails when the value is less than [n].
///
/// Example:
/// ```dart
/// @ZInt('age')
/// @ZMin(18)
/// final int age; // 18, 25 -> passes; 17 -> fails
/// ```
class ZMin extends ZtoValidator {
  const ZMin(this.n, {super.message});
  final num n;
}

/// Enforces maximum numeric value (inclusive).
///
/// Validation fails when the value is greater than [n].
///
/// Example:
/// ```dart
/// @ZInt('age')
/// @ZMax(120)
/// final int age; // 100, 120 -> passes; 121 -> fails
/// ```
class ZMax extends ZtoValidator {
  const ZMax(this.n, {super.message});
  final num n;
}

/// Validates that the value is greater than zero.
///
/// Example:
/// ```dart
/// @ZDouble('price')
/// @ZPositive()
/// final double price; // 9.99 -> passes; 0, -1 -> fails
/// ```
class ZPositive extends ZtoValidator {
  const ZPositive({super.message});
}

/// Validates that the value is less than zero.
///
/// Example:
/// ```dart
/// @ZDouble('temp')
/// @ZNegative()
/// final double temp; // -5.0 -> passes; 5.0 -> fails
/// ```
class ZNegative extends ZtoValidator {
  const ZNegative({super.message});
}

/// Validates that the value is a multiple of [n].
///
/// Example:
/// ```dart
/// @ZInt('quantity')
/// @ZMultipleOf(5)
/// final int quantity; // 10, 15 -> passes; 12 -> fails
/// ```
class ZMultipleOf extends ZtoValidator {
  const ZMultipleOf(this.n, {super.message});
  final num n;
}

/// Validates that the value is less than or equal to zero.
///
/// Example:
/// ```dart
/// @ZInt('delta')
/// @ZNonPositive()
/// final int delta; // 0, -5 -> passes; 1 -> fails
/// ```
class ZNonPositive extends ZtoValidator {
  const ZNonPositive({super.message});
}

/// Validates that the value is finite.
///
/// Rejects [double.infinity], [double.negativeInfinity], and [double.nan].
///
/// Example:
/// ```dart
/// @ZDouble('value')
/// @ZFinite()
/// final double value; // 3.14 -> passes; infinity, nan -> fails
/// ```
class ZFinite extends ZtoValidator {
  const ZFinite({super.message});
}

/// Validates that the value is within JavaScript safe integer range.
///
/// Accepts values between -(2^53 - 1) and (2^53 - 1) inclusive.
///
/// Example:
/// ```dart
/// @ZInt('id')
/// @ZSafeInt()
/// final int id; // 9007199254740991 -> passes; 9007199254740992 -> fails
/// ```
class ZSafeInt extends ZtoValidator {
  const ZSafeInt({super.message});
}

/// Validates that the string is already in uppercase form.
///
/// Passes when [value.toUpperCase()] equals [value] (e.g. "ABC", "ABC123").
///
/// Example:
/// ```dart
/// @ZString('code')
/// @ZUppercase()
/// final String code; // 'ABC', 'ABC123' -> passes; 'Abc' -> fails
/// ```
class ZUppercase extends ZtoValidator {
  const ZUppercase({super.message});
}

/// Validates that the string is already in lowercase form.
///
/// Passes when [value.toLowerCase()] equals [value] (e.g. "abc", "abc123").
///
/// Example:
/// ```dart
/// @ZString('slug')
/// @ZLowercase()
/// final String slug; // 'abc', 'abc123' -> passes; 'Abc' -> fails
/// ```
class ZLowercase extends ZtoValidator {
  const ZLowercase({super.message});
}

/// Validates URL slug format.
///
/// Accepts lowercase letters, digits, and hyphens (e.g. `my-blog-post`).
///
/// Example:
/// ```dart
/// @ZString('slug')
/// @ZSlug()
/// final String slug; // 'my-blog-post' -> passes; 'Invalid Slug!' -> fails
/// ```
class ZSlug extends ZtoValidator {
  const ZSlug({super.message});
}

/// Validates that the string contains only alphanumeric characters.
///
/// Accepts `a-z`, `A-Z`, and `0-9` only.
///
/// Example:
/// ```dart
/// @ZString('code')
/// @ZAlphanumeric()
/// final String code; // 'abc123' -> passes; 'abc-123' -> fails
/// ```
class ZAlphanumeric extends ZtoValidator {
  const ZAlphanumeric({super.message});
}
