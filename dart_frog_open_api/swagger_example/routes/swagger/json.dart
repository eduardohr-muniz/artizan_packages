import 'dart:async';

import 'package:dart_frog/dart_frog.dart';
import '../../main.dart';

FutureOr<Response> onRequest(RequestContext context) => openApi.openApiJsonHandler()(context);
