---
name: zto
description: Annotation-based DTO/Model/Entity validation for Dart with the `zto` package — defining @ZDto/@ZEntity/@ZModel classes, field validators, ParseType/mapKey, and parsing or validating payloads.
---

# zto — Annotation-based DTO validation

You annotate a class; `zto_generator` (via `build_runner`) emits `$NameSchema`; at runtime
`$NameSchema.parse(map, Name.fromMap)` returns a validated `T` or throws `ZtoException`.

Nullability comes from Dart's `?` suffix — there is **no `@ZNullable`**. `String? x` is
optional; `String x` is required.

## The 3 ingredients

A class is only validatable with all three — miss one and `$NameSchema` isn't generated.

```dart
import 'package:zto/zto.dart';
part 'create_user_dto.g.dart';                                       // 1. part for generated file

@ZDto(description: 'Create a user', parseType: ParseType.snakeCase)  // 2. class annotation
class CreateUserDto {
  @ZString(description: 'Full name', example: 'Alice')
  @ZMinLength(2)
  final String name;

  @ZString(description: 'Email address', example: 'alice@example.com')
  @ZEmail()
  final String email;

  @ZInt(description: 'Age in years', example: 25)
  @ZMin(18)
  final int age;

  @ZString(description: 'Phone number', example: '+55 11 90000-0000')
  final String? phone;                                               // optional via `?`

  const CreateUserDto({required this.name, required this.email, required this.age, this.phone});

  factory CreateUserDto.fromMap(Map<String, dynamic> map) => CreateUserDto(  // 3. your factory
        name: map['name'] as String, email: map['email'] as String,
        age: map['age'] as int, phone: map['phone'] as String?);
}
```

Then `dart run build_runner build --delete-conflicting-outputs`.

## Class annotation: `@ZDto` / `@ZEntity` / `@ZModel`

The three are **semantically identical** (same generated schema) — pick by intent:
`@ZDto` = transport/API contracts, `@ZEntity` = domain entities, `@ZModel` = persistable
aggregates.

| Param | Type | Default | Purpose |
|---|---|---|---|
| `description` | `String` | **required** | Shown in OpenAPI / Swagger UI |
| `parseType` | `ParseType` | `ParseType.camelCase` | How field names map to JSON keys (see below) |
| `deprecated` | `bool` | `false` | Marks the schema deprecated in OpenAPI |

```dart
@ZDto(
  description: 'Create user request',
  parseType: ParseType.snakeCase,
  deprecated: false,
)
class CreateUserDto { ... }
```

## Field types

Annotate **one** type per field. Every type annotation shares these params: `mapKey`
(explicit JSON key), `description` and `example` (for OpenAPI docs), `failMessage` (custom
type-mismatch message), `deprecated`.

| Annotation | Dart type | Example (with description/example + type-specific params) |
|---|---|---|
| `@ZString` | `String` | `@ZString(description: 'Full name', example: 'Alice')` |
| `@ZInt` | `int` | `@ZInt(description: 'Age in years', example: 25)` |
| `@ZDouble` | `double` | `@ZDouble(description: 'Unit price', example: 9.99)` |
| `@ZNum` | `num` | `@ZNum(description: 'Score', example: 87.5)` |
| `@ZBool` | `bool` | `@ZBool(description: 'Whether active', example: true)` |
| `@ZDate` | `DateTime` | `@ZDate(description: 'Created at', example: '2024-03-15T10:00:00Z')` |
| `@ZFile` | upload | `@ZFile(description: 'Profile image')` |
| `@ZEnum` | enum / `String` | `@ZEnum(values: ['admin', 'editor', 'viewer'], description: 'Role')` |
| `@ZMap` | `Map<String, dynamic>` | `@ZMap(description: 'Raw metadata')` |
| `@ZMetaData` | `Map<String, dynamic>` | `@ZMetaData(description: 'User metadata', example: {'plan': 'pro'})` |
| `@ZList` | `List<primitive>` | `@ZList(itemType: ZString, description: 'List of tags')` |
| `@ZListOf` | `List<NestedDto>` | `@ZListOf(dtoType: AddressDto, description: 'Addresses')` |
| `@ZObj` | nested DTO (explicit) | `@ZObj(dtoType: AddressDto, description: 'Billing address')` |
| `@ZObject` | nested DTO (inferred) | `@ZObject(description: 'Address')` — type read from the field |

Notes:
- `@ZEnum`: on an enum-typed field the generator infers `values` from the enum; pass
  `values: [...]` explicitly for a plain `String` field.
- `@ZList` takes a **`ZtoField` type** in `itemType` (e.g. `ZString`, `ZInt`).
- `@ZListOf` / `@ZObj` take either `dtoSchema:` (the generated `$Schema`) or `dtoType:` (the
  DTO class, looked up from the registry). Prefer `@ZObject` for a single nested field — it
  infers the type from the declaration, so no `dtoType`/`dtoSchema` needed.

## Validators

