import 'package:test/test.dart';
import 'package:zto/zto.dart';

void main() {
  group('Validator annotations', () {
    group('String validators', () {
      test('@ZMinLength is const and holds n', () {
        const a = ZMinLength(3);
        expect(a.n, 3);
      });

      test('@ZMaxLength is const and holds n', () {
        const a = ZMaxLength(100);
        expect(a.n, 100);
      });

      test('@ZLength is const and holds n', () {
        const a = ZLength(5);
        expect(a.n, 5);
      });

      test('@Email is const', () {
        const a = ZEmail();
        expect(a, isA<ZEmail>());
      });

      test('@Email holds custom message', () {
        const a = ZEmail(message: 'Bad email');
        expect(a.message, 'Bad email');
      });

      test('@Uuid is const', () {
        const a = ZUuid();
        expect(a, isA<ZUuid>());
      });

      test('@Url is const', () {
        const a = ZUrl();
        expect(a, isA<ZUrl>());
      });

      test('@Pattern is const and holds regex string', () {
        const a = ZPattern(r'^[a-z]+$');
        expect(a.regex, r'^[a-z]+$');
      });

      test('@Pattern holds custom message', () {
        const a = ZPattern(r'^[a-z]+$', message: 'Lowercase only');
        expect(a.message, 'Lowercase only');
      });

      test('@ZIsoDate is const', () {
        const a = ZIsoDate();
        expect(a, isA<ZIsoDate>());
      });

      test('@ZIsoDateTime is const', () {
        const a = ZIsoDateTime();
        expect(a, isA<ZIsoDateTime>());
      });

      test('@ZStartsWith is const and holds prefix', () {
        const a = ZStartsWith('https://');
        expect(a.prefix, 'https://');
      });

      test('@ZEndsWith is const and holds suffix', () {
        const a = ZEndsWith('.com');
        expect(a.suffix, '.com');
      });

      test('@ZIncludes is const and holds substring', () {
        const a = ZIncludes('foo');
        expect(a.substring, 'foo');
      });

      test('@ZBase64 is const', () {
        const a = ZBase64();
        expect(a, isA<ZBase64>());
      });

      test('@ZHex is const', () {
        const a = ZHex();
        expect(a, isA<ZHex>());
      });

      test('@ZIpv4 is const', () {
        const a = ZIpv4();
        expect(a, isA<ZIpv4>());
      });

      test('@ZIpv6 is const', () {
        const a = ZIpv6();
        expect(a, isA<ZIpv6>());
      });

      test('@ZHttpUrl is const', () {
        const a = ZHttpUrl();
        expect(a, isA<ZHttpUrl>());
      });

      test('@ZJwt is const', () {
        const a = ZJwt();
        expect(a, isA<ZJwt>());
      });

      test('@ZUppercase is const', () {
        const a = ZUppercase();
        expect(a, isA<ZUppercase>());
      });

      test('@ZLowercase is const', () {
        const a = ZLowercase();
        expect(a, isA<ZLowercase>());
      });

      test('@ZSlug is const', () {
        const a = ZSlug();
        expect(a, isA<ZSlug>());
      });

      test('@ZAlphanumeric is const', () {
        const a = ZAlphanumeric();
        expect(a, isA<ZAlphanumeric>());
      });
    });

    group('Numeric validators', () {
      test('@ZInteger is const', () {
        const a = ZInteger();
        expect(a, isA<ZInteger>());
      });

      test('@ZNonNegative is const', () {
        const a = ZNonNegative();
        expect(a, isA<ZNonNegative>());
      });

      test('@Min is const and holds n', () {
        const a = ZMin(18);
        expect(a.n, 18);
      });

      test('@Max is const and holds n', () {
        const a = ZMax(120);
        expect(a.n, 120);
      });

      test('@Positive is const', () {
        const a = ZPositive();
        expect(a, isA<ZPositive>());
      });

      test('@Negative is const', () {
        const a = ZNegative();
        expect(a, isA<ZNegative>());
      });

      test('@MultipleOf is const and holds n', () {
        const a = ZMultipleOf(5);
        expect(a.n, 5);
      });

      test('@ZNonPositive is const', () {
        const a = ZNonPositive();
        expect(a, isA<ZNonPositive>());
      });

      test('@ZFinite is const', () {
        const a = ZFinite();
        expect(a, isA<ZFinite>());
      });

      test('@ZSafeInt is const', () {
        const a = ZSafeInt();
        expect(a, isA<ZSafeInt>());
      });
    });

    group('Custom messages', () {
      test('@Min holds optional message', () {
        const a = ZMin(18, message: 'Must be adult');
        expect(a.message, 'Must be adult');
        expect(a.n, 18);
      });

      test('@Max holds optional message', () {
        const a = ZMax(120, message: 'Too old');
        expect(a.message, 'Too old');
      });

      test('@ZMinLength holds optional message', () {
        const a = ZMinLength(2, message: 'Too short');
        expect(a.message, 'Too short');
      });
    });
  });
}
