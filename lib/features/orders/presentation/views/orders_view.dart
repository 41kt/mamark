import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mamark/features/orders/presentation/controllers/order_controller.dart';
import 'package:mamark/features/auth/presentation/controllers/auth_controller.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final orderController = Get.find<OrderController>();
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    final isSupplier = user?.role == 'supplier';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isSupplier ? 'طلبات المتجر الواردة' : 'قائمة طلباتي', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderController.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('لا توجد طلبات لعرضها حالياً', style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: orderController.orders.length,
          itemBuilder: (context, index) {
            final order = orderController.orders[index];
            final statusColor = _getStatusColor(order.status);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_basket_outlined, color: statusColor, size: 24),
                ),
                title: Row(
                  children: [
                    Text('طلب #${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (isSupplier && order.customerName != null)
                      Expanded(
                        child: Text(
                          ' - من: ${order.customerName}', 
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _translateStatus(order.status),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${order.totalAmount} \$', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue[900])),
                  ],
                ),
                children: [
                  const Divider(indent: 16, endIndent: 16),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item['image_url'] != null 
                         ? Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                         : Container(width: 50, height: 50, color: Colors.grey[100], child: const Icon(Icons.image)),
                      ),
                      title: Text(item['product_name'] ?? 'منتج', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('الكمية: ${item['quantity']} × ${item['price']} \$', style: const TextStyle(fontSize: 13)),
                      trailing: Text('${(item['quantity'] ?? 1) * (item['price'] ?? 0)} \$', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )),
                  if (isSupplier && order.status == 'pending')
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => orderController.updateStatus(order.id, 'accepted'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text('accept_order'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => orderController.updateStatus(order.id, 'rejected'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text('reject_order'.tr, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Chat button for accepted orders
                  if (order.status == 'accepted')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          if (isSupplier)
                            ElevatedButton.icon(
                              onPressed: () => orderController.updateStatus(order.id, 'delivered'),
                              icon: const Icon(Icons.local_shipping_outlined, color: Colors.white),
                              label: Text('confirm_delivery'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => Get.toNamed('/chat', arguments: {
                              'orderId': order.id,
                              'isSupplier': isSupplier,
                            }),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text('open_chat'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),

                ],
              ),
            );
          },
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      case 'delivered': return Colors.blue;
      case 'cancelled': return Colors.grey;
      default: return Colors.black;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'accepted': return 'مقبول';
      case 'rejected': return 'مرفوض';
      case 'delivered': return 'تم التوصيل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}
