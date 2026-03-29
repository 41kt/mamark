import 'package:get/get.dart';
import 'package:mamark/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mamark/features/cart/domain/usecases/cart_usecases.dart';
import 'package:mamark/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class CartController extends GetxController {
  final GetCartUseCase getCartUseCase;
  final AddToCartUseCase addToCartUseCase;
  final RemoveFromCartUseCase removeFromCartUseCase;
  final ClearCartUseCase clearCartUseCase;

  CartController({
    required this.getCartUseCase,
    required this.addToCartUseCase,
    required this.removeFromCartUseCase,
    required this.clearCartUseCase,
  });

  var cartItems = <CartItemEntity>[].obs;
  var selectedItemIds = <String>{}.obs;
  var isLoading = false.obs;

  double get totalPrice {
    return cartItems
        .where((item) => selectedItemIds.contains(item.id))
        .fold(0, (sum, item) => sum + ((item.productPrice ?? 0) * item.quantity));
  }

  void toggleSelection(String itemId) {
    if (selectedItemIds.contains(itemId)) {
      selectedItemIds.remove(itemId);
    } else {
      selectedItemIds.add(itemId);
    }
  }

  void selectAll() {
    selectedItemIds.assignAll(cartItems.map((item) => item.id));
  }

  void deselectAll() {
    selectedItemIds.clear();
  }

  bool isSelected(String itemId) => selectedItemIds.contains(itemId);
  bool get isAllSelected => cartItems.isNotEmpty && selectedItemIds.length == cartItems.length;

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthController>();
    if (authController.currentUser.value != null) {
      fetchCart(authController.currentUser.value!.id);
    }
  }

  Future<void> fetchCart(String userId) async {
    isLoading.value = true;
    final result = await getCartUseCase(userId);
    result.fold(
      (failure) => Get.snackbar('خطأ', 'فشل في تحميل السلة'),
      (items) {
        cartItems.assignAll(items);
        // Default select all on first load if nothing selected
        if (selectedItemIds.isEmpty) selectAll();
      },
    );
    isLoading.value = false;
  }

  Future<void> addItem(String productId, {int quantity = 1}) async {
    final authController = Get.find<AuthController>();
    if (authController.currentUser.value == null) {
      Get.snackbar('تنبيه', 'يرجى تسجيل الدخول أولاً لإضافة منتجات إلى السلة');
      return;
    }

    isLoading.value = true;
    final newItem = CartItemEntity(
      id: '', 
      userId: authController.currentUser.value!.id,
      productId: productId,
      quantity: quantity,
    );

    final result = await addToCartUseCase(newItem);
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message, backgroundColor: Colors.red[200]),
      (_) {
        fetchCart(authController.currentUser.value!.id);
        Get.snackbar('نجاح', 'تمت الإضافة إلى السلة بنجاح', backgroundColor: Colors.green[200]);
      },
    );
    isLoading.value = false;
  }

  Future<void> removeItem(String itemId) async {
    final result = await removeFromCartUseCase(itemId);
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message),
      (_) {
        cartItems.removeWhere((item) => item.id == itemId);
      },
    );
  }

  Future<void> clear(String userId) async {
    final result = await clearCartUseCase(userId);
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message),
      (_) => cartItems.clear(),
    );
  }
}
