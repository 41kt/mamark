import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.supplierId,
    required super.name,
    required super.category,
    required super.unit,
    required super.quantity,
    required super.price,
    super.description,
    super.imageUrl,
    super.supplierName,
    super.supplierAvatarUrl,
    super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      supplierId: json['supplier_id'],
      name: json['name'],
      category: json['category'],
      unit: json['unit'] ?? 'قطعة',
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      imageUrl: json['image_url'],
      supplierName: json['users'] != null ? (json['users']['store_name'] ?? json['users']['name']) : null,
      supplierAvatarUrl: json['users'] != null ? json['users']['avatar_url'] : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id, // Supabase generates id if not provided
      'supplier_id': supplierId,
      'name': name,
      'category': category,
      'unit': unit,
      'quantity': quantity,
      'price': price,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
