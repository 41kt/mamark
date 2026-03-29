import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final String? productName; // Helper field
  final double? productPrice; // Helper field
  final String? productImageUrl; // Helper field
  final String? supplierId; // Helper field

  const CartItemEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.productName,
    this.productPrice,
    this.productImageUrl,
    this.supplierId,
  });

  @override
  List<Object?> get props => [id, userId, productId, quantity, productName, productPrice, productImageUrl, supplierId];
}
