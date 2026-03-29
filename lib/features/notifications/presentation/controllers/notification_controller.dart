import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'dart:async';

class NotificationController extends GetxController {
  final SupabaseClient supabase = Get.find<SupabaseClient>();
  final authController = Get.find<AuthController>();
  
  var newOrdersCount = 0.obs;
  StreamSubscription? _orderSubscription;

  @override
  void onInit() {
    super.onInit();
    // Re-listen whenever user changes (login/logout)
    ever(authController.currentUser, (user) {
      if (user != null && user.role == 'supplier') {
        _startListening(user.id);
      } else {
        _orderSubscription?.cancel();
        newOrdersCount.value = 0;
      }
    });
    
    // Initial check
    final user = authController.currentUser.value;
    if (user != null && user.role == 'supplier') {
      _startListening(user.id);
    }
  }

  void _startListening(String supplierId) {
    _orderSubscription?.cancel();
    // Use the stream and filter in the listen callback for maximum compatibility
    _orderSubscription = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final pendingOrders = data.where((o) => o['supplier_id'] == supplierId && o['status'] == 'pending').toList();
          
          if (pendingOrders.length > newOrdersCount.value) {
            Get.snackbar('طلبات جديدة', 'لديك ${pendingOrders.length} طلبات جديدة بانتظار الموافقة',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.blue[900]?.withValues(alpha: 0.9),
              colorText: Colors.white,
              duration: const Duration(seconds: 4));
          }
          newOrdersCount.value = pendingOrders.length;
        });
  }

  void resetCount() {
    newOrdersCount.value = 0;
  }

  @override
  void onClose() {
    _orderSubscription?.cancel();
    super.onClose();
  }
}
