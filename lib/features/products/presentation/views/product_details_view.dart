import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../features/ratings/presentation/widgets/star_rating_widget.dart';

class ProductDetailsView extends StatelessWidget {
  final ProductEntity product;

  const ProductDetailsView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final isOutOfStock = product.quantity <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Get.toNamed('/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Image ──
            AspectRatio(
              aspectRatio: 1.2,
              child: Hero(
                tag: 'product-${product.id}',
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (ctx, url, e) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 80, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + Price ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.category,
                                style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${product.price} \$',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary),
                          ),
                          if (isOutOfStock)
                            Text('out_of_stock'.tr,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Store Info Banner ──
                  if (product.supplierName != null)
                    GestureDetector(
                      onTap: () => Get.toNamed('/store-detail', arguments: {
                        'supplierId': product.supplierId,
                        'storeName': product.supplierName,
                        'storeAvatarUrl': product.supplierAvatarUrl,
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                              backgroundImage: product.supplierAvatarUrl != null
                                  ? CachedNetworkImageProvider(product.supplierAvatarUrl!)
                                  : null,
                              child: product.supplierAvatarUrl == null
                                  ? const Icon(Icons.store, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.supplierName!,
                                      style: theme.textTheme.titleMedium),
                                  Text('visit_store'.tr,
                                      style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Info Tiles ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInfoTile(Icons.straighten, 'unit_label'.tr, product.unit, theme),
                        const SizedBox(width: 12),
                        _buildInfoTile(Icons.inventory_2_outlined, 'qty_label'.tr,
                            '${product.quantity}', theme),
                        if (product.createdAt != null) ...[
                          const SizedBox(width: 12),
                          _buildInfoTile(Icons.calendar_today_outlined, 'date_label'.tr,
                              DateFormat('yyyy/MM/dd').format(product.createdAt!), theme),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Description ──
                  Text('description'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text(
                    product.description ?? 'no_description'.tr,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),

                  const SizedBox(height: 28),

                  // ── Star Rating ──
                  StarRatingWidget(productId: product.id),

                  const SizedBox(height: 36),

                  // ── Add to Cart ──
                  Obx(() {
                    final isCustomer =
                        authController.currentUser.value?.role != 'supplier' ||
                            authController.isViewAsCustomer.value;
                    if (!isCustomer) return const SizedBox.shrink();
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          if (!cartController.isLoading.value && !isOutOfStock)
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: (cartController.isLoading.value || isOutOfStock)
                            ? null
                            : () => cartController.addItem(product.id),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(65),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: cartController.isLoading.value
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isOutOfStock
                                        ? Icons.block
                                        : Icons.add_shopping_cart,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isOutOfStock
                                        ? 'out_of_stock'.tr
                                        : 'add_to_cart'.tr,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
