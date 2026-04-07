import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../features/products/presentation/widgets/product_card.dart';
import '../../../../features/products/presentation/controllers/product_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SupplierProfileView extends StatelessWidget {
  const SupplierProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final productController = Get.find<ProductController>();
    final user = authController.currentUser.value;
    
    // Removed local static filtering

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('لوحة تحكم المتجر', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: () => Get.toNamed('/edit-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Get.toNamed('/orders'),
          ),
          IconButton(
            icon: Obx(() => Icon(
              authController.isViewAsCustomer.value ? Icons.storefront : Icons.remove_red_eye_outlined,
              color: authController.isViewAsCustomer.value ? Colors.green : null,
            )),
            onPressed: () {
              authController.toggleStoreMode();
              if (authController.isViewAsCustomer.value) {
                Get.offAllNamed('/home');
              }
            },
            tooltip: 'معاينة كمتسوق',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.blue[50],
                        backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                        child: user?.avatarUrl == null ? Icon(Icons.store, size: 50, color: Colors.blue[800]) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.storeName ?? user?.name ?? 'اسم المتجر',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatTile('المنتجات', productController.myProducts.length.toString(), Icons.inventory_2_outlined),
                      _buildStatTile('المبيعات', '0', Icons.trending_up),
                      _buildStatTile('التقييم', '5.0', Icons.star_outline),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Text('إدارة منتجاتي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          
          // My Products List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: Obx(() => SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = productController.myProducts[index];
                    return ProductCard(
                      product: product,
                      isSupplier: true,
                      onEdit: () => Get.toNamed('/add-product', arguments: product),
                      onDelete: () => _showDeleteDialog(context, productController, product.id),
                    );
                  },
                  childCount: productController.myProducts.length,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/add-product'),
        backgroundColor: Colors.blue[800],
        elevation: 4,
        label: const Text('إضافة منتج جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  Widget _buildStatTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[800], size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, ProductController controller, String productId) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا المنتج؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              controller.deleteProduct(productId);
              Get.back();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
