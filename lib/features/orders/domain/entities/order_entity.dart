import 'package:equatable/equatable.dart';

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final String supplierId;
  final List<Map<String, dynamic>> items; // JSONB in DB
  final double totalAmount;
  final String status; // pending, completed, cancelled
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.supplierId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, supplierId, items, totalAmount, status, createdAt];
}
