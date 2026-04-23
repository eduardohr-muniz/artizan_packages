import 'dart:io';

import '../../lib/dart_frog_open_api.dart';
import 'package:test/test.dart';

void main() {
  group('RoutesDirResolver', () {
    group('resolveFrom', () {
      test('resolves "routes" relative to a given base directory', () {
        final base = Directory.systemTemp;
        final resolved = RoutesDirResolver.resolveFrom(base, 'routes');

        expect(resolved.path, equals('${base.path}/routes'));
      });

      test('resolves custom folder name relative to a given base directory', () {
        final base = Directory('/some/project');
        final resolved = RoutesDirResolver.resolveFrom(base, 'my_routes');

        expect(resolved.path, equals('/some/project/my_routes'));
      });

      test('returns absolute path unchanged when given absolute path', () {
        final base = Directory('/irrelevant');
        final resolved = RoutesDirResolver.resolveFrom(base, '/absolute/routes');

        expect(resolved.path, equals('/absolute/routes'));
      });
    });

    group('fromCwd', () {
      test('resolves routes/ relative to current working directory', () {
        final resolved = RoutesDirResolver.fromCwd();
        final expected = '${Directory.current.path}/routes';

        expect(resolved.path, equals(expected));
      });

      test('resolves custom folder relative to current working directory', () {
        final resolved = RoutesDirResolver.fromCwd(folder: 'my_routes');
        final expected = '${Directory.current.path}/my_routes';

        expect(resolved.path, equals(expected));
      });
    });
  });
}
