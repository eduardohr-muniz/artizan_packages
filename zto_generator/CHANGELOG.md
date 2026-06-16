# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0]

### Added

- Initial release
- `build_runner` builder (`ztoBuilder`) that generates `*.g.dart` from
  `@ZDto`-annotated classes
- Generates `$<Dto>Schema` constants consumed by `zto` for validation
- Build-time validation: incompatible validators (e.g. `@ZEmail` on a numeric
  field) fail the build with a clear error message
