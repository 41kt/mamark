class InventoryEntity {
  final String id;
  final String productId;
  final String storeId;
  final int quantityAvailable;
  final int quantitySold;

  InventoryEntity({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.quantityAvailable,
    required this.quantitySold,
  });
}
