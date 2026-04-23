library;

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart' hide HttpMethod;
import 'package:swagger_example/dtos/user_dto.dart';
import '../../../open_api/security_refs.dart';
import 'package:swagger_example/response.dart';
import 'package:swagger_example/store.dart';

// ── Documentation ────────────────────────────────────────────────────────────

const _listUsersDoc = '''
## List Users

Returns the **full list** of registered users in the system.

### Behavior
- Results are returned in **insertion order** (newest last).
- This endpoint is **public** — no authentication required.
- An empty array `[]` is returned when no users exist yet.

### Response fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Unique identifier (UUID v4) |
| `name` | `string` | Full display name |
| `email` | `string` | Validated e-mail address |
| `createdAt` | `string` | ISO 8601 creation timestamp |

### Example response

```json
{
  "data": [{ "id": "a1b2c3d4-...", "name": "Ada Lovelace", "email": "ada@example.com" }],
  "total": 1
}
```

> **Note:** This endpoint returns **in-memory data** and resets on every server restart.
''';

const _createUserDoc = '''
## Create User

Creates a new user account and returns the persisted resource.

### Validation rules
- `name` — required, minimum **2 characters**.
- `email` — required, must be a **valid e-mail address**.
- `age` — optional, must be **≥ 18** when provided.

### Error handling
On invalid input the server responds with **422 Unprocessable Content**
and a structured error body listing every field that failed validation.

```json
{ "issues": [{ "field": "email", "message": "Invalid email address" }] }
```
''';

const _createUserPostmanScript = '''
const body = pm.response.json();

pm.test("Status is 201 Created", () => {
  pm.response.to.have.status(201);
});

pm.test("Response has user id", () => {
  pm.expect(body).to.have.property("id");
});

if (body.id) {
  pm.environment.set("userId", body.id);
  console.log("userId set:", body.id);
}
''';

const _createUserBrunoScript = '''
const body = res.getBody();

test("Status is 201 Created", function() {
  expect(res.getStatus()).to.equal(201);
});

test("Response has user id", function() {
  expect(body).to.have.property("id");
});

if (body.id) {
  bru.setEnvVar("userId", body.id);
}
''';

/// Documentation for /v1/users
final v1UsersApiDoc = Api.path()
    .get(
      (op) => op
          .summary('List all users')
          .description(_listUsersDoc)
          .tag('Users')
          .security([openapiBearer.componentKey])
          .query(
            'search',
            ParamType.string,
            description: 'Filter by name or e-mail (case-insensitive substring)',
            example: 'alice',
          )
          .query(
            'page',
            ParamType.integer,
            description: 'Page number — 1-based',
            example: 1,
          )
          .query(
            'limit',
            ParamType.integer,
            description: 'Items per page (1–100)',
            example: 20,
          )
          .returns(
            200,
            schema: $UserListResponseDtoSchema,
            description: 'Paginated list of users',
          )
          .responseHeader(
            200,
            'X-Total-Count',
            ParamType.integer,
            description: 'Total number of users matching the query (before pagination)',
            example: 3,
          ),
    )
    .post(
      (op) => op
          .summary('Create a user')
          .description(_createUserDoc)
          .tag('Users')
          .header(
            'X-Request-Id',
            ParamType.string,
            description: 'Idempotency key — repeating the same key returns the cached response',
            format: 'uuid',
          )
          .body($CreateUserDtoSchema)
          .returns(
            201,
            schema: $UserResponseDtoSchema,
            description: 'User created — see Location header for the resource URL',
          )
          .responseHeader(
            201,
            'Location',
            ParamType.string,
            description: 'URL of the newly created user',
            example: '/v1/users/u12345',
          )
          .postman(_createUserPostmanScript)
          .bruno(_createUserBrunoScript),
    )
    .build();

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _listUsers(context),
    HttpMethod.post => _createUser(context),
    _ => Response(statusCode: 405),
  };
}

// Gap 1: reads search / page / limit query parameters and returns
// X-Total-Count in the response header (Gap 6).
Response _listUsers(RequestContext context) {
  final params = context.request.uri.queryParameters;
  final search = params['search'];
  final page = (int.tryParse(params['page'] ?? '') ?? 1).clamp(1, 10000);
  final limit = (int.tryParse(params['limit'] ?? '') ?? 20).clamp(1, 100);

  var users = InMemoryStore.listUsers();

  if (search != null && search.isNotEmpty) {
    final q = search.toLowerCase();
    users = users
        .where(
          (u) => ((u['name'] as String?) ?? '').toLowerCase().contains(q) || ((u['email'] as String?) ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  final total = users.length;
  final start = ((page - 1) * limit).clamp(0, total);
  final end = (start + limit).clamp(start, total);
  final page_ = users.sublist(start, end);

  return Response.json(
    body: {'data': page_, 'total': total},
    headers: {'X-Total-Count': '$total'},
  );
}

Future<Response> _createUser(RequestContext context) async {
  return ztoHandler(() async {
    final (body, error) = await parseBody(context);
    if (error != null) return error;

    final dto = $CreateUserDtoSchema
        .parse(
          body!,
          CreateUserDto.fromMap,
        )
        .refine(
          (d) => d.role != 'admin' || d.email.endsWith('@example.com'),
          field: 'email',
          message: 'Admin accounts must use an @example.com email',
        );

    final user = InMemoryStore.createUser({
      'name': dto.name,
      'email': dto.email,
      'role': dto.role,
    });

    return Response.json(
      statusCode: 201,
      body: user,
      headers: {'Location': '/v1/users/${user['id']}'},
    );
  });
}
