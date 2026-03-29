import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../widgets/product_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final cartController = Get.find<CartController>();
    final authController = Get.find<AuthController>();
    final notificationController = Get.find<NotificationController>();

    final allCategories = ['الكل', ...productController.categories];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Premium SliverAppBar
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.blue[900],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('مامارك للمواد', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
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
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () => Get.toNamed('/notifications'),
                  ),
                  Obx(() => notificationController.newOrdersCount.value > 0
                      ? Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              '${notificationController.newOrdersCount.value}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
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
                    Get.toNamed('/profile');
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

          // Sticky Category Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 70,
              maxHeight: 70,
              child: Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Obx(() => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allCategories.length,
                  itemBuilder: (context, index) {
                    final category = allCategories[index];
                    final isSelected = productController.selectedCategory.value == category;
                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) productController.filterByCategory(category);
                        },
                        selectedColor: Colors.blue[800],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: isSelected ? 4 : 0,
                        pressElevation: 8,
                      ),
                    );
                  },
                )),
              ),
            ),
          ),

          // Product Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Obx(() {
              if (productController.isLoading.value) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              final user = authController.currentUser.value;
              final productsToShow = (user?.role == 'supplier' && !authController.isViewAsCustomer.value)
                  ? productController.myProducts
                  : productController.products;

              if (productsToShow.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('لا توجد منتجات لعرضها حالياً')),
                );
              }

              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = productsToShow[index];
                    return ProductCard(
                      product: product,
                      isSupplier: user?.role == 'supplier' && !authController.isViewAsCustomer.value,
                      onEdit: (user?.role == 'supplier' && !authController.isViewAsCustomer.value) 
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
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/cart'),
        backgroundColor: Colors.blue[900],
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            Obx(() => cartController.cartItems.isNotEmpty
                ? Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cartController.cartItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
