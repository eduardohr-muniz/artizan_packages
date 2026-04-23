import 'package:test/test.dart';

import '../../lib/src/internal/collection_utils.dart';

void main() {
  group('toFilename', () {
    test('lowercases and replaces spaces with underscores', () {
      expect(toFilename('Say Hello'), equals('say_hello'));
    });

    test('removes trailing underscores', () {
      expect(toFilename('hello!'), equals('hello'));
    });

    test('collapses multiple non-alphanumeric chars', () {
      expect(toFilename('foo -- bar'), equals('foo_bar'));
    });

    test('handles already-clean names', () {
      expect(toFilename('myapi'), equals('myapi'));
    });
  });

  group('tagFromPath', () {
    test('returns first non-version, non-param segment', () {
      expect(tagFromPath('/v1/users'), equals('users'));
    });

    test('skips version prefix v2', () {
      expect(tagFromPath('/v2/orders/{id}'), equals('orders'));
    });

    test('returns root segment when path is version-only', () {
      expect(tagFromPath('/v1'), equals('v1'));
    });

    test('returns Root for empty path', () {
      expect(tagFromPath('/'), equals('Root'));
    });

    test('skips path params', () {
      expect(tagFromPath('/{id}/details'), equals('details'));
    });
  });

  group('varNameForScheme', () {
    test('BearerAuth → bearerToken', () {
      expect(varNameForScheme('BearerAuth'), equals('bearerToken'));
    });

    test('bearer (lowercase) → bearerToken', () {
      expect(varNameForScheme('bearer'), equals('bearerToken'));
    });

    test('BasicAuth → basicAuth', () {
      expect(varNameForScheme('BasicAuth'), equals('basicAuth'));
    });

    test('ApiKeyAuth → apiKey', () {
      expect(varNameForScheme('ApiKeyAuth'), equals('apiKey'));
    });

    test('empty-after-cleaning → credential', () {
      expect(varNameForScheme('Auth'), equals('credential'));
    });
  });
}
