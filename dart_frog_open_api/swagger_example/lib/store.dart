import 'dart:math';

/// Simple in-memory store that simulates a backend database.
/// Pre-seeded with demo data.
abstract final class InMemoryStore {
  static final _random = Random();

  static String _generateId() =>
      _random.nextInt(90000 + 10000).toString().padLeft(5, '0');

  // ── Users ─────────────────────────────────────────────────────────────────

  static final _users = <String, Map<String, dynamic>>{
    'u001': {
      'id': 'u001',
      'name': 'Alice Silva',
      'email': 'alice@example.com',
      'role': 'admin',
      'createdAt': '2024-01-10T08:00:00.000Z',
    },
    'u002': {
      'id': 'u002',
      'name': 'Bob Santos',
      'email': 'bob@corp.com',
      'role': 'editor',
      'createdAt': '2024-02-15T14:30:00.000Z',
    },
    'u003': {
      'id': 'u003',
      'name': 'Carol Oliveira',
      'email': 'carol@corp.com',
      'role': 'viewer',
      'createdAt': '2024-03-01T09:15:00.000Z',
    },
  };

  static List<Map<String, dynamic>> listUsers() =>
      _users.values.toList();

  static Map<String, dynamic>? findUser(String id) => _users[id];

  static Map<String, dynamic> createUser(Map<String, dynamic> data) {
    final id = 'u${_generateId()}';
    final user = {
      'id': id,
      ...data,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _users[id] = user;
    return user;
  }

  static Map<String, dynamic>? updateUser(
    String id,
    Map<String, dynamic> patch,
  ) {
    final user = _users[id];
    if (user == null) return null;
    _users[id] = {...user, ...patch};
    return _users[id];
  }

  static bool deleteUser(String id) {
    if (!_users.containsKey(id)) return false;
    _users.remove(id);
    return true;
  }

  // ── Products ──────────────────────────────────────────────────────────────

  static final _products = <String, Map<String, dynamic>>{
    'p001': {
      'id': 'p001',
      'name': 'Widget Pro',
      'price': 29.99,
      'sku': 'WGT-001',
    },
    'p002': {
      'id': 'p002',
      'name': 'Gadget Lite',
      'price': 9.99,
      'sku': null,
    },
    'p003': {
      'id': 'p003',
      'name': 'Super Device',
      'price': 149.00,
      'sku': 'SDV-003',
    },
  };

  static List<Map<String, dynamic>> listProducts() =>
      _products.values.toList();

  static Map<String, dynamic>? findProduct(String id) => _products[id];

  static Map<String, dynamic> createProduct(Map<String, dynamic> data) {
    final id = 'p${_generateId()}';
    final product = {'id': id, ...data};
    _products[id] = product;
    return product;
  }

  static bool deleteProduct(String id) {
    if (!_products.containsKey(id)) return false;
    _products.remove(id);
    return true;
  }
}
