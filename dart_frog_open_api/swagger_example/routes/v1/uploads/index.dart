library;

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart' hide HttpMethod;
import 'package:swagger_example/dtos/upload_dto.dart';

// ── Documentation ────────────────────────────────────────────────────────────

const _uploadFileDoc = '''
## Upload File

Endpoint for uploading binary assets to the system.

### Details
- Uses `multipart/form-data`.
- Maximum file size: **10MB**.
- Supported types: `PNG`, `JPG`, `PDF`.
''';

/// Documentation for /v1/uploads
final v1UploadsApiDoc = Api.path()
    .post(
      (op) => op
          .summary('Upload a file')
          .description(_uploadFileDoc)
          .tag('Uploads')
          .body($UploadRequestDtoSchema, contentType: 'multipart/form-data')
          .returns(
            201,
            schema: $UploadResponseDtoSchema,
            description: 'File uploaded and stored successfully',
          ),
    )
    .build();

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _uploadFile(context),
    _ => Response(statusCode: 405),
  };
}

// Gap 4 & 13: multipart/form-data file upload.
// In a real server you would parse the multipart body to extract the file
// bytes (e.g., using the `mime` package). Here we simulate a successful
// upload and return metadata.
Future<Response> _uploadFile(RequestContext context) async {
  // Collect body bytes to derive the uploaded size.
  final chunks = await context.request.bytes().toList();
  final size = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);

  return Response.json(
    statusCode: 201,
    body: {
      'fileName': 'uploaded_file.bin',
      'size': size,
      'mimeType': 'application/octet-stream',
    },
  );
}
