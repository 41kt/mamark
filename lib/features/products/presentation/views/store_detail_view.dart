import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../widgets/product_card.dart';

class StoreDetailView extends StatelessWidget {
  const StoreDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final String supplierId = Get.arguments as String;
    final productController = Get.find<ProductController>();
    
    final storeProducts = productController.products.where((p) => p.supplierId == supplierId).toList();
    final supplierName = storeProducts.isNotEmpty ? storeProducts.first.supplierName : 'all_store_products'.tr;
    final supplierAvatar = storeProducts.isNotEmpty ? storeProducts.first.supplierAvatarUrl : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(supplierName ?? 'store_profile'.tr),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Store Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: supplierAvatar != null ? NetworkImage(supplierAvatar) : null,
                  child: supplierAvatar == null ? Icon(Icons.storefront, size: 35, color: theme.colorScheme.primary) : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplierName ?? 'store_profile'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${storeProducts.length} ${'products'.tr}',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
          
          // Store Products Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.68,
              ),
              itemCount: storeProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: storeProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

