import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/presentation/controllers/order_controller.dart';
import '../widgets/product_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final cartController = Get.find<CartController>();
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar ──
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'معمارك للمواد',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[900]!, Colors.blue[700]!],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
              // Notification badge — only the count itself is reactive
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () => Get.toNamed('/notifications'),
                  ),
                  Obx(() {
                    final orderController = Get.find<OrderController>();
                    final user = authController.currentUser.value;
                    final isSupplierMode = user?.role == 'supplier' && !authController.isViewAsCustomer.value;
                    final count = isSupplierMode
                       ? orderController.orders.where((o) => o.status == 'pending').length
                       : orderController.orders.where((o) => o.status == 'accepted' || o.status == 'delivered').length;

                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {
                  final user = authController.currentUser.value;
                  if (user == null) {
                    Get.toNamed('/login');
                  } else if (user.role == 'supplier') {
                    Get.toNamed('/supplier-profile');
                  } else {
                    Get.toNamed('/edit-profile');
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Get.toNamed('/settings'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Sticky Category Bar ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryBarDelegate(
              child: Obx(() {
                // Reading selectedCategory.value makes this Obx reactive
                final selected = productController.selectedCategory.value;
                final categories = ['الكل', ...productController.categories];
                return Container(
                  color: theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selected == cat;
                      return Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (ok) {
                            if (ok) productController.filterByCategory(cat);
                          },
                          selectedColor: Colors.blue[800],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: isSelected ? 4 : 0,
                          pressElevation: 8,
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),

          // ── Product Grid ──
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Obx(() {
              if (productController.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final user = authController.currentUser.value;
              final isSupplierMode =
                  user?.role == 'supplier' && !authController.isViewAsCustomer.value;
              final productsToShow =
                  isSupplierMode ? productController.myProducts : productController.products;

              if (productsToShow.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('no_products'.tr,
                            style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = productsToShow[index];
                    return ProductCard(
                      product: product,
                      isSupplier: isSupplierMode,
                      onEdit: isSupplierMode
                          ? () => Get.toNamed('/add-product', arguments: product)
                          : null,
                      onAddToCart: () => cartController.addItem(product.id),
                    );
                  },
                  childCount: productsToShow.length,
                ),
              );
            }),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── Cart FAB ──
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/cart'),
        backgroundColor: Colors.blue[900],
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            Obx(() {
              final count = cartController.cartItems.length;
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Sliver Header Delegate ──
class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _CategoryBarDelegate({required this.child});

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_CategoryBarDelegate old) => child != old.child;
}
