class ProductEntity {
  final String id;
  final String supplierId;
  final String name;
  final String category;
  final String unit;
  final int quantity;
  final double price;
  final String? description;
  final String? imageUrl;
  final String? supplierName;
  final String? supplierAvatarUrl;
  final DateTime? createdAt;

  ProductEntity({
    required this.id,
    required this.supplierId,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.price,
    this.description,
    this.imageUrl,
    this.supplierName,
    this.supplierAvatarUrl,
    this.createdAt,
  });
}
