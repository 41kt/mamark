import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mamark/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mamark/features/orders/presentation/controllers/order_controller.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المشتريات'),
      ),
      body: Obx(() {
        if (cartController.cartItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('سلتك فارغة حالياً', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Checkbox(
                    value: cartController.isAllSelected,
                    onChanged: (value) {
                      if (value == true) {
                        cartController.selectAll();
                      } else {
                        cartController.deselectAll();
                      }
                    },
                  ),
                  const Text('تحديد الكل', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cartController.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartController.cartItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: cartController.isSelected(item.id),
                            onChanged: (_) => cartController.toggleSelection(item.id),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.productImageUrl != null
                                ? Image.network(item.productImageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                                : Container(
                                    width: 60, 
                                    height: 60, 
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName ?? 'منتج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('${item.productPrice} \$', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w500)),
                                Text('الكمية: ${item.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => cartController.removeItem(item.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Get.isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي للمحدد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      Text('${cartController.totalPrice.toStringAsFixed(2)} \$', 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: cartController.selectedItemIds.isEmpty 
                      ? null 
                      : () {
                        // Import of OrderController needed or use Get.find
                        final orderController = Get.find<OrderController>();
                        orderController.checkout();
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      disabledBackgroundColor: Colors.grey,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text('إتمام الطلب المختار', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
