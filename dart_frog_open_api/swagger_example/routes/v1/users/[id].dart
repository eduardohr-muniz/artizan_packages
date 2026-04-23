library;

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart' hide HttpMethod;

import 'package:swagger_example/dtos/user_dto.dart';
import 'package:swagger_example/response.dart';
import 'package:swagger_example/store.dart';

// ── Documentation ────────────────────────────────────────────────────────────

const _patchUserDoc = '''
## Partial Update User

Updates only the fields provided in the request body — body is **optional**.
Sending an empty body (or omitting it entirely) is valid and returns the current state.

### Patchable fields
- `name` — new display name
- `email` — new e-mail address (must be valid)

### Example — update only the name
```json
{ "name": "Alice Wonderland" }
```
''';

const _patchUserPostmanScript = '''
const body = pm.response.json();

pm.test("Status is 200 OK", () => {
  pm.response.to.have.status(200);
});

pm.test("Response has user id", () => {
  pm.expect(body).to.have.property("id");
});
''';

const _patchUserBrunoScript = '''
const body = res.getBody();

test("Status is 200 OK", function() {
  expect(res.getStatus()).to.equal(200);
});

test("Response has user id", function() {
  expect(body).to.have.property("id");
});
''';

/// Documentation for /v1/users/{id}
final v1UsersIdApiDoc = Api.path()
    .param(
      'id',
      ParamType.string,
      description: 'Unique user identifier',
      example: 'u001',
    )
    .get(
      (op) => op
          .summary('Get user by ID')
          .tag('Users')
          .returns(200, schema: $UserResponseDtoSchema, description: 'User found')
          .returns(404, description: 'User not found'),
    )
    .put(
      (op) => op
          .summary('Replace user')
          .tag('Users')
          .body($UpdateUserDtoSchema)
          .returns(200, schema: $UserResponseDtoSchema),
    )
    .patch(
      (op) => op
          .summary('Partially update user')
          .description(_patchUserDoc)
          .tag('Users')
          .body($UpdateUserDtoSchema, required: false)
          .returns(200, schema: $UserResponseDtoSchema)
          .postman(_patchUserPostmanScript)
          .bruno(_patchUserBrunoScript),
    )
    .delete(
      (op) => op
          .summary('Delete user')
          .tag('Users')
          .returns(204, description: 'User deleted successfully'),
    )
    .build();

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getUser(id),
    HttpMethod.put => _updateUser(context, id),
    HttpMethod.patch => _patchUser(context, id),
    HttpMethod.delete => _deleteUser(id),
    _ => Response(statusCode: 405),
  };
}

Response _getUser(String id) {
  final user = InMemoryStore.findUser(id);
  if (user == null) return Response.json(statusCode: 404, body: {'message': 'User not found'});
  return Response.json(body: user);
}

Future<Response> _updateUser(RequestContext context, String id) async {
  return ztoHandler(() async {
    final user = InMemoryStore.findUser(id);
    if (user == null) return Response.json(statusCode: 404, body: {'message': 'User not found'});

    final (body, error) = await parseBody(context);
    if (error != null) return error;

    final dto = $UpdateUserDtoSchema.parse(body!, UpdateUserDto.fromMap);
    final updated = InMemoryStore.updateUser(id, {
      if (dto.name != null) 'name': dto.name,
      if (dto.email != null) 'email': dto.email,
    });

    return Response.json(body: updated);
  });
}

// Gap 5: requestBodyRequired=false — body is optional for PATCH.
Future<Response> _patchUser(RequestContext context, String id) async {
  return ztoHandler(() async {
    final existing = InMemoryStore.findUser(id);
    if (existing == null) {
      return Response.json(statusCode: 404, body: {'message': 'User not found'});
    }

    Map<String, dynamic>? body;
    try {
      body = await context.request.json() as Map<String, dynamic>;
    } catch (_) {
      // Empty or missing body is valid for PATCH — return current state.
    }

    if (body != null && body.isNotEmpty) {
      final dto = $UpdateUserDtoSchema.parse(body, UpdateUserDto.fromMap);
      InMemoryStore.updateUser(id, {
        if (dto.name != null) 'name': dto.name,
        if (dto.email != null) 'email': dto.email,
      });
    }

    return Response.json(body: InMemoryStore.findUser(id));
  });
}

Response _deleteUser(String id) {
  final deleted = InMemoryStore.deleteUser(id);
  if (!deleted) return Response.json(statusCode: 404, body: {'message': 'User not found'});
  return Response(statusCode: 204);
}
