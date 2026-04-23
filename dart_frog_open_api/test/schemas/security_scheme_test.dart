import '../../lib/dart_frog_open_api.dart';
import 'package:test/test.dart';

void main() {
  // ── Gap 11 — SecurityScheme const ────────────────────────────────────────────

  group('SecurityScheme const constructors', () {
    test('ApiKeyScheme can be used in const context', () {
      const scheme = ApiKeyScheme(name: 'X-API-Key', location: 'header');
      expect(scheme.toJson()['type'], 'apiKey');
      expect(scheme.toJson()['name'], 'X-API-Key');
      expect(scheme.toJson()['in'], 'header');
    });

    test('BearerScheme can be used in const context', () {
      const scheme = BearerScheme();
      expect(scheme.toJson()['type'], 'http');
      expect(scheme.toJson()['scheme'], 'bearer');
    });

    test('BasicScheme can be used in const context', () {
      const scheme = BasicScheme();
      expect(scheme.toJson()['type'], 'http');
      expect(scheme.toJson()['scheme'], 'basic');
    });

    test('ApiKeyScheme with query location', () {
      const scheme = ApiKeyScheme(name: 'api_key', location: 'query');
      expect(scheme.toJson()['in'], 'query');
      expect(scheme.postmanHeader('cred'), isNull);
    });

    test('ApiKeyScheme header returns postman header', () {
      const scheme = ApiKeyScheme(name: 'X-API-Key', location: 'header');
      final header = scheme.postmanHeader('apiKey');
      expect(header, isNotNull);
      expect(header!['key'], 'X-API-Key');
      expect(header['value'], '{{apiKey}}');
    });

    test('BearerScheme postmanHeader returns Authorization Bearer', () {
      const scheme = BearerScheme();
      final header = scheme.postmanHeader('bearerToken');
      expect(header!['key'], 'Authorization');
      expect(header['value'], 'Bearer {{bearerToken}}');
    });

    test('static factory apiKeyHeader still works for backwards compat', () {
      final scheme = SecurityScheme.apiKeyHeader('X-Custom');
      expect(scheme.toJson()['type'], 'apiKey');
      expect(scheme.toJson()['name'], 'X-Custom');
    });

    test('static bearer constant still works', () {
      const scheme = SecurityScheme.bearer;
      expect(scheme.toJson()['type'], 'http');
    });
  });
}
