import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';

class StoreDetailView extends StatelessWidget {
  const StoreDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final String supplierId = Get.arguments as String;
    final productController = Get.find<ProductController>();
    
    // Simplified: we filter products by supplierId
    final storeProducts = productController.products.where((p) => p.supplierId == supplierId).toList();
    final supplierName = storeProducts.isNotEmpty ? storeProducts.first.supplierName : 'Store';
    final supplierAvatar = storeProducts.isNotEmpty ? storeProducts.first.supplierAvatarUrl : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(supplierName ?? 'Store'),
      ),
      body: Column(
        children: [
          // Store Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: supplierAvatar != null ? NetworkImage(supplierAvatar) : null,
                  child: supplierAvatar == null ? const Icon(Icons.store, size: 40) : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplierName ?? 'Store Name',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text('Welcome to our store! We provide the best materials.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Store Products Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: storeProducts.length,
              itemBuilder: (context, index) {
                final product = storeProducts[index];
                return InkWell(
                  onTap: () {
                    // Navigate to product detail
                  },
                  child: product.imageUrl != null 
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                    : Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
