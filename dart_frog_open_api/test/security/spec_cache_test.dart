import 'package:test/test.dart';

import '../../lib/src/security/spec_cache.dart';

void main() {
  group('SpecCache', () {
    late SpecCache cache;

    setUp(() {
      cache = SpecCache(ttl: const Duration(minutes: 5));
    });

    group('get', () {
      test('returns null when cache is empty', () {
        expect(cache.get(), isNull);
      });

      test('returns null after invalidation', () {
        cache.set({'openapi': '3.0.0'});
        cache.invalidate();
        expect(cache.get(), isNull);
      });

      test('returns the stored spec before TTL expires', () {
        final spec = {'openapi': '3.0.0', 'info': {'title': 'Test'}};
        cache.set(spec);
        expect(cache.get(), equals(spec));
      });

      test('returns null after TTL expires', () async {
        cache = SpecCache(ttl: const Duration(milliseconds: 50));
        cache.set({'openapi': '3.0.0'});
        expect(cache.get(), isNotNull);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(cache.get(), isNull);
      });
    });

    group('set', () {
      test('stores the spec', () {
        final spec = {'openapi': '3.0.0'};
        cache.set(spec);
        expect(cache.get(), equals(spec));
      });

      test('overwrites previous spec', () {
        cache.set({'openapi': '2.0.0'});
        cache.set({'openapi': '3.0.0'});
        expect(cache.get()!['openapi'], equals('3.0.0'));
      });

      test('resets TTL timer on each set', () async {
        cache = SpecCache(ttl: const Duration(milliseconds: 100));
        cache.set({'openapi': '3.0.0'});

        // Re-set before expiry
        await Future<void>.delayed(const Duration(milliseconds: 60));
        cache.set({'openapi': '3.0.1'});

        // At 120ms total — old TTL would have expired, but new one resets it
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(cache.get(), isNotNull);
        expect(cache.get()!['openapi'], equals('3.0.1'));
      });
    });

    group('invalidate', () {
      test('clears cached spec', () {
        cache.set({'openapi': '3.0.0'});
        expect(cache.get(), isNotNull);
        cache.invalidate();
        expect(cache.get(), isNull);
      });

      test('is safe to call when cache is already empty', () {
        expect(() => cache.invalidate(), returnsNormally);
      });
    });

    group('with zero TTL', () {
      test('get always returns null when TTL is zero', () {
        final zeroCache = SpecCache(ttl: Duration.zero);
        zeroCache.set({'openapi': '3.0.0'});
        expect(zeroCache.get(), isNull);
      });
    });
  });
}
