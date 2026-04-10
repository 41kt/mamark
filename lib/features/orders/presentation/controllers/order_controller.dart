import 'package:get/get.dart';
import 'package:mamark/features/orders/domain/entities/order_entity.dart';
import 'package:mamark/features/orders/domain/usecases/order_usecases.dart';
import 'package:mamark/features/orders/domain/repositories/order_repository.dart';
import 'package:mamark/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mamark/features/cart/presentation/controllers/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderController extends GetxController {
  final CreateOrderUseCase createOrderUseCase;
  final GetOrdersUseCase getOrdersUseCase;
  final UpdateOrderStatusUseCase updateOrderStatusUseCase;

  OrderController({
    required this.createOrderUseCase,
    required this.getOrdersUseCase,
    required this.updateOrderStatusUseCase,
  });

  var orders = <OrderEntity>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthController>();
    ever(authController.currentUser, (user) {
      if (user != null) {
        refreshOrders();
        if (user.role == 'supplier') {
          _listenToOrders(user.id);
        }
      }
    });
    
    // Initial check in case it's already there
    final user = authController.currentUser.value;
    if (user != null) {
      refreshOrders();
      if (user.role == 'supplier') {
        _listenToOrders(user.id);
      }
    }
  }

  void refreshOrders() {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    if (user != null) {
      fetchOrders(user.id, isSupplier: user.role == 'supplier');
    }
  }

  Future<void> fetchOrders(String userId, {bool isSupplier = false}) async {
    isLoading.value = true;
    final result = await getOrdersUseCase(GetOrdersParams(userId: userId, isSupplier: isSupplier));
    result.fold(
      (failure) {
        Get.snackbar('خطأ تقني', 'الخطأ: \${failure.message}', duration: const Duration(seconds: 10));
      },
      (items) {
        orders.assignAll(items);
      },
    );
    isLoading.value = false;
  }

  Future<void> checkout() async {
    final authController = Get.find<AuthController>();
    final cartController = Get.find<CartController>();
    final user = authController.currentUser.value;

    if (user == null || cartController.cartItems.isEmpty) return;

    isLoading.value = true;
    
    try {
      final selectedItems = cartController.cartItems
          .where((item) => cartController.selectedItemIds.contains(item.id))
          .toList();

      if (selectedItems.isEmpty) {
        Get.snackbar('تنبيه', 'يرجى تحديد منتجات لإتمام الطلب');
        return;
      }

      final Map<String, List<Map<String, dynamic>>> supplierGroups = {};
      final Map<String, double> supplierTotals = {};

      for (var item in selectedItems) {
        final sId = item.supplierId ?? 'unknown'; 
        
        supplierGroups.putIfAbsent(sId, () => []);
        supplierGroups[sId]!.add({
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'price': item.productPrice,
          'image_url': item.productImageUrl,
        });
        
        supplierTotals[sId] = (supplierTotals[sId] ?? 0) + ((item.productPrice ?? 0) * item.quantity);
      }

      for (var sId in supplierGroups.keys) {
        final newOrder = OrderEntity(
          id: '',
          userId: user.id,
          supplierId: sId,
          items: supplierGroups[sId]!,
          totalAmount: supplierTotals[sId]!,
          status: 'pending',
          createdAt: DateTime.now(),
        );

        final result = await createOrderUseCase(newOrder);
        result.fold(
          (failure) => Get.snackbar('خطأ', failure.message, backgroundColor: Colors.red[200]),
          (_) async {
            // ── تخفيض المخزون تلقائياً بعد نجاح الطلب ──
            try {
              final supabase = Get.find<SupabaseClient>();
              for (final item in supplierGroups[sId]!) {
                final productId = item['product_id'];
                final orderedQty = (item['quantity'] as int? ?? 1);
                // Get current inventory row for this product
                final invResult = await supabase
                    .from('inventory')
                    .select('id, quantity_available, quantity_sold')
                    .eq('product_id', productId)
                    .maybeSingle();
                if (invResult != null) {
                  final currentAvail = (invResult['quantity_available'] as int? ?? 0);
                  final currentSold = (invResult['quantity_sold'] as int? ?? 0);
                  await supabase.from('inventory').update({
                    'quantity_available': (currentAvail - orderedQty).clamp(0, 999999),
                    'quantity_sold': currentSold + orderedQty,
                  }).eq('id', invResult['id']);
                }
              }
            } catch (_) {
              // Non-critical: inventory update failed silently
            }
            await cartController.clear(user.id);
            Get.snackbar('نجاح', 'تم إرسال الطلب بنجاح', backgroundColor: Colors.green[200]);
            refreshOrders();
          },
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إتمام الطلب: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    final result = await updateOrderStatusUseCase(UpdateStatusParams(orderId: orderId, status: newStatus));
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message),
      (_) {
        final index = orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          // This will trigger Obx if we replace the item or just refresh
          refreshOrders();
        }
        Get.snackbar('نجاح', 'تم تحديث حالة الطلب');
      },
    );
  }

  void _listenToOrders(String supplierId) {
    // Note: Use the repository's stream to trigger notifications
    final OrderRepository repository = Get.find<OrderRepository>();
    repository.streamOrders(supplierId).listen((newOrders) {
      if (orders.isNotEmpty && newOrders.length > orders.length) {
        // Find new orders
        final existingIds = orders.map((o) => o.id).toSet();
        final newlyAdded = newOrders.where((o) => !existingIds.contains(o.id)).toList();
        
        for (var order in newlyAdded) {
          final roleStr = order.customerRole == 'contractor' ? 'مقاول' : 'عميل';
          Get.snackbar(
            'طلب جديد من $roleStr!',
            'وصلك طلب جديد برقم ${order.id.substring(0, 8)} من ${order.customerName ?? "مستخدم"}',
            backgroundColor: Colors.blue[100],
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () => Get.toNamed('/orders'),
              child: const Text('عرض'),
            ),
          );
        }
      }
      orders.assignAll(newOrders);
    });
  }
}
