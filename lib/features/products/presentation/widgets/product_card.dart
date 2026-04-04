import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/product_entity.dart';
import '../views/product_details_view.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final bool isSupplier;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.isSupplier = false,
    this.onEdit,
    this.onDelete,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutOfStock = product.quantity <= 0;

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsView(product: product)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image (fixed height, no Expanded) ──
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-${product.id}',
                    child: _buildImage(),
                  ),
                  // Out of Stock overlay
                  if (isOutOfStock)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'out_of_stock'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Info Section ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name + Category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Store row
                    if (product.supplierName != null)
                      GestureDetector(
                        onTap: () => Get.toNamed('/store-detail',
                            arguments: {
                              'supplierId': product.supplierId,
                              'storeName': product.supplierName,
                              'storeAvatarUrl': product.supplierAvatarUrl,
                            }),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              backgroundImage: product.supplierAvatarUrl != null
                                  ? CachedNetworkImageProvider(product.supplierAvatarUrl!)
                                  : null,
                              child: product.supplierAvatarUrl == null
                                  ? const Icon(Icons.store, size: 10)
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.supplierName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Price + Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${product.price} \$',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isSupplier)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _iconBtn(Icons.edit_outlined, Colors.blue, onEdit),
                              _iconBtn(Icons.delete_outline, Colors.red, onDelete),
                            ],
                          )
                        else
                          _iconBtn(
                            isOutOfStock
                                ? Icons.block
                                : Icons.add_shopping_cart,
                            isOutOfStock ? Colors.grey : theme.colorScheme.primary,
                            isOutOfStock ? null : onAddToCart,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: product.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (ctx, url, err) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
          ],
        ),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback? onTap) => IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(4),
        visualDensity: VisualDensity.compact,
      );
}
