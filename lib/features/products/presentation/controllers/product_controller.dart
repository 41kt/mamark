import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/manage_product_usecases.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ProductController extends GetxController {
  final GetProductsUseCase getProductsUseCase;
  final AddProductUseCase addProductUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final DeleteProductUseCase deleteProductUseCase;
  final StreamProductsUseCase streamProductsUseCase;
  
  ProductController({
    required this.getProductsUseCase,
    required this.addProductUseCase,
    required this.updateProductUseCase,
    required this.deleteProductUseCase,
    required this.streamProductsUseCase,
  });

  var products = <ProductEntity>[].obs;
  var myProducts = <ProductEntity>[].obs; // Specific for the logged-in supplier
  var isLoading = false.obs;
  var selectedCategory = 'الكل'.obs;
  var pickedImage = Rx<File?>(null);
  
  final categories = ['أسمنت', 'حديد تسليح', 'طوب وبلك', 'رمال وخرسانة', 'أدوات بناء', 'دهانات', 'سباكة', 'كهرباء', 'أخرى'];
  
  final _picker = ImagePicker();
  StreamSubscription? _productsSubscription;

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      pickedImage.value = File(image.path);
    }
  }

  void clearPickedImage() {
    pickedImage.value = null;
  }

  Future<String?> uploadImage(File image) async {
    try {
      isLoading.value = true;
      final supabase = Get.find<SupabaseClient>();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'product_images/$fileName'; // Using a more specific folder
      
      await supabase.storage.from('products').upload(path, image);
      final publicUrl = supabase.storage.from('products').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      Get.snackbar('خطأ في الرفع', 'تعذر رفع الصورة: $e\nتأكد من وجود سلة (bucket) باسم products في Supabase ووجود صلاحيات الرفع.');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    listenToProducts();
  }

  void listenToProducts() {
    _productsSubscription?.cancel();
    _productsSubscription = streamProductsUseCase(
      category: (selectedCategory.value.isEmpty || selectedCategory.value == 'الكل') ? null : selectedCategory.value
    ).listen((event) {
      event.fold(
        (failure) => Get.snackbar('خطأ', failure.message),
        (productList) {
          products.assignAll(productList);
          _updateMyProducts();
        },
      );
    });
  }

  void _updateMyProducts() {
    try {
      final authCtrl = Get.find<AuthController>();
      final user = authCtrl.currentUser.value;
      if (user != null) {
        myProducts.assignAll(products.where((p) => p.supplierId == user.id));
      }
    } catch (_) {}
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    listenToProducts();
  }

  Future<void> addProduct(ProductEntity product) async {
    isLoading.value = true;
    
    String? imageUrl = product.imageUrl;
    if (pickedImage.value != null) {
      imageUrl = await uploadImage(pickedImage.value!);
    }

    // Create a new product entity with the uploaded image URL
    final finalProduct = ProductEntity(
      id: product.id,
      supplierId: product.supplierId,
      name: product.name,
      category: product.category,
      unit: product.unit,
      quantity: product.quantity,
      price: product.price,
      description: product.description,
      imageUrl: imageUrl,
    );

    final result = await addProductUseCase(finalProduct);
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message),
      (success) {
        pickedImage.value = null; // Reset image after success
        Get.back();
        Get.snackbar('نجاح', 'تم إضافة المنتج بنجاح');
      },
    );
    isLoading.value = false;
  }

  Future<void> updateProduct(ProductEntity product) async {
    isLoading.value = true;
    
    String? imageUrl = product.imageUrl;
    if (pickedImage.value != null) {
      imageUrl = await uploadImage(pickedImage.value!);
    }

    final finalProduct = ProductEntity(
      id: product.id,
      supplierId: product.supplierId,
      name: product.name,
      category: product.category,
      unit: product.unit,
      quantity: product.quantity,
      price: product.price,
      description: product.description,
      imageUrl: imageUrl,
    );

    final result = await updateProductUseCase(finalProduct);
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message),
      (success) {
        pickedImage.value = null; // Reset image
        Get.back();
        Get.snackbar('نجاح', 'تم تحديث المنتج بنجاح');
      },
    );
    isLoading.value = false;
  }

  Future<void> deleteProduct(String id) async {
    final result = await deleteProductUseCase(id);
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message),
      (success) {
        Get.snackbar('نجاح', 'تم حذف المنتج بنجاح');
      },
    );
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    super.onClose();
  }
  
  bool get isSupplier {
    try {
      final authCtrl = Get.find<AuthController>();
      return authCtrl.currentUser.value?.role == 'supplier';
    } catch (_) {
      return false;
    }
  }
}
