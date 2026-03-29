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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      supplierId: json['supplier_id'],
      items: List<Map<String, dynamic>>.from(json['items']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'supplier_id': supplierId,
      'items': items,
      'total_amount': totalAmount,
      'status': status,
    };
  }
}
