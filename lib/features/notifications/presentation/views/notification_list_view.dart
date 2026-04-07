import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mamark/features/orders/presentation/controllers/order_controller.dart';
import 'package:mamark/features/auth/presentation/controllers/auth_controller.dart';
import 'package:intl/intl.dart';

class NotificationListView extends StatelessWidget {
  const NotificationListView({super.key});

  @override
  Widget build(BuildContext context) {
    // We will just use the orders already fetched by OrderController to show real details.
    // If it's not registered (user came directly), we find it:
    final orderController = Get.put(OrderController(
      createOrderUseCase: Get.find(),
      getOrdersUseCase: Get.find(),
      updateOrderStatusUseCase: Get.find(),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (orderController.isLoading.value && orderController.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final authController = Get.find<AuthController>();
        final user = authController.currentUser.value;
        final isSupplier = user?.role == 'supplier' && !authController.isViewAsCustomer.value;

        // For suppliers: pending orders
        // For customers: accepted or delivered
        final displayOrders = isSupplier
             ? orderController.orders.where((o) => o.status == 'pending').toList()
             : orderController.orders.where((o) => o.status == 'accepted' || o.status == 'delivered').toList();

        if (displayOrders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد إشعارات جديدة حالياً', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayOrders.length,
          itemBuilder: (context, index) {
            final order = displayOrders[index];
            final customerName = order.customerName ?? 'مستخدم';
            final avatarUrl = order.customerAvatarUrl;
            
            final String titleText = isSupplier
               ? 'طلب جديد من: $customerName'
               : 'تحديث لطلبك #${order.id.substring(0, 8)}';
               
            final String subtitleText = isSupplier
               ? 'لقد أرسل لك الطلب #${order.id.substring(0, 8)}. اضغط للمراجعة التفصيلية.'
               : (order.status == 'accepted' ? 'تمت الموافقة على طلبك بنجاح! اضغط للاتفاق بالدردشة.' : 'طلبك الآن جاهز/قيد التوصيل!');
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50], // fallback
                  backgroundImage: (isSupplier && avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty || !isSupplier) ? Icon(isSupplier ? Icons.person : Icons.local_shipping, color: Colors.blue[800]) : null,
                ),
                title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitleText, style: TextStyle(color: Colors.grey[700])),
                trailing: Text(
                  DateFormat('HH:mm').format(order.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Get.toNamed('/orders');
                },
              ),
            );
          },
        );
      }),
    );
  }
}
