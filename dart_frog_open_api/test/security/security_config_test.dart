import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../../lib/src/security/security_config.dart';

class _MockRequest extends Mock implements Request {}

void main() {
  group('SecurityConfig', () {
    group('defaults', () {
      test('enabled is false by default', () {
        const config = SecurityConfig();
        expect(config.enabled, isFalse);
      });

      test('guard is null by default', () {
        const config = SecurityConfig();
        expect(config.guard, isNull);
      });

      test('corsOrigins is null by default', () {
        const config = SecurityConfig();
        expect(config.corsOrigins, isNull);
      });

      test('securityHeaders is true by default', () {
        const config = SecurityConfig();
        expect(config.securityHeaders, isTrue);
      });

      test('cacheTtl defaults to 5 minutes', () {
        const config = SecurityConfig();
        expect(config.cacheTtl, equals(const Duration(minutes: 5)));
      });

      test('logAccess is false by default', () {
        const config = SecurityConfig();
        expect(config.logAccess, isFalse);
      });
    });

    group('enabled field', () {
      test('can be set to true', () {
        const config = SecurityConfig(enabled: true);
        expect(config.enabled, isTrue);
      });

      test('can be set to false explicitly', () {
        const config = SecurityConfig(enabled: false);
        expect(config.enabled, isFalse);
      });
    });

    group('guard field', () {
      test('accepts a guard function', () {
        final config = SecurityConfig(
          enabled: true,
          guard: (req) => true,
        );
        expect(config.guard, isNotNull);
      });

      test('guard function is callable and returns bool', () {
        final request = _MockRequest();
        final config = SecurityConfig(
          enabled: true,
          guard: (req) => req == request,
        );
        expect(config.guard!(request), isTrue);
        expect(config.guard!(_MockRequest()), isFalse);
      });
    });

    group('corsOrigins field', () {
      test('accepts a list of origins', () {
        const config = SecurityConfig(
          corsOrigins: ['http://localhost:3000', 'https://admin.example.com'],
        );
        expect(config.corsOrigins, hasLength(2));
        expect(config.corsOrigins, contains('http://localhost:3000'));
      });

      test('accepts empty list', () {
        const config = SecurityConfig(corsOrigins: []);
        expect(config.corsOrigins, isEmpty);
      });
    });

    group('cacheTtl field', () {
      test('can be set to zero to disable caching', () {
        const config = SecurityConfig(cacheTtl: Duration.zero);
        expect(config.cacheTtl, equals(Duration.zero));
      });

      test('can be set to custom duration', () {
        const config = SecurityConfig(cacheTtl: Duration(minutes: 30));
        expect(config.cacheTtl, equals(const Duration(minutes: 30)));
      });
    });

    group('is const-constructible', () {
      test('can be created as compile-time constant', () {
        // This verifies the class can be used in const context
        const config = SecurityConfig(
          enabled: true,
          corsOrigins: ['http://localhost:3000'],
          securityHeaders: true,
          cacheTtl: Duration(minutes: 10),
          logAccess: true,
        );
        expect(config.enabled, isTrue);
      });
    });
  });
}
