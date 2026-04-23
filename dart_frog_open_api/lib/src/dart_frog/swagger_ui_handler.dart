import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dart_frog/dart_frog.dart';

import '../bruno/bruno_collection_builder.dart';
import '../internal/collection_utils.dart';
import '../open_api_builder/open_api_info.dart';
import '../postman/postman_collection_builder.dart';
import '../schemas/security_scheme.dart';
import '../schemas/path_schema.dart';
import '../security/security_config.dart';
import '../security/security_guard.dart';
import '../security/input_sanitizer.dart';

/// Returns a Dart Frog [Handler] that serves the Swagger UI HTML page.
///
/// The page loads Swagger UI from the official CDN and points it at
/// [specUrl] (default: `/openapi`).
///
/// When [info] is provided, the handler serves downloadable
/// collections via query parameters and injects styled download buttons:
///
/// - `?format=postman` → Postman Collection v2.1 JSON
/// - `?format=bruno`   → ZIP archive of Bruno `.bru` files (only when
///   [brunoOutputDir] is set)
///
/// [brunoOutputDir]: When set, enables the Bruno button and writes the
/// collection to this directory on every request. Omit to disable Bruno.
///
/// Usage (same config as [swaggerJsonHandler]):
/// ```dart
/// swaggerUiHandler(
///   specUrl: '/openapi',
///   info: apiInfo,
///   securitySchemes: apiSecuritySchemes,
///   pathSchemas: apiPathSchemas,
///   brunoOutputDir: Directory('bruno_collection'), // optional
/// );
/// ```
Handler swaggerUiHandler({
  String specUrl = '/openapi',
  // Shared config (Postman + Bruno)
  OpenApiInfo? info,
  Map<String, PathSchema>? pathSchemas,
  Map<String, SecurityScheme>? securitySchemes,
  String baseUrl = 'http://localhost:8080',

  /// When set, enables the Bruno download button and writes the collection to
  /// this directory once at handler initialization. Omit to disable Bruno.
  Directory? brunoOutputDir,
  SecurityConfig security = const SecurityConfig(),
}) {
  final resolvedInfo = info;
  final postmanUrl = resolvedInfo != null ? '?format=postman' : null;
  final brunoUrl =
      resolvedInfo != null && brunoOutputDir != null ? '?format=bruno' : null;

  // Write Bruno files to disk once at initialization, not on every request.
  if (resolvedInfo != null && brunoOutputDir != null) {
    _writeBrunoToDisk(
      info: resolvedInfo,
      pathSchemas: pathSchemas ?? const {},
      securitySchemes: securitySchemes ?? const {},
      baseUrl: baseUrl,
      outputDir: brunoOutputDir,
    );
  }

  return (RequestContext context) {
    if (context.request.method != HttpMethod.get) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final format = context.request.uri.queryParameters['format'];

    if (format == 'postman' && resolvedInfo != null) {
      return _servePostman(
        info: resolvedInfo,
        pathSchemas: pathSchemas ?? const {},
        securitySchemes: securitySchemes ?? const {},
        baseUrl: baseUrl,
      );
    }

    if (format == 'bruno' && resolvedInfo != null && brunoOutputDir != null) {
      return _serveBruno(
        info: resolvedInfo,
        pathSchemas: pathSchemas ?? const {},
        securitySchemes: securitySchemes ?? const {},
        baseUrl: baseUrl,
      );
    }

    final html = _buildHtml(
      InputSanitizer.sanitizeSpecUrl(specUrl),
      postmanUrl,
      brunoUrl,
      title: InputSanitizer.escapeForHtml(info?.title ?? 'API Docs'),
    );

    final secHeaders = SecurityGuard.securityResponseHeaders(security);
    final corsHeaders = SecurityGuard.corsHeaders(context.request, security);

    return Response(
      body: html,
      headers: {
        HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
        ...secHeaders,
        ...corsHeaders,
      },
    );
  };
}

// ---------------------------------------------------------------------------
// Postman response
// ---------------------------------------------------------------------------

Response _servePostman({
  required OpenApiInfo info,
  required Map<String, PathSchema> pathSchemas,
  required Map<String, SecurityScheme> securitySchemes,
  required String baseUrl,
}) {
  final collection = PostmanCollectionBuilder(
    info: info,
    pathSchemas: pathSchemas,
    securitySchemes: securitySchemes,
    baseUrl: baseUrl,
  ).build();

  final json = const JsonEncoder.withIndent('  ').convert(collection);

  return Response(
    body: json,
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      'Content-Disposition':
          'attachment; filename="${toFilename(info.title)}.postman_collection.json"',
    },
  );
}