Stack validators **below** the type annotation. They run at parse time and collect **all**
failures (they don't stop at the first). Every validator accepts an optional `message:` to
override the default error. The build fails with a clear error if a validator is
incompatible with the field type (e.g. `@ZEmail` on a `@ZDouble`).

**String** (under `@ZString`):

| Validator | Passes ✓ / Fails ✗ |
|---|---|
| `@ZMinLength(2)` | `'abc'` ✓ / `'a'` ✗ |
| `@ZMaxLength(10)` | `'hello'` ✓ / `'hello world!'` ✗ |
| `@ZLength(5)` | `'12345'` ✓ / `'1234'` ✗ |
| `@ZEmail()` | `'a@b.com'` ✓ / `'invalid'` ✗ |
| `@ZUuid()` | `'550e8400-e29b-41d4-a716-446655440000'` ✓ / `'x'` ✗ |
| `@ZUrl()` | `'https://example.com'` ✓ / `'not-a-url'` ✗ |
| `@ZHttpUrl()` | `'https://x.com'` ✓ / `'ftp://x.com'` ✗ |
| `@ZPattern(r'^[a-z]+$')` | `'abc'` ✓ / `'Abc'` ✗ |
| `@ZStartsWith('https://')` | `'https://x.com'` ✓ / `'http://x.com'` ✗ |
| `@ZEndsWith('.com')` | `'site.com'` ✓ / `'site.org'` ✗ |
| `@ZIncludes('foo')` | `'hello foo'` ✓ / `'hello bar'` ✗ |
| `@ZBase64()` | `'SGVsbG8='` ✓ / `'!!!'` ✗ |
| `@ZHex()` | `'deadbeef'` ✓ / `'ghijk'` ✗ |
| `@ZIpv4()` | `'192.168.1.1'` ✓ / `'256.1.1.1'` ✗ |
| `@ZIpv6()` | `'2001:0db8::1'` ✓ / `'invalid'` ✗ |
| `@ZJwt()` | `'a.b.c'` ✓ / `'a.b'` ✗ |
| `@ZIsoDate()` | `'2024-03-15'` ✓ / `'2024-13-01'` ✗ |
| `@ZIsoDateTime()` | `'2024-03-15T10:00:00Z'` ✓ / `'2024-03-15'` ✗ |
| `@ZUppercase()` | `'ABC'` ✓ / `'Abc'` ✗ |
| `@ZLowercase()` | `'abc'` ✓ / `'Abc'` ✗ |
| `@ZSlug()` | `'my-blog-post'` ✓ / `'Invalid Slug!'` ✗ |
| `@ZAlphanumeric()` | `'abc123'` ✓ / `'abc-123'` ✗ |

**Numeric** (under `@ZInt` / `@ZDouble` / `@ZNum`; `@ZMin`/`@ZMax` also work on `@ZDate`):

| Validator | Passes ✓ / Fails ✗ |
|---|---|
| `@ZMin(18)` | `18`, `25` ✓ / `17` ✗ |
| `@ZMax(120)` | `100`, `120` ✓ / `121` ✗ |
| `@ZPositive()` | `1` ✓ / `0`, `-1` ✗ |
| `@ZNegative()` | `-5` ✓ / `5` ✗ |
| `@ZNonNegative()` | `0`, `1` ✓ / `-1` ✗ |
| `@ZNonPositive()` | `0`, `-5` ✓ / `1` ✗ |
| `@ZMultipleOf(5)` | `10`, `15` ✓ / `12` ✗ |
| `@ZInteger()` | `10` ✓ / `9.99` ✗ |
| `@ZFinite()` | `42` ✓ / `infinity`, `nan` ✗ |
| `@ZSafeInt()` | `9007199254740991` ✓ / `9007199254740992` ✗ |

## ParseType & mapKey

`parseType` (on the class) maps field names → JSON keys when no `mapKey` is set; an explicit
`mapKey` always wins.

| `ParseType` | `firstName` becomes |
|---|---|
| `camelCase` *(default)* | `firstName` |
| `snakeCase` | `first_name` |
| `pascalCase` | `FirstName` |
| `kebabCase` | `first-name` |

```dart
@ZDto(description: 'User', parseType: ParseType.snakeCase)
class UserDto {
  @ZString()                         // key: first_name
  final String firstName;

  @ZString(mapKey: 'email_address')  // explicit mapKey overrides snake_case
  final String email;                // key: email_address
}
```

## Validating

```dart
// parse → validated dto, with an optional cross-field rule chained on:
final dto = $CreateUserDtoSchema.parse(body, CreateUserDto.fromMap)
    .refine((d) => d.age >= 18, field: 'age', message: 'Must be an adult');

final list = $CreateUserDtoSchema.parseList(jsonArray, CreateUserDto.fromMap);
// registry form (schema auto-registered by the generator): Zto.parse(body, CreateUserDto.fromMap)
```

`.refine()` for cross-field/business rules is available on **any** parsed value (via the
`ZtoRefineExtension` — no mixin needed). Any factory works (`fromMap`/`fromJson`/…). Failure
throws `ZtoException` with `message`, `issues` (`List<ZtoIssue>` of `field` + `message`), and
`toMap()`.

## Production error handling

Never let validation detail reach the client — `issues` expose internal field names and
rules (information disclosure). Send the `ZtoException` only to logs/analytics; return a
fixed generic message.

```dart
try {
  final dto = $CreateUserDtoSchema.parse(body, CreateUserDto.fromMap);
} on ZtoException catch (e, s) {
  log('Validation failed', error: e, stackTrace: s);        // detail → logs/analytics only
  return Response.json(statusCode: 422, body: {'message': 'Invalid request.'}); // generic
}
```

Don't serialize `e.issues`/`e.toMap()` into the client response; centralize handling in one
middleware. (`Zto.errorFormatter` is for internal logging only, not client payloads.)

## Common mistakes

- `$...Schema` missing → no `part 'x.g.dart';`, no class annotation, or didn't run `build_runner`.
- Field validates as required → use the `?` suffix (no `@ZNullable`).
- Wrong JSON key → check the class `parseType` or set an explicit `mapKey`.
- Validator rejected at build time → it's incompatible with the field type (e.g. `@ZEmail`
  on a number); use a compatible one.
