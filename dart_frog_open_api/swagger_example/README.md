# swagger_example

Example Dart Frog service showing how to use `dart_frog_open_api` to generate live OpenAPI docs from your routes — no annotations, no manual spec files.

Run it and open `http://localhost:8080/swagger`.

---

## Project structure

```
lib/
  open_api_config.dart   ← all OpenAPI config in one place
  dtos/                  ← Zto DTO classes (@ZDto, @ZString, etc.)
  api_docs/              ← long descriptions & Postman/Bruno scripts
routes/
  v1/
    users/
      index.dart         → GET /v1/users, POST /v1/users
      [id].dart          → GET/PUT/PATCH/DELETE /v1/users/{id}
    products/…
    uploads/…
  swagger/               ← Swagger UI + JSON spec handlers
main.dart
```

---

## 1. Initialize in `main.dart`

```dart
Future<void> init(InternetAddress ip, int port) async {
  await DartFrogOpenApi.initialize(openApiConfig);
}
```

---

## 2. Configure in `lib/open_api_config.dart`

```dart
final openApiConfig = OpenApiConfig(
  info: const OpenApiInfo(
    title: 'Swagger Example API',
    description: 'Dart Frog + Zto DTO annotations demo.',
    servers: ['http://localhost:8080'],
  ),
  routesDir: RoutesDirResolver.fromCwd(),
  securitySchemes: const {
    'BearerAuth': SecurityScheme.bearer,
    'ApiKey': ApiKeyScheme(name: 'X-API-Key', location: 'header'),
  },
  globalSecurity: const ['BearerAuth'],
  pathSchemas: apiPathSchemas,   // defined below
  specUrl: '/swagger/json',
  brunoOutputDir: Directory('bruno_collection'),
);
```

### Documenting a path

```dart
'/v1/users': PathSchema(
  get: OperationSchema(
    summary: 'List all users',
    tags: ['Users'],
    security: [],                          // public — overrides globalSecurity
    queryParameters: [
      const ParameterSchema(name: 'search', type: 'string'),
      const ParameterSchema(name: 'page',   type: 'integer', example: 1),
      const ParameterSchema(name: 'limit',  type: 'integer', example: 20),
    ],
    responseSchemas: {200: OpenApiSchema.fromZto($UserListResponseDtoSchema)},
    responseHeaders: {
      200: [const ResponseHeaderSchema(name: 'X-Total-Count', type: 'integer')],
    },
  ),
  post: OperationSchema(
    summary: 'Create a user',
    tags: ['Users'],
    headerParameters: [
      const ParameterSchema(name: 'X-Request-Id', type: 'string', format: 'uuid'),
    ],
    requestBodySchema: OpenApiSchema.fromZto($CreateUserDtoSchema),
    responseSchemas: {201: OpenApiSchema.fromZto($UserResponseDtoSchema)},
    responseHeaders: {
      201: [const ResponseHeaderSchema(name: 'Location', example: '/v1/users/u001')],
    },
    postmanTestScript: createUserPostmanScript,
    brunoTestScript: createUserBrunoScript,
  ),
),

'/v1/users/{id}': PathSchema(
  pathParameters: {
    'id': const ParameterSchema(type: 'string', description: 'User ID', example: 'u001'),
  },
  get:    OperationSchema(summary: 'Get user by ID', tags: ['Users'], …),
  put:    OperationSchema(summary: 'Replace user',   tags: ['Users'], …),
  patch:  OperationSchema(summary: 'Partial update', tags: ['Users'], requestBodyRequired: false, …),
  delete: const OperationSchema(summary: 'Delete user', tags: ['Users'], responseSchemas: {204: null}),
),
```

---

## 3. Define DTOs with Zto

```dart
@ZDto(description: 'Create a new user', parseType: ParseType.snakeCase)
class CreateUserDto with ZtoDto<CreateUserDto> {
  @ZString(description: 'Full name', example: 'Alice Silva')
  @ZMinLength(2)
  @ZNullable()
  final String? name;

  @ZString(description: 'E-mail address', example: 'alice@example.com')
  @ZEmail()
  final String email;

  @ZEnum(values: ['admin', 'editor', 'viewer'])
  final String role;
  …
}
```

Run `dart run build_runner build` to generate the `$CreateUserDtoSchema` used in `OpenApiSchema.fromZto(…)`.

---

## 4. Mount the handlers

Os handlers são rotas Dart Frog normais — você cria os arquivos onde quiser dentro de `routes/`. Cada arquivo expõe um endpoint diferente do pacote.

Crie os três arquivos abaixo (ou só os que precisar):

**`routes/swagger/index.dart`** → `GET /swagger` — Swagger UI interativa
```dart
import 'dart:async';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';

FutureOr<Response> onRequest(RequestContext context) =>
    DartFrogOpenApi.swaggerUiHandler()(context);
```

**`routes/swagger/json.dart`** → `GET /swagger/json` — spec OpenAPI 3.0 em JSON puro
```dart
import 'dart:async';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';

FutureOr<Response> onRequest(RequestContext context) =>
    DartFrogOpenApi.openApiJsonHandler()(context);
```

**`routes/swagger/postman.dart`** → `GET /swagger/postman` — Postman Collection v2.1
```dart
import 'dart:async';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';

FutureOr<Response> onRequest(RequestContext context) =>
    DartFrogOpenApi.postmanCollectionHandler()(context);
```

> O caminho das rotas é livre — se preferir `/api-docs` em vez de `/swagger`, basta criar a pasta `routes/api-docs/` com os mesmos arquivos. Só lembre de atualizar `specUrl` no `OpenApiConfig` para apontar para o JSON correto.

A Swagger UI já inclui botões de download para o JSON e o Postman Collection.

---

## Running

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart_frog dev
```

Open `http://localhost:8080/swagger`.
