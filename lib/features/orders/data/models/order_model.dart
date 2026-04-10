import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.supplierId,
    required super.items,
    required super.totalAmount,
    required super.status,
    required super.createdAt,
    super.customerName,
    super.customerAvatarUrl,
    super.customerRole,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['customer_id'],
      supplierId: json['supplier_id'],
      items: List<Map<String, dynamic>>.from(json['items']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      customerName: json['customer'] != null ? json['customer']['name'] : (json['users'] != null ? json['users']['name'] : null),
      customerAvatarUrl: json['customer'] != null ? json['customer']['avatar_url'] : (json['users'] != null ? json['users']['avatar_url'] : null),
      customerRole: json['customer'] != null ? json['customer']['role'] : (json['users'] != null ? json['users']['role'] : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': userId,
      'supplier_id': supplierId,
      'items': items,
      'total_amount': totalAmount,
      'status': status,
    };
  }
}
