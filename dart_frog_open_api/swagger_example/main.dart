import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import 'open_api/config.dart';

late final DartFrogOpenApi openApi;

Future<void> init(InternetAddress ip, int port) async {
  openApi = DartFrogOpenApi(config: openApiConfig);
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) => serve(handler, ip, port);
