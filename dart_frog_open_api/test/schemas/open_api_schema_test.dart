import '../../lib/dart_frog_open_api.dart';
import 'package:test/test.dart';
import 'package:zto/zto.dart';

const _testZtoSchema = ZtoSchema(
  typeName: 'TestDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'id'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(mapKey: 'name', description: 'User name'),
      validators: [],
      isNullable: false,
    ),
  ],
);

void main() {
  group('OpenApiSchema', () {
    test('has typeName and jsonSchema', () {
      const schema = OpenApiSchema(
        typeName: 'MyDto',
        jsonSchema: {'type': 'object', 'properties': {}},
      );
      expect(schema.typeName, equals('MyDto'));
      expect(schema.jsonSchema, equals({'type': 'object', 'properties': {}}));
    });

    test('fromZto returns schema with correct typeName', () {
      final schema = OpenApiSchema.fromZto(_testZtoSchema);
      expect(schema.typeName, equals('TestDto'));
    });

    test('fromZto returns jsonSchema with type object, properties, required', () {
      final schema = OpenApiSchema.fromZto(_testZtoSchema);
      expect(schema.jsonSchema['type'], equals('object'));
      expect(schema.jsonSchema['properties'], isA<Map<String, dynamic>>());
      expect(schema.jsonSchema['required'], containsAll(['id', 'name']));
    });

    test('fromZto jsonSchema properties match ZtoSchema descriptors', () {
      final schema = OpenApiSchema.fromZto(_testZtoSchema);
      final props = schema.jsonSchema['properties'] as Map<String, dynamic>;
      expect(props['id'], equals({'type': 'string'}));
      expect(props['name']['type'], equals('string'));
      expect(props['name']['description'], equals('User name'));
    });
  });
}
