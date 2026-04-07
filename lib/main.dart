import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/localization/app_translations.dart';
import 'core/services/localization_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';

// NEW CLEAN ARCHITECTURE IMPORTS
import 'core/bindings/main_binding.dart';
import 'features/splash/presentation/views/splash_view.dart';
import 'features/auth/presentation/views/forgot_password_view.dart';

// NEW CLEAN ARCHITECTURE VIEWS
import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/register_view.dart';
import 'features/auth/presentation/views/edit_profile_view.dart';
import 'features/auth/presentation/views/verify_otp_view.dart';
import 'features/products/presentation/views/home_view.dart';
import 'features/products/presentation/views/add_product_view.dart';
import 'features/products/presentation/views/store_detail_view.dart';
import 'features/auth/presentation/views/supplier_profile_view.dart';
import 'features/cart/presentation/views/cart_view.dart';
import 'features/orders/presentation/views/orders_view.dart';
import 'features/settings/presentation/views/settings_view.dart';
import 'features/chat/presentation/views/chat_view.dart';
import 'features/notifications/presentation/views/notification_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Init SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);
  
  // Init Core Services
  Get.put(ThemeService(Get.find()), permanent: true);
  Get.put(LocalizationService(Get.find()), permanent: true);

  // Init Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final localizationService = Get.find<LocalizationService>();

    return GetMaterialApp(
      title: 'app_name'.tr,
      debugShowCheckedModeBanner: false,
      initialBinding: MainBinding(), // Using new MainBinding
      translations: AppTranslations(),
      locale: localizationService.currentLanguage,
      fallbackLocale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashView()),
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/forgot-password', page: () => const ForgotPasswordView()),
        GetPage(name: '/register', page: () => const RegisterView()),
        GetPage(name: '/edit-profile', page: () => const EditProfileView()),
        GetPage(name: '/verify-otp', page: () => const VerifyOtpView()),
        GetPage(name: '/home', page: () => const HomeView()),
        GetPage(name: '/add-product', page: () => const AddProductView()),
        GetPage(name: '/store-detail', page: () => const StoreDetailView()),
        GetPage(name: '/supplier-profile', page: () => const SupplierProfileView()),
        GetPage(name: '/cart', page: () => const CartView()),
        GetPage(name: '/orders', page: () => const OrdersView()),
        GetPage(name: '/settings', page: () => const SettingsView()),
        GetPage(name: '/chat', page: () => const ChatView()),
        GetPage(name: '/notifications', page: () => const NotificationListView()),
      ],
    );
  }
}
