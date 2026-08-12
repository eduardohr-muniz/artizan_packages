# dart_frog_open_api

OpenAPI/Swagger spec generator for [Dart Frog](https://dartfrog.vgv.dev). Document your
routes with a fluent API, get an OpenAPI 3.0 spec, **Swagger UI** and **Scalar UI**, plus
**Postman** and **Bruno** collection exports — with request/response schemas
**auto-generated** from your [`zto`](https://pub.dev/packages/zto) DTOs (no hand-written
JSON Schema).

| Scalar UI | Swagger UI |
|---|---|
| ![Scalar UI](https://raw.githubusercontent.com/eduardohr-muniz/artizan_packages/main/dart_frog_open_api/assets/scalar.jpg) | ![Swagger UI](https://raw.githubusercontent.com/eduardohr-muniz/artizan_packages/main/dart_frog_open_api/assets/swagger.jpg) |

## Features

- **Fluent route docs** — describe each endpoint with `Api.path()...build()`.
- **Auto-generated DTO schemas** — `.body($Schema)` / `.response(200, ztoSchema: $Schema)`
  reuse the schemas [`zto`](https://pub.dev/packages/zto) generates from your annotated DTOs
  (via `build_runner`), with recursive `$ref` resolution for nested DTOs — you never write
  JSON Schema by hand.
- **OpenAPI 3.0 JSON** served by a Dart Frog handler.
- **Swagger UI + Scalar UI** out of the box, including a Scalar environment switcher.
- **Postman v2.1 & Bruno** collection export (with pre-request / test scripts).
- **Security gating** — docs endpoints are closed by default (404), opt-in per environment,
  with optional guard, CORS, security headers, and access logging.

## How it works

Documenting an endpoint has four pieces, always in this dependency order:

```
DTO (@ZDto + build_runner → $NameSchema)     →  body/response schema
        ↓
ApiDoc on the route (Api.path() … .build())  →  describes the path's operations
        ↓
register it in a paths map (apiPathSchemas)  →  maps "path string" → ApiDoc
        ↓
OpenApiConfig + DartFrogOpenApi (main.dart)  →  builds the spec, serves the UIs
```

The ApiDoc is **documentation only** — it doesn't affect runtime. What validates a request
is `$NameSchema.parse()` inside your route handler (see [`zto`](https://pub.dev/packages/zto)).

## Installation

```yaml
dependencies:
  dart_frog_open_api: ^0.1.0
  zto: ^0.1.0   # for request/response DTO schemas
```

## Quick start

### 1. Document a route

Declare an `ApiDoc` next to your route handler. `.body()` and `.response(..., ztoSchema:)`
take generated `zto` schemas:

```dart
// routes/users/index.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

/// OpenAPI: `POST /users`
final usersApiDoc = Api.path()
    .post(
      (op) => op
          .summary('Create a user')
          .tag('Users')
          .body($CreateUserDtoSchema)
          .response(201, ztoSchema: $UserDtoSchema, description: 'Created')
          .response(422, description: 'Validation failed'),
    )
    .build();

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _createUser(context), // validates with $CreateUserDtoSchema.parse(...)
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}
```

### 2. Register the path

Map each OpenAPI path string to its `ApiDoc`. Use `{param}` for path params:

```dart
// open_api/paths.dart
final apiPathSchemas = <String, PathSchema>{
  '/users': usersApiDoc,
  '/users/{id}': userByIdApiDoc,
  // ...
};
```

### 3. Build the config

```dart
// open_api/config.dart
final openApiConfig = OpenApiConfig(
  baseUrl: 'http://localhost:8080',
  info: const OpenApiInfo(
    title: 'My API',
    description: 'Example API.',
    servers: ['http://localhost:8080'],
  ),
  pathSchemas: apiPathSchemas,
  specUrl: '/swagger/json',
  declaredSecuritySchemes: [OpenApiSecurity.bearer()],
  globalSecurity: [OpenApiSecurity.bearer().componentKey],
  // Docs are closed (404) by default — enable per environment:
  security: const SecurityConfig(enabled: true),
);
```

### 4. Initialize in `main.dart`

```dart
// main.dart
late final DartFrogOpenApi openApi;

Future<void> init(InternetAddress ip, int port) async {
  openApi = DartFrogOpenApi(config: openApiConfig);
}
```

### 5. Expose the UI + spec

```dart
// routes/swagger/index.dart      → Swagger UI page
FutureOr<Response> onRequest(RequestContext context) =>
    openApi.swaggerUiHandler()(context);

// routes/swagger/json.dart       → OpenAPI 3.0 JSON spec
FutureOr<Response> onRequest(RequestContext context) =>
    openApi.openApiJsonHandler()(context);
```

Open `/swagger` for the UI; the spec is served at `specUrl` (`/swagger/json` above).

## Fluent API reference

Start with `Api.path()`, add a path-level param if needed, then one block per HTTP method,
and finish with `.build()`.

```dart
final apiDoc = Api.path()
    .param('id', ParamType.string, description: 'Resource id')   // path param shared by all methods
    .get((op) => op.summary('Get one').tag('Items').ok(ztoSchema: $ItemDtoSchema))
    .post((op) => op
        .summary('Create')
        .tag('Items')
        .body($CreateItemDtoSchema)
        .created(ztoSchema: $ItemDtoSchema))
    .delete((op) => op.summary('Delete').tag('Items').noContent())
    .build();
```

**Operation builder (`op`):**

| Method | Purpose |
|---|---|
| `.summary(s)` · `.description(s)` | human-readable docs |
| `.tag(s)` · `.tags([...])` | group operations in the UI |
| `.body($Schema, {required, contentType})` | JSON request body from a `zto` schema |
| `.bytesBody()` · `.streamBody(...)` | binary / streamed request body |
| `.query(name, ParamType, {...})` · `.queryParam(name, {required})` | query params |
| `.header(name, ParamType, {...})` | request header |
| `.response(status, {ztoSchema, listOfZtoSchema, json, listOfJson, description, headers})` | document a response |
| `.security([...])` · `.public()` | per-operation auth (override global) |
| `.deprecated()` | mark the operation deprecated |
| `.postman(s)` / `.postmanPre(s)` · `.bruno(s)` / `.brunoPre(s)` | attach test / pre-request scripts |

**Response shortcuts** (each takes the same named args as `.response`): `.ok()` `.created()`
`.accepted()` `.noContent()` `.badRequest()` `.unauthorized()` `.forbidden()` `.notFound()`
`.conflict()` `.unprocessable()` `.tooManyRequests()` `.serverError()` `.serviceUnavailable()`.

```dart
op.ok(ztoSchema: $UserDtoSchema)               // 200 with a single object
  .response(200, listOfZtoSchema: $UserDtoSchema) // 200 with an array
  .notFound(description: 'User not found');
```

## Security

Documentation endpoints are **closed by default** — every handler returns `404` until you
set `SecurityConfig(enabled: true)`. When the guard denies a request it returns `403`.

```dart
security: SecurityConfig(
  enabled: true,
  guard: (req) => req.headers['x-docs-key'] == myDocsKey, // optional allow/deny
  corsOrigins: ['https://docs.example.com'],              // optional CORS allowlist
  securityHeaders: true,                                  // nosniff, etc. (default true)
  logAccess: true,                                        // log each docs hit
  cacheTtl: Duration(minutes: 5),                         // spec cache TTL
),
```

Declare the schemes shown in the UI's "Authorize" panel and apply one globally:

```dart
final bearer = OpenApiSecurity.bearer();

OpenApiConfig(
  declaredSecuritySchemes: [bearer],
  globalSecurity: [bearer.componentKey],   // applied to every operation
  // ...
);
```

Other schemes: `SecurityScheme.bearer`, `SecurityScheme.basic`,
`SecurityScheme.apiKeyHeader('X-API-Key')`, `apiKeyQuery`, `apiKeyCookie`, and the OAuth2
factories. Use `.public()` on an operation to opt it out of `globalSecurity`.

> ⚠️ The constructor warns on stderr for any `servers` entry using plain HTTP on a
> non-localhost host — prefer HTTPS outside local dev.

## UIs

- **Swagger UI** — `openApi.swaggerUiHandler()`
- **Scalar UI** — `openApi.scalarUiHandler()` (optionally `scalarUiHandler(options: ScalarOptions(...))`)

Both UIs sort tag groups alphabetically by default, so the sidebar order stays stable
regardless of route-scan order. (Scalar does not honour the top-level `tags` ordering on
its own — the sorting is applied via its configuration.)

### Expand / collapse sections (Swagger UI)

Control how much of the document Swagger UI expands on first load with the
`SwaggerDocExpansion` enum:

```dart
// Everything collapsed (fully minimized)
openApi.swaggerUiHandler(docExpansion: SwaggerDocExpansion.none);

// Tag groups open, operations collapsed (default)
openApi.swaggerUiHandler(docExpansion: SwaggerDocExpansion.list);

// Tag groups and operations expanded
openApi.swaggerUiHandler(docExpansion: SwaggerDocExpansion.full);
```

### Sidebar ordering (Scalar UI)

`ScalarOptions` exposes the sort order via enums (default: alphabetical). Pass `null` to
preserve the order tags/operations appear in the spec:

```dart
openApi.scalarUiHandler(
  options: const ScalarOptions(
    tagsSorter: ScalarTagsSorter.alpha,            // or null to keep spec order
    operationsSorter: ScalarOperationsSorter.alpha, // or .method / null
    defaultOpenAllTags: true,                       // start with all groups expanded
  ),
);
```

Scalar supports named environments with `{{variable}}` substitution in the "Try it" panel:

```dart
OpenApiConfig(
  scalarEnvironments: const [
    ScalarEnvironment(
      name: 'local',
      description: 'Dev',
      color: '#6366f1',
      variables: {'token': ScalarEnvironmentVariable(defaultValue: '', description: 'Bearer JWT')},
    ),
  ],
  scalarActiveEnvironment: 'local',
);
```

## Postman & Bruno export

Attach scripts per operation with `.postman()/.postmanPre()` and `.bruno()/.brunoPre()`.

- **Postman**: serve a v2.1 collection with `postmanCollectionHandler(...)` (mount it on a route).
- **Bruno**: set `OpenApiConfig(brunoOutputDir: Directory(...))` to enable the Bruno download
  and write the collection to disk.

## zto integration

Request/response schemas come from [`zto`](https://pub.dev/packages/zto). Define an annotated
DTO, run `dart run build_runner build`, and pass the generated `$NameSchema` to `.body()` /
`.response(ztoSchema:)`. Nested DTOs are resolved recursively into `components.schemas` with
`$ref`. Because the docs reuse the very schemas you validate with, they never drift from your
validation rules.

## License

MIT
