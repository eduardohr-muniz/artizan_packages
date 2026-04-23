import 'package:test/test.dart';
import 'package:zto/zto.dart';

void main() {
  tearDown(() => Zto.resetErrorFormatter());

  group('ZtoIssue', () {
    test('holds message and field', () {
      const issue = ZtoIssue(message: 'Required', field: 'name');
      expect(issue.message, 'Required');
      expect(issue.field, 'name');
    });

    test('field is optional', () {
      const issue = ZtoIssue(message: 'Invalid');
      expect(issue.field, isNull);
    });

    test('toMap includes message and field', () {
      const issue = ZtoIssue(message: 'Too short', field: 'name');
      expect(issue.toMap(), {'field': 'name', 'message': 'Too short'});
    });

    test('toMap omits field when null', () {
      const issue = ZtoIssue(message: 'General error');
      final map = issue.toMap();
      expect(map.containsKey('field'), isFalse);
      expect(map['message'], 'General error');
    });
  });

  group('ZtoException', () {
    test('holds message and list of issues', () {
      final e = ZtoException(
        message: 'Validation failed',
        issues: const [ZtoIssue(message: 'Required', field: 'name')],
      );
      expect(e.message, 'Validation failed');
      expect(e.issues, hasLength(1));
    });

    test('toMap returns default format', () {
      final e = ZtoException(
        message: 'Validation failed',
        issues: const [
          ZtoIssue(message: 'Must be >= 18', field: 'age'),
          ZtoIssue(message: 'Invalid email', field: 'email'),
        ],
      );

      final map = e.toMap();
      expect(map['statusCode'], 422);
      expect(map['message'], 'Validation failed');
      expect(map['errors'], hasLength(2));
      expect(map['errors'][0]['field'], 'age');
      expect(map['errors'][1]['field'], 'email');
    });

    test('format applies custom formatter to issues', () {
      final e = ZtoException(
        message: 'Fail',
        issues: const [ZtoIssue(message: 'Bad', field: 'name')],
      );

      final result = e.format(
        (issues) => {
          'code': 'VALIDATION_ERROR',
          'fields': issues.map((i) => i.field).toList(),
        },
      );

      expect(result['code'], 'VALIDATION_ERROR');
      expect(result['fields'], ['name']);
    });

    test('toMap uses Zto.errorFormatter when set', () {
      Zto.errorFormatter = (e) => {'custom': true, 'count': e.issues.length};

      final e = ZtoException(
        message: 'Fail',
        issues: const [ZtoIssue(message: 'Bad', field: 'x')],
      );

      expect(e.toMap(), {'custom': true, 'count': 1});
    });

    test('toMap uses default format after resetErrorFormatter', () {
      Zto.errorFormatter = (e) => {'custom': true};
      Zto.resetErrorFormatter();

      final e = ZtoException(
        message: 'Fail',
        issues: const [ZtoIssue(message: 'Bad', field: 'x')],
      );

      expect(e.toMap()['statusCode'], 422);
    });

    test('is a subtype of Exception', () {
      final e = ZtoException(message: 'Fail', issues: const []);
      expect(e, isA<Exception>());
    });

    test('toString includes message', () {
      final e = ZtoException(message: 'Validation failed', issues: const []);
      expect(e.toString(), contains('Validation failed'));
    });
  });

  group('Zto.errorFormatter', () {
    test('is null by default', () {
      expect(Zto.errorFormatter, isNull);
    });

    test('can be set and read', () {
      Zto.errorFormatter = (e) => {};
      expect(Zto.errorFormatter, isNotNull);
    });

    test('resetErrorFormatter sets it back to null', () {
      Zto.errorFormatter = (e) => {};
      Zto.resetErrorFormatter();
      expect(Zto.errorFormatter, isNull);
    });
  });
}
