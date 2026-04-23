import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../../lib/src/security/security_config.dart';
import '../../lib/src/security/security_guard.dart';

class _MockRequest extends Mock implements Request {}

void main() {
  group('SecurityGuard', () {
    late _MockRequest request;

    setUp(() {
      request = _MockRequest();
    });

    group('isAllowed', () {
      group('when enabled is false', () {
        test('returns false regardless of guard', () {
          const config = SecurityConfig(enabled: false);
          expect(SecurityGuard.isAllowed(request, config), isFalse);
        });

        test('returns false even with permissive guard', () {
          final config = SecurityConfig(
            enabled: false,
            guard: (_) => true,
          );
          expect(SecurityGuard.isAllowed(request, config), isFalse);
        });
      });

      group('when enabled is true', () {
        test('returns true when no guard is set', () {
          const config = SecurityConfig(enabled: true);
          expect(SecurityGuard.isAllowed(request, config), isTrue);
        });

        test('returns true when guard returns true', () {
          final config = SecurityConfig(
            enabled: true,
            guard: (_) => true,
          );
          expect(SecurityGuard.isAllowed(request, config), isTrue);
        });

        test('returns false when guard returns false', () {
          final config = SecurityConfig(
            enabled: true,
            guard: (_) => false,
          );
          expect(SecurityGuard.isAllowed(request, config), isFalse);
        });

        test('guard receives the request object', () {
          Request? capturedRequest;
          final config = SecurityConfig(
            enabled: true,
            guard: (req) {
              capturedRequest = req;
              return true;
            },
          );
          SecurityGuard.isAllowed(request, config);
          expect(capturedRequest, same(request));
        });
      });
    });

    group('corsHeaders', () {
      test('returns empty map when corsOrigins is null', () {
        const config = SecurityConfig(enabled: true, corsOrigins: null);
        when(() => request.headers).thenReturn({});
        final headers = SecurityGuard.corsHeaders(request, config);
        expect(headers, isEmpty);
      });

      test('returns empty map when corsOrigins is empty list', () {
        const config = SecurityConfig(enabled: true, corsOrigins: []);
        when(() => request.headers).thenReturn({'Origin': 'http://localhost:3000'});
        final headers = SecurityGuard.corsHeaders(request, config);
        expect(headers, isEmpty);
      });

      test('returns CORS header when origin matches allowlist', () {
        const config = SecurityConfig(
          enabled: true,
          corsOrigins: ['http://localhost:3000'],
        );
        when(() => request.headers).thenReturn({'Origin': 'http://localhost:3000'});
        final headers = SecurityGuard.corsHeaders(request, config);
        expect(headers['Access-Control-Allow-Origin'], equals('http://localhost:3000'));
      });

      test('returns specific matching origin, not wildcard', () {
        const config = SecurityConfig(
          enabled: true,
          corsOrigins: ['http://localhost:3000', 'https://admin.example.com'],
        );
        when(() => request.headers).thenReturn({'Origin': 'https://admin.example.com'});
        final headers = SecurityGuard.corsHeaders(request, config);
        expect(headers['Access-Control-Allow-Origin'], equals('https://admin.example.com'));
        expect(headers['Access-Control-Allow-Origin'], isNot(equals('*')));
      });

      test('returns empty map when origin is not in allowlist', () {
        const config = SecurityConfig(
          enabled: true,
          corsOrigins: ['http://localhost:3000'],
        );
        when(() => request.headers).thenReturn({'Origin': 'https://evil.com'});
        final headers = SecurityGuard.corsHeaders(request, config);
        expect(headers, isEmpty);
      });

      test('returns empty map when request has no Origin header', () {
        const config = SecurityConfig(
          enabled: true,
          corsOrigins: ['http://localhost:3000'],
        );
        when(() => request.headers).thenReturn({});
        final headers = SecurityGuard.corsHeaders(request, config);
        expect(headers, isEmpty);
      });

      test('never returns wildcard Access-Control-Allow-Origin', () {
        const config = SecurityConfig(
          enabled: true,
          corsOrigins: ['http://localhost:3000'],
        );
        when(() => request.headers).thenReturn({'Origin': 'http://localhost:3000'});
        final headers = SecurityGuard.corsHeaders(request, config);
        expect(headers['Access-Control-Allow-Origin'], isNot(equals('*')));
      });
    });

    group('securityHeaders', () {
      test('returns empty map when securityHeaders is false', () {
        const config = SecurityConfig(enabled: true, securityHeaders: false);
        final headers = SecurityGuard.securityResponseHeaders(config);
        expect(headers, isEmpty);
      });

      test('includes X-Content-Type-Options: nosniff', () {
        const config = SecurityConfig(enabled: true, securityHeaders: true);
        final headers = SecurityGuard.securityResponseHeaders(config);
        expect(headers['X-Content-Type-Options'], equals('nosniff'));
      });

      test('includes X-Frame-Options: DENY', () {
        const config = SecurityConfig(enabled: true, securityHeaders: true);
        final headers = SecurityGuard.securityResponseHeaders(config);
        expect(headers['X-Frame-Options'], equals('DENY'));
      });

      test('includes Referrer-Policy', () {
        const config = SecurityConfig(enabled: true, securityHeaders: true);
        final headers = SecurityGuard.securityResponseHeaders(config);
        expect(headers['Referrer-Policy'], isNotEmpty);
      });

      test('includes Content-Security-Policy', () {
        const config = SecurityConfig(enabled: true, securityHeaders: true);
        final headers = SecurityGuard.securityResponseHeaders(config);
        expect(headers['Content-Security-Policy'], isNotNull);
        expect(headers['Content-Security-Policy'], isNotEmpty);
      });

      test('CSP allows unpkg.com for Swagger UI CDN assets', () {
        const config = SecurityConfig(enabled: true, securityHeaders: true);
        final headers = SecurityGuard.securityResponseHeaders(config);
        expect(headers['Content-Security-Policy'], contains('unpkg.com'));
      });
    });
  });
}
