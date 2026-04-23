import 'package:test/test.dart';

import '../../lib/src/security/input_sanitizer.dart';

void main() {
  group('InputSanitizer', () {
    group('escapeForJs', () {
      test('returns plain string unchanged', () {
        expect(InputSanitizer.escapeForJs('/swagger/json'), equals('/swagger/json'));
      });

      test('escapes double quotes', () {
        expect(InputSanitizer.escapeForJs('"hello"'), equals('\\"hello\\"'));
      });

      test('escapes single quotes', () {
        expect(InputSanitizer.escapeForJs("it's"), equals(r"it\'s"));
      });

      test('escapes backslashes', () {
        expect(InputSanitizer.escapeForJs(r'a\b'), equals(r'a\\b'));
      });

      test('escapes newline characters', () {
        expect(InputSanitizer.escapeForJs('line1\nline2'), equals(r'line1\nline2'));
      });

      test('escapes carriage return characters', () {
        expect(InputSanitizer.escapeForJs('line1\rline2'), equals(r'line1\rline2'));
      });

      test('escapes < to prevent </script> injection', () {
        expect(InputSanitizer.escapeForJs('<script>'), contains(r'\x3c'));
      });

      test('escapes > to prevent </script> injection', () {
        expect(InputSanitizer.escapeForJs('>'), contains(r'\x3e'));
      });

      test('XSS payload is neutralized', () {
        const xss = '"/></script><script>alert(1)</script>';
        final result = InputSanitizer.escapeForJs(xss);
        expect(result, isNot(contains('</script>')));
        expect(result, isNot(contains('<script>')));
      });

      test('handles empty string', () {
        expect(InputSanitizer.escapeForJs(''), isEmpty);
      });
    });

    group('escapeForHtml', () {
      test('returns plain string unchanged', () {
        expect(InputSanitizer.escapeForHtml('My API'), equals('My API'));
      });

      test('escapes & ampersand', () {
        expect(InputSanitizer.escapeForHtml('A & B'), equals('A &amp; B'));
      });

      test('escapes < less-than', () {
        expect(InputSanitizer.escapeForHtml('<tag>'), equals('&lt;tag&gt;'));
      });

      test('escapes > greater-than', () {
        expect(InputSanitizer.escapeForHtml('a > b'), equals('a &gt; b'));
      });

      test('escapes double quotes', () {
        expect(InputSanitizer.escapeForHtml('"quoted"'), equals('&quot;quoted&quot;'));
      });

      test('escapes single quotes', () {
        expect(InputSanitizer.escapeForHtml("it's"), equals('it&#x27;s'));
      });

      test('XSS script tag is escaped', () {
        const xss = '<script>alert(1)</script>';
        final result = InputSanitizer.escapeForHtml(xss);
        expect(result, isNot(contains('<script>')));
        expect(result, contains('&lt;script&gt;'));
      });

      test('handles empty string', () {
        expect(InputSanitizer.escapeForHtml(''), isEmpty);
      });
    });

    group('sanitizeSpecUrl', () {
      test('returns valid relative URL unchanged', () {
        expect(InputSanitizer.sanitizeSpecUrl('/swagger/json'), equals('/swagger/json'));
      });

      test('returns valid absolute URL unchanged', () {
        expect(
          InputSanitizer.sanitizeSpecUrl('https://api.example.com/openapi'),
          equals('https://api.example.com/openapi'),
        );
      });

      test('returns fallback for empty string', () {
        expect(InputSanitizer.sanitizeSpecUrl(''), equals('/openapi'));
      });

      test('strips double quotes from URL', () {
        final result = InputSanitizer.sanitizeSpecUrl('/api"json');
        expect(result, isNot(contains('"')));
      });

      test('strips script injection from URL', () {
        const malicious = '"/><script>alert(1)</script>';
        final result = InputSanitizer.sanitizeSpecUrl(malicious);
        expect(result, isNot(contains('<script>')));
      });
    });
  });
}
