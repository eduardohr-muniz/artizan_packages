library;

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import 'package:swagger_example/dtos/product_dto.dart';
import 'package:swagger_example/response.dart';
import 'package:swagger_example/store.dart';

import '../../../open_api/security_refs.dart';

// ── Documentation ────────────────────────────────────────────────────────────

const _listProductsDoc = '''
## List Products

Returns the inventory of available products.

### Pricing
- Prices are in **USD**.
- Use `minPrice` and `maxPrice` to find products in a specific budget.

### Security
This endpoint requires **either** a Bearer token **or** an API Key.
''';

const _createProductDoc = '''
## Create Product

Adds a new item to the catalog.

### Requirements
- **Admin/Editor** role required (enforced via middleware).
- `price` must be **> 1.0**.
- `sku` must be **unique**.
''';

const _listProductsPostmanScript = '''
pm.test("Status is 200 OK", () => pm.response.to.have.status(200));
const body = pm.response.json();
pm.test("Data is an array", () => pm.expect(body.data).to.be.an("array"));
''';

const _listProductsBrunoScript = '''
test("Status is 200 OK", () => expect(res.getStatus()).to.equal(200));
test("Data is an array", () => expect(res.getBody().data).to.be.an("array"));
''';

const _createProductPostmanScript = '''
pm.test("Status is 201 Created", () => pm.response.to.have.status(201));
''';

const _createProductBrunoScript = '''
test("Status is 201 Created", () => expect(res.getStatus()).to.equal(201));
''';

/// Documentation for /v1/products
final v1ProductsApiDoc = Api.path()
    .get(
      (op) => op
          .summary('List all products')
          .description(_listProductsDoc)
          .tag('Products')
          .security(OpenApiSecurity.componentKeys([openapiBearer, openapiApiKey]))
          .query(
            'sort',
            ParamType.string,
            description: 'Sort field',
            values: ['name', 'price'],
          )
          .query(
            'minPrice',
            ParamType.number,
            description: 'Minimum price filter (inclusive)',
            example: 5.0,
          )
          .query(
            'maxPrice',
            ParamType.number,
            description: 'Maximum price filter (inclusive)',
            example: 100.0,
          )
          .returns(
            200,
            schema: $ProductListResponseDtoSchema,
          )
          .responseHeader(
            200,
            'X-Total-Count',
            ParamType.integer,
            description: 'Total number of products matching the filters (before pagination)',
            example: 3,
          )
          .postman(_listProductsPostmanScript)
          .bruno(_listProductsBrunoScript),
    )
    .post(
      (op) => op
          .summary('Create a product')
          .description(_createProductDoc)
          .tag('Products')
          .security(OpenApiSecurity.componentKeys([openapiBearer, openapiApiKey]))
          .header(
            'X-Request-Id',
            ParamType.string,
            description: 'Idempotency key',
            format: 'uuid',
          )
          .body($CreateProductDtoSchema)
          .returns(
            201,
            schema: $ProductResponseDtoSchema,
            description: 'Product created — see Location header',
          )
          .responseHeader(
            201,
            'Location',
            ParamType.string,
            description: 'URL of the newly created product',
            example: '/v1/products/p12345',
          )
          .postman(_createProductPostmanScript)
          .bruno(_createProductBrunoScript),
    )
    .build();

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _listProducts(context),
    HttpMethod.post => _createProduct(context),
    _ => Response(statusCode: 405),
  };
}

// Gap 1: reads sort / minPrice / maxPrice query parameters and returns
// X-Total-Count in the response header (Gap 6).
Response _listProducts(RequestContext context) {
  final params = context.request.uri.queryParameters;
  final sort = params['sort'];
  final minPrice = double.tryParse(params['minPrice'] ?? '');
  final maxPrice = double.tryParse(params['maxPrice'] ?? '');

  var products = InMemoryStore.listProducts();

  if (minPrice != null) {
    products = products.where((p) => (p['price'] as num) >= minPrice).toList();
  }
  if (maxPrice != null) {
    products = products.where((p) => (p['price'] as num) <= maxPrice).toList();
  }
  if (sort == 'name') {
    products.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  } else if (sort == 'price') {
    products.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
  }

  final total = products.length;
  return Response.json(
    body: {'data': products, 'total': total},
    headers: {'X-Total-Count': '$total'},
  );
}

Future<Response> _createProduct(RequestContext context) async {
  return ztoHandler(() async {
    final (body, error) = await parseBody(context);
    if (error != null) return error;

    final dto =
        $CreateProductDtoSchema.parse(body!, CreateProductDto.fromMap).refine((dto) => dto.price > 1.0, message: 'Price must be greater than 1.0');
    final product = InMemoryStore.createProduct(dto.toMap());

    return Response.json(
      statusCode: 201,
      body: product,
      headers: {'Location': '/v1/products/${product['id']}'},
    );
  });
}
