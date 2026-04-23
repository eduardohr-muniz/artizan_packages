import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import '../../../open_api/config.dart';
import '../../../open_api/security_refs.dart';

import '../../../open_api/paths.dart';
import '../../../routes/swagger/json.dart' as route;
import '../../../main.dart' as main_file;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  setUp(() async {
    main_file.openApi = DartFrogOpenApi(
      config: OpenApiConfig(
        info: apiInfo,
        pathSchemas: apiPathSchemas,
        declaredSecuritySchemes: openapiDeclaredSecuritySchemes,
        globalSecurity: [openapiBearer.componentKey],
        security: const SecurityConfig(enabled: true),
        specUrl: '/swagger/json',
      ),
    );
  });

  tearDown(() {});

  group('GET /swagger/json', () {
    test('responds with 200 and JSON OpenAPI spec', () async {
      final context = _MockRequestContext();
      final request = Request('GET', Uri.parse('http://localhost/swagger/json'));
      when(() => context.request).thenReturn(request);

      final raw = route.onRequest(context);
      final res = raw is Future<Response> ? await raw : raw;
      expect(res.statusCode, equals(200));
      expect(res.headers['content-type'], contains('application/json'));
      expect(await res.body(), contains('3.0.0'));
    });
  });
}
