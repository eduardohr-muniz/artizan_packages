# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-03-14

### Added

- Initial release
- `@Dto` class annotation for DTOs
- Field type annotations: `@ZString`, `@ZInt`, `@ZDouble`, `@ZNum`, `@ZBool`, `@ZDate`, `@ZFile`, `@ZEnum`, `@ZList`, `@ZListOf`, `@ZObj`
- String validators: `@ZMinLength`, `@ZMaxLength`, `@ZLength`, `@ZEmail`, `@ZUuid`, `@ZUrl`, `@ZPattern`, `@ZStartsWith`, `@ZEndsWith`, `@ZIncludes`, `@ZBase64`, `@ZHex`, `@ZIpv4`, `@ZIpv6`, `@ZHttpUrl`, `@ZJwt`, `@ZIsoDate`, `@ZIsoDateTime`, `@ZUppercase`, `@ZLowercase`, `@ZSlug`, `@ZAlphanumeric`
- Numeric validators: `@ZMin`, `@ZMax`, `@ZPositive`, `@ZNegative`, `@ZNonNegative`, `@ZNonPositive`, `@ZMultipleOf`, `@ZInteger`, `@ZFinite`, `@ZSafeInt`
- `@Nullable()` modifier for optional fields
- `Zto.parse()` and `Zto.parseList()` for parsing maps
- `ZtoDto.refine()` for cross-field validation
- `ZtoException` with `toMap()`, `format()`, and configurable `Zto.errorFormatter`
- `DtoToOpenApi.convert()` for OpenAPI 3.0 JSON Schema generation
- Integration with `zto_generator` for code generation
- Build-time validation: incompatible validators (e.g. `@ZEmail` on `@ZDouble`) fail the build with a clear error message