void _writeBrunoToDisk({
  required OpenApiInfo info,
  required Map<String, PathSchema> pathSchemas,
  required Map<String, SecurityScheme> securitySchemes,
  required String baseUrl,
  required Directory outputDir,
}) {
  final files = BrunoCollectionBuilder(
    info: info,
    pathSchemas: pathSchemas,
    securitySchemes: securitySchemes,
    baseUrl: baseUrl,
  ).build();

  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final entry in files.entries) {
    final file = File.fromUri(outputDir.uri.resolve(entry.key));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
  }
}

Response _serveBruno({
  required OpenApiInfo info,
  required Map<String, PathSchema> pathSchemas,
  required Map<String, SecurityScheme> securitySchemes,
  required String baseUrl,
}) {
  final files = BrunoCollectionBuilder(
    info: info,
    pathSchemas: pathSchemas,
    securitySchemes: securitySchemes,
    baseUrl: baseUrl,
  ).build();

  final archive = Archive();
  final collectionFolder = toFilename(info.title);

  for (final entry in files.entries) {
    final bytes = utf8.encode(entry.value);
    archive.addFile(
      ArchiveFile('$collectionFolder/${entry.key}', bytes.length, bytes),
    );
  }

  final zipBytes = ZipEncoder().encode(archive);

  return Response.bytes(
    body: zipBytes,
    headers: {
      HttpHeaders.contentTypeHeader: 'application/zip',
      'Content-Disposition':
          'attachment; filename="${toFilename(info.title)}.bruno.zip"',
    },
  );
}

// ---------------------------------------------------------------------------
// HTML builder
// ---------------------------------------------------------------------------

String _buildHtml(String specUrl, String? postmanUrl, String? brunoUrl,
    {String title = 'API Docs'}) {
  final buttons = _buildButtons(postmanUrl, brunoUrl);

  return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$title — Swagger UI</title>
    <link
      rel="stylesheet"
      href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css"
    />
    <style>
      body { margin: 0; }
    </style>
  </head>
  <body>
    $buttons
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
      SwaggerUIBundle({
        url: "$specUrl",
        dom_id: "#swagger-ui",
        presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
        layout: "BaseLayout",
        deepLinking: true,
        tryItOutEnabled: true,
      });
    </script>
  </body>
</html>
''';
}

String _buildButtons(String? postmanUrl, String? brunoUrl) {
  if (postmanUrl == null && brunoUrl == null) return '';

  final buttonItems = <String>[];

  if (postmanUrl != null) {
    buttonItems.add(_downloadButton(
      href: postmanUrl,
      color: '#FF6C37',
      hoverColor: '#e85d27',
      label: 'Postman',
      icon: _downloadSvg,
    ));
  }

  if (brunoUrl != null) {
    buttonItems.add(_downloadButton(
      href: brunoUrl,
      color: '#7B3F00',
      hoverColor: '#5c2e00',
      label: 'Bruno',
      icon: _downloadSvg,
    ));
  }

  return '''
    <div style="
      position: fixed;
      top: 16px;
      right: 20px;
      z-index: 9999;
      display: flex;
      gap: 10px;
      font-family: sans-serif;
    ">
      ${buttonItems.join('\n      ')}
    </div>''';
}

String _downloadButton({
  required String href,
  required String color,
  required String hoverColor,
  required String label,
  required String icon,
}) =>
    '''<a
        href="$href"
        download
        style="
          display: inline-flex;
          align-items: center;
          gap: 8px;
          background: $color;
          color: #fff;
          padding: 9px 18px;
          border-radius: 6px;
          text-decoration: none;
          font-size: 13px;
          font-weight: 600;
          letter-spacing: 0.3px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.25);
          transition: background 0.2s;
        "
        onmouseover="this.style.background='$hoverColor'"
        onmouseout="this.style.background='$color'"
      >
        $icon
        $label
      </a>''';

const _downloadSvg =
    '''<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
          <polyline points="7 10 12 15 17 10"/>
          <line x1="12" y1="15" x2="12" y2="3"/>
        </svg>''';
