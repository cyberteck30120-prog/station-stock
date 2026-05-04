import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum SpaceType { bar, metro, labo }

class Product {
  final String id;
  final String name;
  final double quantity;
  final double minQuantity;
  final String unit;
  final int orderIndex;
  final SpaceType space;
  final String restaurant; // "Cathédrale" ou "Beaux Arts"
  final String? imagePath;
  final double priceHT;

  Product({
    String? id,
    required this.name,
    this.quantity = 0.0,
    this.minQuantity = 0.0,
    this.unit = 'unités',
    this.orderIndex = 0,
    required this.space,
    this.restaurant = 'Cathédrale',
    this.imagePath,
    this.priceHT = 0.0,
  }) : id = id ?? uuid.v4();

  Product copyWith({
    String? id,
    String? name,
    double? quantity,
    double? minQuantity,
    String? unit,
    int? orderIndex,
    SpaceType? space,
    String? restaurant,
    String? imagePath,
    double? priceHT,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
      orderIndex: orderIndex ?? this.orderIndex,
      space: space ?? this.space,
      restaurant: restaurant ?? this.restaurant,
      imagePath: imagePath ?? this.imagePath,
      priceHT: priceHT ?? this.priceHT,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'unit': unit,
      'order_index': orderIndex,
      'space': space.index,
      'restaurant': restaurant,
      'image_path': imagePath,
      'price_ht': priceHT,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      quantity: (map['quantity'] as num).toDouble(),
      minQuantity: (map['min_quantity'] as num).toDouble(),
      unit: map['unit'],
      orderIndex: map['order_index'] ?? 0,
      space: SpaceType.values[map['space']],
      restaurant: map['restaurant'] ?? 'Cathédrale',
      imagePath: map['image_path'],
      priceHT: (map['price_ht'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ── Utilisateurs ─────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String name;
  final String pin;
  final String role;
  final String restaurant;
  final bool canCreateProducts;
  final bool canViewStats;
  final bool canViewHistory;

  AppUser({
    String? id,
    required this.name,
    this.pin = '1234',
    this.role = 'employe',
    this.restaurant = 'Cathédrale',
    this.canCreateProducts = false,
    this.canViewStats = false,
    this.canViewHistory = false,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'pin': pin,
    'role': role,
    'restaurant': restaurant,
    'can_create_products': canCreateProducts ? 1 : 0,
    'can_view_stats': canViewStats ? 1 : 0,
    'can_view_history': canViewHistory ? 1 : 0,
  };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id'],
    name: m['name'],
    pin: m['pin'] ?? '1234',
    role: m['role'] ?? 'employe',
    restaurant: m['restaurant'] ?? 'Cathédrale',
    canCreateProducts: (m['can_create_products'] ?? 0) == 1,
    canViewStats: (m['can_view_stats'] ?? 0) == 1,
    canViewHistory: (m['can_view_history'] ?? 0) == 1,
  );
}

// ── Historique ────────────────────────────────────────────────────────────────

class SnapshotItem {
  final String id;
  final String snapshotId;
  final String name;
  final double quantity;
  final String unit;
  final SpaceType space;
  final double priceHT;

  SnapshotItem({
    String? id,
    required this.snapshotId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.space,
    this.priceHT = 0.0,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'snapshot_id': snapshotId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'space': space.index,
        'price_ht': priceHT,
      };

  factory SnapshotItem.fromMap(Map<String, dynamic> m) => SnapshotItem(
        id: m['id'],
        snapshotId: m['snapshot_id'],
        name: m['name'],
        quantity: (m['quantity'] as num).toDouble(),
        unit: m['unit'],
        space: SpaceType.values[m['space']],
        priceHT: (m['price_ht'] as num?)?.toDouble() ?? 0.0,
      );
}

class StockSnapshot {
  final String id;
  final DateTime date;
  final String label; // Ex: "Semaine 17 – 28 avr. 2026"
  final String restaurant;
  final String createdBy; // Nom de la personne qui a fait le relevé
  final List<SnapshotItem> items;

  StockSnapshot({
    String? id,
    required this.date,
    required this.label,
    this.restaurant = 'Cathédrale',
    this.createdBy = 'Inconnu',
    this.items = const [],
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'label': label,
        'restaurant': restaurant,
        'created_by': createdBy,
      };

  factory StockSnapshot.fromMap(Map<String, dynamic> m, List<SnapshotItem> items) =>
      StockSnapshot(
        id: m['id'],
        date: DateTime.parse(m['date']),
        label: m['label'],
        restaurant: m['restaurant'] ?? 'Cathédrale',
        createdBy: m['created_by'] ?? 'Inconnu',
        items: items,
      );
}
// ── Activités ────────────────────────────────────────────────────────────────

class ActivityLog {
  final String id;
  final DateTime date;
  final String userName;
  final String action; // Ex: "Ajout", "Modification", "Stock", "Suppression"
  final String details; // Ex: "Lait d'Amande : 10 -> 15"
  final String? productId;

  ActivityLog({
    String? id,
    required this.date,
    required this.userName,
    required this.action,
    required this.details,
    this.productId,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'user_name': userName,
    'action': action,
    'details': details,
    'product_id': productId,
  };

  factory ActivityLog.fromMap(Map<String, dynamic> m) => ActivityLog(
    id: m['id'],
    date: DateTime.parse(m['date']),
    userName: m['user_name'],
    action: m['action'],
    details: m['details'],
    productId: m['product_id'],
  );
}
