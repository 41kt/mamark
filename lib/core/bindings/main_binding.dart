import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/update_password_usecase.dart';
import '../../features/auth/domain/usecases/is_email_available_usecase.dart';
import '../../features/auth/domain/usecases/is_username_available_usecase.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

// Products
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_products_usecase.dart';
import '../../features/products/domain/usecases/manage_product_usecases.dart';
import '../../features/products/presentation/controllers/product_controller.dart';
import 'package:mamark/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:mamark/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:mamark/features/cart/domain/repositories/cart_repository.dart';
import 'package:mamark/features/cart/domain/usecases/cart_usecases.dart';
import 'package:mamark/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mamark/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:mamark/features/orders/domain/repositories/order_repository.dart';
import 'package:mamark/features/orders/domain/usecases/order_usecases.dart';
import 'package:mamark/features/orders/presentation/controllers/order_controller.dart';
import 'package:mamark/features/notifications/presentation/controllers/notification_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Note: Since Supabase is placeholder in main, this might throw if not careful, 
    // but assuming standard execution:
    final supabase = Supabase.instance.client;
    Get.put(supabase);

    // --- Auth Feature ---
    Get.lazyPut<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(supabase));
    Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(Get.find()));
    
    Get.lazyPut(() => LoginUseCase(Get.find()));
    Get.lazyPut(() => RegisterUseCase(Get.find()));
    Get.lazyPut(() => GetCurrentUserUseCase(Get.find()));
    Get.lazyPut(() => VerifyOtpUseCase(Get.find()));
    Get.lazyPut(() => LogoutUseCase(Get.find()));
    Get.lazyPut(() => UpdateProfileUseCase(Get.find()));
    Get.lazyPut(() => ResetPasswordUseCase(Get.find()));
    Get.lazyPut(() => UpdatePasswordUseCase(Get.find()));
    Get.lazyPut(() => IsEmailAvailableUseCase(Get.find()));
    Get.lazyPut(() => IsUsernameAvailableUseCase(Get.find()));
    
    Get.put(AuthController(
      loginUseCase: Get.find(),
      registerUseCase: Get.find(),
      getCurrentUserUseCase: Get.find(),
      verifyOtpUseCase: Get.find(),
      logoutUseCase: Get.find(),
      updateProfileUseCase: Get.find(),
      resetPasswordUseCase: Get.find(),
      updatePasswordUseCase: Get.find(),
      isEmailAvailableUseCase: Get.find(),
      isUsernameAvailableUseCase: Get.find(),
    ), permanent: true);

    // --- Products Feature ---
    Get.lazyPut<ProductRemoteDataSource>(() => ProductRemoteDataSourceImpl(supabase));
    Get.lazyPut<ProductRepository>(() => ProductRepositoryImpl(Get.find()));
    
    Get.lazyPut(() => GetProductsUseCase(Get.find()));
    Get.lazyPut(() => AddProductUseCase(Get.find()));
    Get.lazyPut(() => UpdateProductUseCase(Get.find()));
    Get.lazyPut(() => DeleteProductUseCase(Get.find()));
    Get.lazyPut(() => StreamProductsUseCase(Get.find()));

    Get.put(ProductController(
      getProductsUseCase: Get.find(),
      addProductUseCase: Get.find(),
      updateProductUseCase: Get.find(),
      deleteProductUseCase: Get.find(),
      streamProductsUseCase: Get.find(),
    ));

    // --- Cart Feature ---
    Get.lazyPut<CartRemoteDataSource>(() => CartRemoteDataSourceImpl(supabase));
    Get.lazyPut<CartRepository>(() => CartRepositoryImpl(Get.find()));
    
    Get.lazyPut(() => GetCartUseCase(Get.find()));
    Get.lazyPut(() => AddToCartUseCase(Get.find()));
    Get.lazyPut(() => RemoveFromCartUseCase(Get.find()));
    Get.lazyPut(() => ClearCartUseCase(Get.find()));

    Get.put(CartController(
      getCartUseCase: Get.find(),
      addToCartUseCase: Get.find(),
      removeFromCartUseCase: Get.find(),
      clearCartUseCase: Get.find(),
    ));

    // --- Order Feature ---
    Get.lazyPut<OrderRemoteDataSource>(() => OrderRemoteDataSourceImpl(supabase));
    Get.lazyPut<OrderRepository>(() => OrderRepositoryImpl(Get.find()));
    
    Get.lazyPut(() => CreateOrderUseCase(Get.find()));
    Get.lazyPut(() => GetOrdersUseCase(Get.find()));
    Get.lazyPut(() => UpdateOrderStatusUseCase(Get.find()));
    Get.put(OrderController(
      createOrderUseCase: Get.find(),
      getOrdersUseCase: Get.find(),
      updateOrderStatusUseCase: Get.find(),
    ));

    Get.put(NotificationController());
  }
}
