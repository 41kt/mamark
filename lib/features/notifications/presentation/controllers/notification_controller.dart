import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'dart:async';

class NotificationController extends GetxController {
  final SupabaseClient supabase = Get.find<SupabaseClient>();
  final authController = Get.find<AuthController>();

  var newOrdersCount = 0.obs;
  var newBidsCount = 0.obs;
  StreamSubscription? _orderSubscription;
  StreamSubscription? _bidSubscription;

  @override
  void onInit() {
    super.onInit();
    // Re-listen whenever user changes (login/logout)
    ever(authController.currentUser, (user) {
      _orderSubscription?.cancel();
      _bidSubscription?.cancel();
      newOrdersCount.value = 0;
      newBidsCount.value = 0;

      if (user != null) {
        if (user.role == 'supplier') {
          _listenToOrders(user.id);
        } else if (user.role == 'customer') {
          _listenToBids(user.id);
        } else if (user.role == 'contractor') {
          _listenToContractorBids(user.id);
        }
      }
    });

    // Initial check
    final user = authController.currentUser.value;
    if (user != null) {
      if (user.role == 'supplier') {
        _listenToOrders(user.id);
      } else if (user.role == 'customer') {
        _listenToBids(user.id);
      } else if (user.role == 'contractor') {
        _listenToContractorBids(user.id);
      }
    }
  }

  /// Supplier: listens for new pending orders
  void _listenToOrders(String supplierId) {
    _orderSubscription?.cancel();
    _orderSubscription = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final pendingOrders = data
              .where((o) => o['supplier_id'] == supplierId && o['status'] == 'pending')
              .toList();

          if (pendingOrders.length > newOrdersCount.value) {
            _showSnackbar(
              'طلبات جديدة',
              'لديك ${pendingOrders.length} طلبات جديدة بانتظار الموافقة',
              role: '[مورد]',
            );
          }
          newOrdersCount.value = pendingOrders.length;
        });
  }

  /// Customer: listens for bid status changes on their projects
  void _listenToBids(String customerId) {
    _bidSubscription?.cancel();
    _bidSubscription = supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .listen((data) {
          // Count accepted bids on this customer's projects
          // (We'll track via notifications table for simplicity)
        });
  }

  /// Contractor: listens for bid acceptance/rejection
  void _listenToContractorBids(String contractorUserId) async {
    // Get contractor row id
    final contractor = await supabase
        .from('contractors')
        .select('id')
        .eq('user_id', contractorUserId)
        .maybeSingle();

    if (contractor == null) return;
    final contractorId = contractor['id'];

    _bidSubscription?.cancel();
    _bidSubscription = supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('contractor_id', contractorId)
        .listen((data) {
          final acceptedNew = data.where((b) => b['status'] == 'accepted').length;
          if (acceptedNew > newBidsCount.value) {
            _showSnackbar(
              'تم قبول عرضك!',
              'لقد قبل أحد العملاء عرضك على مشروع',
              role: '[مقاول]',
            );
          }
          newBidsCount.value = acceptedNew;
        });
  }

  void _showSnackbar(String title, String message, {String role = ''}) {
    Get.snackbar(
      '$role $title',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String? type,
  }) async {
    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      String roleLabel = '';
      if (user.role == 'supplier') roleLabel = '[مورد]';
      if (user.role == 'contractor') roleLabel = '[مقاول]';
      if (user.role == 'customer') roleLabel = '[عميل]';

      await supabase.from('notifications').insert({
        'user_id': user.id,
        'title': '$roleLabel $title',
        'content': body,
        'type': type ?? 'general',
      });

      _showSnackbar(title, body, role: roleLabel);
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  void resetCount() {
    newOrdersCount.value = 0;
    newBidsCount.value = 0;
  }

  /// Total notification count (for badge)
  int get totalCount => newOrdersCount.value + newBidsCount.value;

  @override
  void onClose() {
    _orderSubscription?.cancel();
    _bidSubscription?.cancel();
    super.onClose();
  }
}
