import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import '../routes/v1/users/index.dart';
import '../routes/v1/users/[id].dart';
import '../routes/v1/products/index.dart';
import '../routes/v1/products/[id].dart';
import '../routes/v1/uploads/index.dart';
import '../routes/v1/auth/login.dart';

final apiPathSchemas = <String, PathSchema>{
  '/v1/users': v1UsersApiDoc,
  '/v1/users/{id}': v1UsersIdApiDoc,
  '/v1/products': v1ProductsApiDoc,
  '/v1/products/{id}': v1ProductsIdApiDoc,
  '/v1/uploads': v1UploadsApiDoc,
  '/v1/auth/login': v1AuthLoginApiDoc,
};
