import '../../domain/entities/inventory_entity.dart';

class InventoryModel extends InventoryEntity {
  InventoryModel({
    required super.id,
    required super.productId,
    required super.storeId,
    required super.quantityAvailable,
    required super.quantitySold,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'],
      productId: json['product_id'],
      storeId: json['store_id'],
      quantityAvailable: json['quantity_available'],
      quantitySold: json['quantity_sold'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'product_id': productId,
      'store_id': storeId,
      'quantity_available': quantityAvailable,
      'quantity_sold': quantitySold,
    };
  }
}
