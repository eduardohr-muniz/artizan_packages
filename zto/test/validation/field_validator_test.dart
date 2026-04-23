import 'package:test/test.dart';
import 'package:zto/zto.dart';

FieldDescriptor _descriptor(
  ZtoField field, {
  List<ZtoValidator> validators = const [],
  bool isNullable = false,
}) =>
    FieldDescriptor(
      fieldAnnotation: field,
      validators: validators,
      isNullable: isNullable,
    );

void main() {
  group('FieldValidator.validate', () {
    group('type checking', () {
      test('ZString accepts String value', () {
        final d = _descriptor(const ZString(mapKey: 'name'));
        expect(FieldValidator.validate(d, 'John'), isEmpty);
      });

      test('ZString rejects non-String', () {
        final d = _descriptor(const ZString(mapKey: 'name'));
        final issues = FieldValidator.validate(d, 42);
        expect(issues, hasLength(1));
        expect(issues.first.field, 'name');
      });

      test('ZInt accepts int value', () {
        final d = _descriptor(const ZInt(mapKey: 'age'));
        expect(FieldValidator.validate(d, 25), isEmpty);
      });

      test('ZInt rejects non-int', () {
        final d = _descriptor(const ZInt(mapKey: 'age'));
        expect(FieldValidator.validate(d, 'twenty'), isNotEmpty);
      });

      test('ZDouble accepts double', () {
        final d = _descriptor(const ZDouble(mapKey: 'price'));
        expect(FieldValidator.validate(d, 9.99), isEmpty);
      });

      test('ZDouble accepts int as num (coerce)', () {
        final d = _descriptor(const ZDouble(mapKey: 'price'));
        expect(FieldValidator.validate(d, 10), isEmpty);
      });

      test('ZNum accepts int', () {
        final d = _descriptor(const ZNum(mapKey: 'score'));
        expect(FieldValidator.validate(d, 5), isEmpty);
      });

      test('ZNum accepts double', () {
        final d = _descriptor(const ZNum(mapKey: 'score'));
        expect(FieldValidator.validate(d, 5.5), isEmpty);
      });

      test('ZBool accepts bool', () {
        final d = _descriptor(const ZBool(mapKey: 'active'));
        expect(FieldValidator.validate(d, true), isEmpty);
      });

      test('ZBool rejects non-bool', () {
        final d = _descriptor(const ZBool(mapKey: 'active'));
        expect(FieldValidator.validate(d, 1), isNotEmpty);
      });

      test('ZEnum accepts value in allowed list', () {
        final d = _descriptor(const ZEnum(mapKey: 'role', values: ['admin', 'viewer']));
        expect(FieldValidator.validate(d, 'admin'), isEmpty);
      });

      test('ZEnum rejects value not in list', () {
        final d = _descriptor(const ZEnum(mapKey: 'role', values: ['admin', 'viewer']));
        final issues = FieldValidator.validate(d, 'superuser');
        expect(issues, hasLength(1));
        expect(issues.first.field, 'role');
      });
    });

    group('nullable fields', () {
      test('nullable field accepts null', () {
        final d = _descriptor(const ZString(mapKey: 'email'), isNullable: true);
        expect(FieldValidator.validate(d, null), isEmpty);
      });

      test('nullable field accepts absent (null passed)', () {
        final d = _descriptor(const ZString(mapKey: 'email'), isNullable: true);
        expect(FieldValidator.validate(d, null), isEmpty);
      });

      test('required field rejects null', () {
        final d = _descriptor(const ZString(mapKey: 'name'));
        final issues = FieldValidator.validate(d, null);
        expect(issues, hasLength(1));
        expect(issues.first.message, contains('required'));
      });
    });

    group('string validators', () {
      test('@ZMinLength passes when length >= n', () {
        final d = _descriptor(const ZString(mapKey: 'name'), validators: [const ZMinLength(3)]);
        expect(FieldValidator.validate(d, 'John'), isEmpty);
      });

      test('@ZMinLength fails when length < n', () {
        final d = _descriptor(const ZString(mapKey: 'name'), validators: [const ZMinLength(5)]);
        expect(FieldValidator.validate(d, 'Jo'), isNotEmpty);
      });

      test('@ZMaxLength passes when length <= n', () {
        final d = _descriptor(const ZString(mapKey: 'name'), validators: [const ZMaxLength(10)]);
        expect(FieldValidator.validate(d, 'John'), isEmpty);
      });

      test('@ZMaxLength fails when length > n', () {
        final d = _descriptor(const ZString(mapKey: 'name'), validators: [const ZMaxLength(3)]);
        expect(FieldValidator.validate(d, 'Jonathan'), isNotEmpty);
      });

      test('@ZLength passes when length equals n', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZLength(4)]);
        expect(FieldValidator.validate(d, '1234'), isEmpty);
      });

      test('@ZLength fails when length differs from n', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZLength(4)]);
        expect(FieldValidator.validate(d, '123'), isNotEmpty);
        expect(FieldValidator.validate(d, '12345'), isNotEmpty);
      });

      test('@Email passes valid email', () {
        final d = _descriptor(const ZString(mapKey: 'email'), validators: [const ZEmail()]);
        expect(FieldValidator.validate(d, 'john@example.com'), isEmpty);
      });

      test('@Email fails invalid email', () {
        final d = _descriptor(const ZString(mapKey: 'email'), validators: [const ZEmail()]);
        expect(FieldValidator.validate(d, 'notanemail'), isNotEmpty);
      });

      test('@Uuid passes valid UUID', () {
        final d = _descriptor(const ZString(mapKey: 'id'), validators: [const ZUuid()]);
        expect(FieldValidator.validate(d, '550e8400-e29b-41d4-a716-446655440000'), isEmpty);
      });

      test('@Uuid fails invalid UUID', () {
        final d = _descriptor(const ZString(mapKey: 'id'), validators: [const ZUuid()]);
        expect(FieldValidator.validate(d, 'not-a-uuid'), isNotEmpty);
      });

      test('@Pattern passes matching value', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZPattern(r'^\d{4}$')]);
        expect(FieldValidator.validate(d, '1234'), isEmpty);
      });

      test('@Pattern fails non-matching value', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZPattern(r'^\d{4}$')]);
        expect(FieldValidator.validate(d, 'abcd'), isNotEmpty);
      });

      test('@ZIsoDate passes valid YYYY-MM-DD', () {
        final d = _descriptor(const ZString(mapKey: 'date'), validators: [const ZIsoDate()]);
        expect(FieldValidator.validate(d, '2024-03-15'), isEmpty);
      });

      test('@ZIsoDate fails invalid date format', () {
        final d = _descriptor(const ZString(mapKey: 'date'), validators: [const ZIsoDate()]);
        expect(FieldValidator.validate(d, '15/03/2024'), isNotEmpty);
        expect(FieldValidator.validate(d, '2024-13-01'), isNotEmpty);
        expect(FieldValidator.validate(d, 'not-a-date'), isNotEmpty);
      });

      test('@ZIsoDateTime passes valid ISO 8601 datetime', () {
        final d = _descriptor(const ZString(mapKey: 'timestamp'), validators: [const ZIsoDateTime()]);
        expect(FieldValidator.validate(d, '2024-03-15T10:30:00Z'), isEmpty);
        expect(FieldValidator.validate(d, '2024-03-15T10:30:00.123Z'), isEmpty);
      });

      test('@ZIsoDateTime fails invalid datetime format', () {
        final d = _descriptor(const ZString(mapKey: 'timestamp'), validators: [const ZIsoDateTime()]);
        expect(FieldValidator.validate(d, '2024-03-15'), isNotEmpty);
        expect(FieldValidator.validate(d, 'invalid'), isNotEmpty);
      });

      test('@ZStartsWith passes when string starts with prefix', () {
        final d = _descriptor(const ZString(mapKey: 'url'), validators: [const ZStartsWith('https://')]);
        expect(FieldValidator.validate(d, 'https://example.com'), isEmpty);
      });

      test('@ZStartsWith fails when string does not start with prefix', () {
        final d = _descriptor(const ZString(mapKey: 'url'), validators: [const ZStartsWith('https://')]);
        expect(FieldValidator.validate(d, 'http://example.com'), isNotEmpty);
      });

      test('@ZEndsWith passes when string ends with suffix', () {
        final d = _descriptor(const ZString(mapKey: 'domain'), validators: [const ZEndsWith('.com')]);
        expect(FieldValidator.validate(d, 'example.com'), isEmpty);
      });

      test('@ZEndsWith fails when string does not end with suffix', () {
        final d = _descriptor(const ZString(mapKey: 'domain'), validators: [const ZEndsWith('.com')]);
        expect(FieldValidator.validate(d, 'example.org'), isNotEmpty);
      });

      test('@ZIncludes passes when string contains substring', () {
        final d = _descriptor(const ZString(mapKey: 'text'), validators: [const ZIncludes('foo')]);
        expect(FieldValidator.validate(d, 'hello foo world'), isEmpty);
      });

      test('@ZIncludes fails when string does not contain substring', () {
        final d = _descriptor(const ZString(mapKey: 'text'), validators: [const ZIncludes('foo')]);
        expect(FieldValidator.validate(d, 'hello bar world'), isNotEmpty);
      });

      test('@ZBase64 passes valid base64', () {
        final d = _descriptor(const ZString(mapKey: 'data'), validators: [const ZBase64()]);
        expect(FieldValidator.validate(d, 'SGVsbG8gV29ybGQ='), isEmpty);
      });

      test('@ZBase64 fails invalid base64', () {
        final d = _descriptor(const ZString(mapKey: 'data'), validators: [const ZBase64()]);
        expect(FieldValidator.validate(d, 'not valid!!'), isNotEmpty);
      });

      test('@ZHex passes valid hex', () {
        final d = _descriptor(const ZString(mapKey: 'hash'), validators: [const ZHex()]);
        expect(FieldValidator.validate(d, 'deadbeef'), isEmpty);
      });

      test('@ZHex fails invalid hex', () {
        final d = _descriptor(const ZString(mapKey: 'hash'), validators: [const ZHex()]);
        expect(FieldValidator.validate(d, 'ghijk'), isNotEmpty);
      });

      test('@ZIpv4 passes valid IPv4', () {
        final d = _descriptor(const ZString(mapKey: 'ip'), validators: [const ZIpv4()]);
        expect(FieldValidator.validate(d, '192.168.1.1'), isEmpty);
      });

      test('@ZIpv4 fails invalid IPv4', () {
        final d = _descriptor(const ZString(mapKey: 'ip'), validators: [const ZIpv4()]);
        expect(FieldValidator.validate(d, '256.1.1.1'), isNotEmpty);
      });

      test('@ZIpv6 passes valid IPv6', () {
        final d = _descriptor(const ZString(mapKey: 'ip'), validators: [const ZIpv6()]);
        expect(FieldValidator.validate(d, '2001:0db8:85a3::8a2e:0370:7334'), isEmpty);
      });

      test('@ZHttpUrl passes http/https URL', () {
        final d = _descriptor(const ZString(mapKey: 'url'), validators: [const ZHttpUrl()]);
        expect(FieldValidator.validate(d, 'https://example.com'), isEmpty);
      });

      test('@ZHttpUrl fails non-http URL', () {
        final d = _descriptor(const ZString(mapKey: 'url'), validators: [const ZHttpUrl()]);
        expect(FieldValidator.validate(d, 'ftp://example.com'), isNotEmpty);
      });

      test('@ZJwt passes valid JWT (3 parts)', () {
        final d = _descriptor(const ZString(mapKey: 'token'), validators: [const ZJwt()]);
        expect(
          FieldValidator.validate(d, 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.x'),
          isEmpty,
        );
      });

      test('@ZJwt fails invalid JWT', () {
        final d = _descriptor(const ZString(mapKey: 'token'), validators: [const ZJwt()]);
        expect(FieldValidator.validate(d, 'only.two'), isNotEmpty);
        expect(FieldValidator.validate(d, 'a.b.'), isNotEmpty);
      });
    });

    group('numeric validators', () {
      test('@Min passes when value >= n', () {
        final d = _descriptor(const ZInt(mapKey: 'age'), validators: [const ZMin(18)]);
        expect(FieldValidator.validate(d, 18), isEmpty);
      });

      test('@Min fails when value < n', () {
        final d = _descriptor(const ZInt(mapKey: 'age'), validators: [const ZMin(18)]);
        expect(FieldValidator.validate(d, 17), isNotEmpty);
      });

      test('@Max passes when value <= n', () {
        final d = _descriptor(const ZInt(mapKey: 'age'), validators: [const ZMax(120)]);
        expect(FieldValidator.validate(d, 100), isEmpty);
      });

      test('@Max fails when value > n', () {
        final d = _descriptor(const ZInt(mapKey: 'age'), validators: [const ZMax(120)]);
        expect(FieldValidator.validate(d, 200), isNotEmpty);
      });

      test('@Positive passes for value > 0', () {
        final d = _descriptor(const ZInt(mapKey: 'qty'), validators: [const ZPositive()]);
        expect(FieldValidator.validate(d, 1), isEmpty);
      });

      test('@Positive fails for zero', () {
        final d = _descriptor(const ZInt(mapKey: 'qty'), validators: [const ZPositive()]);
        expect(FieldValidator.validate(d, 0), isNotEmpty);
      });

      test('@Negative fails for positive', () {
        final d = _descriptor(const ZInt(mapKey: 'temp'), validators: [const ZNegative()]);
        expect(FieldValidator.validate(d, 5), isNotEmpty);
      });

      test('@Negative passes for negative', () {
        final d = _descriptor(const ZInt(mapKey: 'temp'), validators: [const ZNegative()]);
        expect(FieldValidator.validate(d, -3), isEmpty);
      });

      test('@ZInteger passes for int', () {
        final d = _descriptor(const ZNum(mapKey: 'count'), validators: [const ZInteger()]);
        expect(FieldValidator.validate(d, 42), isEmpty);
      });

      test('@ZInteger passes for double with no fractional part', () {
        final d = _descriptor(const ZDouble(mapKey: 'qty'), validators: [const ZInteger()]);
        expect(FieldValidator.validate(d, 10.0), isEmpty);
      });

      test('@ZInteger fails for double with fractional part', () {
        final d = _descriptor(const ZDouble(mapKey: 'price'), validators: [const ZInteger()]);
        expect(FieldValidator.validate(d, 9.99), isNotEmpty);
      });

      test('@ZNonNegative passes for zero', () {
        final d = _descriptor(const ZInt(mapKey: 'qty'), validators: [const ZNonNegative()]);
        expect(FieldValidator.validate(d, 0), isEmpty);
      });

      test('@ZNonNegative passes for positive', () {
        final d = _descriptor(const ZInt(mapKey: 'qty'), validators: [const ZNonNegative()]);
        expect(FieldValidator.validate(d, 1), isEmpty);
      });

      test('@ZNonNegative fails for negative', () {
        final d = _descriptor(const ZInt(mapKey: 'qty'), validators: [const ZNonNegative()]);
        expect(FieldValidator.validate(d, -1), isNotEmpty);
      });

      test('@ZNonPositive passes for zero and negative', () {
        final d = _descriptor(const ZInt(mapKey: 'x'), validators: [const ZNonPositive()]);
        expect(FieldValidator.validate(d, 0), isEmpty);
        expect(FieldValidator.validate(d, -5), isEmpty);
      });

      test('@ZNonPositive fails for positive', () {
        final d = _descriptor(const ZInt(mapKey: 'x'), validators: [const ZNonPositive()]);
        expect(FieldValidator.validate(d, 1), isNotEmpty);
      });

      test('@ZFinite passes for finite numbers', () {
        final d = _descriptor(const ZDouble(mapKey: 'x'), validators: [const ZFinite()]);
        expect(FieldValidator.validate(d, 3.14), isEmpty);
      });

      test('@ZFinite fails for Infinity and NaN', () {
        final d = _descriptor(const ZDouble(mapKey: 'x'), validators: [const ZFinite()]);
        expect(FieldValidator.validate(d, double.infinity), isNotEmpty);
        expect(FieldValidator.validate(d, double.nan), isNotEmpty);
      });

      test('@ZSafeInt passes for safe integer range', () {
        final d = _descriptor(const ZInt(mapKey: 'x'), validators: [const ZSafeInt()]);
        expect(FieldValidator.validate(d, 9007199254740991), isEmpty);
      });

      test('@ZSafeInt fails outside safe range', () {
        final d = _descriptor(const ZInt(mapKey: 'x'), validators: [const ZSafeInt()]);
        expect(FieldValidator.validate(d, 9007199254740992), isNotEmpty);
      });

      test('@ZUppercase passes for uppercase string', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZUppercase()]);
        expect(FieldValidator.validate(d, 'ABC'), isEmpty);
      });

      test('@ZUppercase fails for lowercase', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZUppercase()]);
        expect(FieldValidator.validate(d, 'abc'), isNotEmpty);
      });

      test('@ZLowercase passes for lowercase string', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZLowercase()]);
        expect(FieldValidator.validate(d, 'abc'), isEmpty);
      });

      test('@ZLowercase fails for uppercase', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZLowercase()]);
        expect(FieldValidator.validate(d, 'ABC'), isNotEmpty);
      });

      test('@ZSlug passes valid slug', () {
        final d = _descriptor(const ZString(mapKey: 'slug'), validators: [const ZSlug()]);
        expect(FieldValidator.validate(d, 'my-blog-post'), isEmpty);
      });

      test('@ZSlug fails invalid slug', () {
        final d = _descriptor(const ZString(mapKey: 'slug'), validators: [const ZSlug()]);
        expect(FieldValidator.validate(d, 'Invalid Slug!'), isNotEmpty);
      });

      test('@ZAlphanumeric passes alphanumeric', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZAlphanumeric()]);
        expect(FieldValidator.validate(d, 'abc123'), isEmpty);
      });

      test('@ZAlphanumeric fails with special chars', () {
        final d = _descriptor(const ZString(mapKey: 'code'), validators: [const ZAlphanumeric()]);
        expect(FieldValidator.validate(d, 'abc-123'), isNotEmpty);
      });
    });

    group('error messages', () {
      test('uses custom message from annotation', () {
        final d = _descriptor(
          const ZInt(mapKey: 'age'),
          validators: [const ZMin(18, message: 'Must be adult')],
        );
        final issues = FieldValidator.validate(d, 10);
        expect(issues.first.message, 'Must be adult');
      });

      test('uses default message when none provided', () {
        final d = _descriptor(const ZInt(mapKey: 'age'), validators: [const ZMin(18)]);
        final issues = FieldValidator.validate(d, 10);
        expect(issues.first.message, isNotEmpty);
      });

      test('field name is set on every issue', () {
        final d = _descriptor(const ZString(mapKey: 'name'), validators: [const ZMinLength(10)]);
        final issues = FieldValidator.validate(d, 'Jo');
        expect(issues.first.field, 'name');
      });

      test('ZtoField failMessage used when type check fails', () {
        final d = _descriptor(const ZString(mapKey: 'name', failMessage: 'Nome deve ser texto'));
        final issues = FieldValidator.validate(d, 42);
        expect(issues, hasLength(1));
        expect(issues.first.message, 'Nome deve ser texto');
      });

      test('ZtoField uses default message when failMessage is null', () {
        final d = _descriptor(const ZString(mapKey: 'name'));
        final issues = FieldValidator.validate(d, 42);
        expect(issues, hasLength(1));
        expect(issues.first.message, contains('string'));
      });
    });
  });
}
