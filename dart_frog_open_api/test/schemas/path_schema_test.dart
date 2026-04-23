import '../../lib/dart_frog_open_api.dart';
import 'package:test/test.dart';
import 'package:zto/zto.dart';

const _testDtoSchema = ZtoSchema(
  typeName: 'TestDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'id'),
      validators: [],
      isNullable: false,
    ),
  ],
);

void main() {
  group('OperationSchema', () {
    test('defaults to null requestBodySchema and empty responseSchemas', () {
      const op = OperationSchema();
      expect(op.requestBodySchema, isNull);
      expect(op.responseSchemas, isEmpty);
    });

    test('holds requestBodySchema', () {
      final op = OperationSchema(requestBodySchema: OpenApiSchema.fromZto(_testDtoSchema));
      expect(op.requestBodySchema!.typeName, equals('TestDto'));
    });

    test('holds responseSchemas keyed by status code', () {
      final op = OperationSchema(responseSchemas: {200: OpenApiSchema.fromZto(_testDtoSchema)});
      expect(op.responseSchemas[200]!.typeName, equals('TestDto'));
    });

    test('responseSchemas supports null for no-content responses', () {
      const op = OperationSchema(responseSchemas: {204: null});
      expect(op.responseSchemas[204], isNull);
    });
  });

  group('PathSchema', () {
    test('all methods default to null', () {
      const schema = PathSchema();
      expect(schema.get, isNull);
      expect(schema.post, isNull);
      expect(schema.put, isNull);
      expect(schema.patch, isNull);
      expect(schema.delete, isNull);
    });

    test('forMethod returns correct OperationSchema', () {
      const op = OperationSchema();
      const schema = PathSchema(post: op);
      expect(schema.forMethod('post'), same(op));
      expect(schema.forMethod('get'), isNull);
    });

    test('forMethod returns null for unknown method', () {
      const schema = PathSchema();
      expect(schema.forMethod('head'), isNull);
      expect(schema.forMethod('options'), isNull);
    });

    test('can define schemas for multiple methods', () {
      final getOp = OperationSchema(responseSchemas: {200: OpenApiSchema.fromZto(_testDtoSchema)});
      final postOp = OperationSchema(requestBodySchema: OpenApiSchema.fromZto(_testDtoSchema));

      final schema = PathSchema(get: getOp, post: postOp);
      expect(schema.forMethod('get'), same(getOp));
      expect(schema.forMethod('post'), same(postOp));
      expect(schema.forMethod('delete'), isNull);
    });
  });

  group('OperationSchema Bruno fields', () {
    test('brunoTestScript defaults to null', () {
      const op = OperationSchema();
      expect(op.brunoTestScript, isNull);
    });

    test('brunoPreRequestScript defaults to null', () {
      const op = OperationSchema();
      expect(op.brunoPreRequestScript, isNull);
    });

    test('holds brunoTestScript value', () {
      const script = 'test("ok", function() { expect(res.getStatus()).to.equal(200); });';
      const op = OperationSchema(brunoTestScript: script);
      expect(op.brunoTestScript, equals(script));
    });

    test('holds brunoPreRequestScript value', () {
      const script = 'bru.setEnvVar("ts", Date.now().toString());';
      const op = OperationSchema(brunoPreRequestScript: script);
      expect(op.brunoPreRequestScript, equals(script));
    });

    test('postman and bruno scripts are independent', () {
      const op = OperationSchema(
        postmanTestScript: 'pm.test("ok", () => {});',
        brunoTestScript: 'test("ok", function() {});',
      );
      expect(op.postmanTestScript, contains('pm.test'));
      expect(op.brunoTestScript, contains('test("ok"'));
    });
  });

  // ── Gap 10b — New fields coverage ───────────────────────────────────────────

  group('OperationSchema.queryParameters', () {
    test('defaults to empty list', () {
      const op = OperationSchema();
      expect(op.queryParameters, isEmpty);
    });

    test('holds query parameters', () {
      const op = OperationSchema(
        queryParameters: [
          ParameterSchema(name: 'search', type: 'string'),
          ParameterSchema(name: 'page', type: 'integer', required: true),
        ],
      );
      expect(op.queryParameters, hasLength(2));
      expect(op.queryParameters.first.name, 'search');
      expect(op.queryParameters.last.required, isTrue);
    });
  });

  group('OperationSchema.headerParameters', () {
    test('defaults to empty list', () {
      const op = OperationSchema();
      expect(op.headerParameters, isEmpty);
    });

    test('holds header parameters', () {
      const op = OperationSchema(
        headerParameters: [
          ParameterSchema(name: 'X-Tenant-Id', type: 'string', description: 'Tenant identifier'),
        ],
      );
      expect(op.headerParameters, hasLength(1));
      expect(op.headerParameters.first.name, 'X-Tenant-Id');
      expect(op.headerParameters.first.description, 'Tenant identifier');
    });
  });

  group('OperationSchema.requestBodyRequired', () {
    test('defaults to true', () {
      const op = OperationSchema();
      expect(op.requestBodyRequired, isTrue);
    });

    test('can be set to false', () {
      const op = OperationSchema(requestBodyRequired: false);
      expect(op.requestBodyRequired, isFalse);
    });
  });

  group('ResponseHeaderSchema', () {
    test('holds name, description, and default type string', () {
      const h = ResponseHeaderSchema(name: 'Location', description: 'Resource URL');
      expect(h.name, 'Location');
      expect(h.description, 'Resource URL');
      expect(h.type, 'string');
      expect(h.format, isNull);
      expect(h.example, isNull);
    });

    test('holds custom type and format', () {
      const h = ResponseHeaderSchema(
        name: 'X-Rate-Limit',
        description: 'Remaining requests',
        type: 'integer',
        example: 100,
      );
      expect(h.type, 'integer');
      expect(h.example, 100);
    });
  });

  group('ParameterSchema', () {
    test('holds all fields', () {
      const p = ParameterSchema(
        name: 'page',
        type: 'integer',
        description: 'Page number',
        required: true,
        example: 1,
        enumValues: ['1', '2', '3'],
        format: 'int32',
      );
      expect(p.name, 'page');
      expect(p.type, 'integer');
      expect(p.description, 'Page number');
      expect(p.required, isTrue);
      expect(p.example, 1);
      expect(p.enumValues, ['1', '2', '3']);
      expect(p.format, 'int32');
    });

    test('required defaults to false', () {
      const p = ParameterSchema(name: 'q', type: 'string');
      expect(p.required, isFalse);
    });
  });

  group('PathSchema.pathParameters', () {
    test('defaults to empty map', () {
      const schema = PathSchema();
      expect(schema.pathParameters, isEmpty);
    });

    test('holds path parameter overrides', () {
      const schema = PathSchema(
        pathParameters: {
          'id': ParameterSchema(name: 'id', type: 'integer', description: 'Resource ID'),
        },
      );
      expect(schema.pathParameters.containsKey('id'), isTrue);
      expect(schema.pathParameters['id']!.type, 'integer');
    });
  });
}
