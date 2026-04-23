import 'package:dart_frog/dart_frog.dart';
import 'package:zto/zto.dart';

/// Wraps a route handler and catches [ZtoException], returning HTTP 422.
Future<Response> ztoHandler(Future<Response> Function() handler) async {
  try {
    return await handler();
  } on ZtoException catch (e) {
    return Response.json(statusCode: 422, body: e.toMap());
  }
}

/// Parses the request body as JSON and returns `(map, null)` on success
/// or `(null, 400 response)` when the body is missing or invalid JSON.
Future<(Map<String, dynamic>?, Response?)> parseBody(
  RequestContext context,
) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    return (body, null);
  } catch (_) {
    return (null, Response.json(statusCode: 400, body: {'message': 'Invalid JSON body'}));
  }
}
