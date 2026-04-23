import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart' hide HttpMethod;
import 'package:swagger_example/dtos/product_dto.dart';
import '../../../open_api/security_refs.dart';
import 'package:swagger_example/store.dart';

/// Documentation for /v1/products/{id}
final v1ProductsIdApiDoc = Api.path()
    .param(
      'id',
      ParamType.string,
      description: 'Unique product identifier',
      example: 'p001',
    )
    .get(
      (op) => op
          .summary('Get product by ID')
          .tag('Products')
          .security(OpenApiSecurity.componentKeys([openapiBearer, openapiApiKey]))
          .returns(
            200,
            schema: $ProductResponseDtoSchema,
            description: 'Product found',
          )
          .returns(404, description: 'Product not found'),
    )
    .delete(
      (op) => op
          .summary('Delete product')
          .tag('Products')
          .returns(204, description: 'Product deleted successfully')
          .returns(404, description: 'Product not found'),
    )
    .build();

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getProduct(id),
    HttpMethod.delete => _deleteProduct(id),
    _ => Response(statusCode: 405),
  };
}

Response _getProduct(String id) {
  final product = InMemoryStore.findProduct(id);
  if (product == null) {
    return Response.json(statusCode: 404, body: {'message': 'Product not found'});
  }
  return Response.json(body: product);
}

Response _deleteProduct(String id) {
  final deleted = InMemoryStore.deleteProduct(id);
  if (!deleted) {
    return Response.json(statusCode: 404, body: {'message': 'Product not found'});
  }
  return Response(statusCode: 204);
}
