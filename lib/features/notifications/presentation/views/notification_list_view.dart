import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import 'package:intl/intl.dart';

class NotificationListView extends StatelessWidget {
  const NotificationListView({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => notificationController.resetCount(),
            child: const Text('تحديد الكل كمقروء', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Obx(() {
        if (notificationController.newOrdersCount.value == 0) {
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
          itemCount: notificationController.newOrdersCount.value,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.shopping_bag_outlined, color: Colors.blue[800]),
                ),
                title: const Text('طلب جديد وصل!', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('لديك طلب جديد ينتظر المراجعة. اضغط للتفاصيل.', style: TextStyle(color: Colors.grey[700])),
                trailing: Text(
                  DateFormat('HH:mm').format(DateTime.now()),
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
