import 'package:dart_frog/dart_frog.dart';

// Fake credentials — for local testing only.
const _validBearerToken = 'test-token-123';
const _validApiKey = 'api-key-abc456';

Handler middleware(Handler handler) {
  return (RequestContext context) {
    final authResult = _authenticate(context.request);
    if (authResult != null) return authResult;
    return handler(context);
  };
}

/// Validates each provided credential individually:
/// - If Authorization header is present, the token must be correct.
/// - If X-API-Key header is present, the key must be correct.
/// - At least one credential must be present and valid.
Response? _authenticate(Request request) {
  final bearerResult = _validateBearer(request);
  final apiKeyResult = _validateApiKey(request);

  if (bearerResult == _CredentialResult.invalid) {
    return _unauthorizedResponse('Invalid Bearer token.');
  }

  if (apiKeyResult == _CredentialResult.invalid) {
    return _unauthorizedResponse('Invalid X-API-Key.');
  }

  final hasValidCredential = bearerResult == _CredentialResult.valid ||
      apiKeyResult == _CredentialResult.valid;

  if (!hasValidCredential) {
    return _unauthorizedResponse(
      'No credentials provided. Send a Bearer token or X-API-Key.',
    );
  }

  return null;
}

enum _CredentialResult { valid, invalid, absent }

_CredentialResult _validateBearer(Request request) {
  final authHeader = request.headers['Authorization'];
  if (authHeader == null) return _CredentialResult.absent;
  if (authHeader == 'Bearer $_validBearerToken') return _CredentialResult.valid;
  return _CredentialResult.invalid;
}

_CredentialResult _validateApiKey(Request request) {
  final apiKey = request.headers['X-API-Key'];
  if (apiKey == null) return _CredentialResult.absent;
  if (apiKey == _validApiKey) return _CredentialResult.valid;
  return _CredentialResult.invalid;
}

Response _unauthorizedResponse(String message) {
  return Response.json(
    statusCode: 401,
    body: {
      'error': 'Unauthorized',
      'message': message,
      'hint': {
        'bearer': 'Authorization: Bearer $_validBearerToken',
        'apiKey': 'X-API-Key: $_validApiKey',
      },
    },
  );
}
