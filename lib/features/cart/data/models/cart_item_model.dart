import '../../domain/entities/cart_item_entity.dart';

class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.id,
    required super.userId,
    required super.productId,
    required super.quantity,
    super.productName,
    super.productPrice,
    super.productImageUrl,
    super.supplierId,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Handling join result if product details are included
    final product = json['products'] as Map<String, dynamic>?;

    return CartItemModel(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      productName: product?['name'],
      productPrice: product != null ? (product['price'] as num).toDouble() : null,
      productImageUrl: product?['image_url'],
      supplierId: product?['supplier_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    };
  }
}
