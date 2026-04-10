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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/contractor/presentation/screens/contractor_main_screen.dart';
import 'features/customer/presentation/screens/customer_main_screen.dart';
import 'features/projects/presentation/screens/project_execution_screen.dart';
import 'features/projects/presentation/screens/project_details_screen.dart';
import 'features/projects/presentation/screens/my_projects_list_screen.dart';
import 'features/projects/presentation/screens/create_project_screen.dart';
import 'features/projects/presentation/screens/create_bid_screen.dart';
import 'features/projects/presentation/screens/browse_projects_screen.dart';
import 'features/projects/presentation/screens/bid_detail_screen.dart';
import 'features/projects/presentation/screens/bids_list_screen.dart';
import 'features/customer/presentation/screens/browse_contractors_screen.dart';
import 'features/contractor/presentation/screens/portfolio_screen.dart';
import 'features/contractor/presentation/screens/contractor_profile_screen.dart';
import 'features/contractor/presentation/screens/add_portfolio_item_screen.dart';

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
        GetPage(
          name: '/contractor-home',
          page: () => const ProviderScope(child: ContractorMainScreen()),
        ),
        GetPage(
          name: '/customer-home',
          page: () => const ProviderScope(child: CustomerMainScreen()),
        ),
        GetPage(name: '/create-project', page: () => const ProviderScope(child: CreateProjectScreen())),
        GetPage(name: '/browse-contractors', page: () => const ProviderScope(child: BrowseContractorsScreen())),
        GetPage(name: '/contractor-profile/:id', page: () => ProviderScope(child: ContractorProfileScreen(contractorId: Get.parameters['id']!))),
        GetPage(name: '/portfolio', page: () => const ProviderScope(child: PortfolioScreen())),
        GetPage(name: '/add-portfolio', page: () => const ProviderScope(child: AddPortfolioItemScreen())),
        GetPage(name: '/my-projects', page: () => const ProviderScope(child: MyProjectsListScreen())),
        GetPage(name: '/project-details/:id', page: () => ProviderScope(child: ProjectDetailsScreen(projectId: Get.parameters['id']!))),
        GetPage(name: '/browse-projects', page: () => const ProviderScope(child: BrowseProjectsScreen())),
        GetPage(name: '/create-bid/:projectId', page: () => ProviderScope(child: CreateBidScreen(projectId: Get.parameters['projectId']!))),
        GetPage(name: '/bids-list/:projectId', page: () => ProviderScope(child: BidsListScreen(projectId: Get.parameters['projectId']!))),
        GetPage(name: '/bid-detail/:bidId', page: () => ProviderScope(child: BidDetailScreen(bidId: Get.parameters['bidId']!))),
        GetPage(name: '/project-execution/:projectId', page: () => ProviderScope(child: ProjectExecutionScreen(projectId: Get.parameters['projectId']!))),
        GetPage(name: '/marketplace', page: () => const HomeView()),
      ],
    );
  }
}
