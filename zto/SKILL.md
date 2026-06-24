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
part 'create_user_dto.g.dart';        // 1. part for generated file

@ZDto(description: 'Create a user')   // 2. class annotation
class CreateUserDto {
  @ZString() @ZMinLength(2) final String name;
  @ZString() @ZEmail() final String email;
  @ZInt() @ZMin(18) final int age;
  @ZString() final String? phone;     // optional via `?`

  const CreateUserDto({required this.name, required this.email, required this.age, this.phone});

  factory CreateUserDto.fromMap(Map<String, dynamic> map) => CreateUserDto(  // 3. your factory
        name: map['name'] as String, email: map['email'] as String,
        age: map['age'] as int, phone: map['phone'] as String?);
}
```

Then `dart run build_runner build --delete-conflicting-outputs`.

## Class annotation

`@ZDto`, `@ZEntity`, `@ZModel` are **semantically identical** (same generated schema) —
pick by intent: `@ZDto` = transport/API contracts, `@ZEntity` = domain entities,
`@ZModel` = persistable aggregates. Params: `description` (**required**), `parseType`
(default `ParseType.camelCase`), `deprecated`.

## Field types

One per field. Common params: `mapKey`, `description`, `example`, `failMessage`, `deprecated`.

`@ZString` `@ZInt` `@ZDouble` `@ZNum` `@ZBool` `@ZDate` `@ZFile` · `@ZEnum()` (values
inferred from the enum, or `values: [...]`) · `@ZList(itemType: X)` for `List<primitive>` ·
`@ZListOf(...)` for `List<NestedDto>` · `@ZObj()`/`@ZObject()` for a nested DTO (auto-detected
when the field type is itself `@ZDto`/`@ZEntity`/`@ZModel`).

## Validators

Stack below the type annotation; they run at parse time and collect all failures. The build
fails with a clear error if a validator is incompatible with the field type.

- **String:** `@ZMinLength` `@ZMaxLength` `@ZLength` `@ZEmail` `@ZUrl` `@ZHttpUrl`
  `@ZRegex`/`@ZPattern` `@ZUuid` `@ZJwt` `@ZBase64` `@ZHex` `@ZIpv4` `@ZIpv6` `@ZStartsWith`
  `@ZEndsWith` `@ZIncludes` `@ZIsoDate` `@ZIsoDateTime` `@ZUppercase` `@ZLowercase` `@ZSlug`
  `@ZAlphanumeric`
- **Numeric:** `@ZMin` `@ZMax` `@ZPositive` `@ZNegative` `@ZNonNegative` `@ZNonPositive`
  `@ZMultipleOf` `@ZInteger` `@ZFinite` `@ZSafeInt`

## ParseType & mapKey

`parseType` on the class maps field names → JSON keys when no `mapKey` is set; an explicit
`mapKey` always wins. `firstName` → `firstName` (`camelCase`, default) / `first_name`
(`snakeCase`) / `FirstName` (`pascalCase`) / `first-name` (`kebabCase`).

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
- Wrong JSON key → check `parseType` or set an explicit `mapKey`.
