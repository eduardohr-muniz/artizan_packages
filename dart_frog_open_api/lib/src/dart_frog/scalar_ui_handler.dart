import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../open_api_builder/scalar_options.dart';
import '../security/input_sanitizer.dart';
import '../security/security_config.dart';
import '../security/security_guard.dart';

Handler scalarUiHandler({
  String specUrl = '/openapi',
  ScalarOptions options = const ScalarOptions(),
  SecurityConfig security = const SecurityConfig(),
  Map<String, dynamic>? authentication,
}) {
  return (RequestContext context) {
    if (context.request.method != HttpMethod.get) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final html = _buildHtml(
      InputSanitizer.sanitizeSpecUrl(specUrl),
      options: options,
      authentication: authentication,
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

String _buildHtml(
  String specUrl, {
  required ScalarOptions options,
  Map<String, dynamic>? authentication,
  String title = 'API Docs',
}) {
  final config = {
    ...options.toJson(),
    if (authentication != null) 'authentication': authentication,
  };
  final configAttr = jsonEncode(config).replaceAll('"', '&quot;');

  return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$title — Scalar API Reference</title>
    <style>
      body { margin: 0; }
    </style>
  </head>
  <body>
    <script
      id="api-reference"
      data-url="$specUrl"
      data-configuration="$configAttr"></script>
    <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
  </body>
</html>
''';
}
