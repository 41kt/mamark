import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/update_password_usecase.dart';
import '../../domain/usecases/is_email_available_usecase.dart';
import '../../domain/usecases/is_username_available_usecase.dart';
import '../../../../core/usecases/usecase.dart';

class AuthController extends GetxController {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final LogoutUseCase logoutUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;
  final IsEmailAvailableUseCase isEmailAvailableUseCase;
  final IsUsernameAvailableUseCase isUsernameAvailableUseCase;

  AuthController({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.getCurrentUserUseCase,
    required this.verifyOtpUseCase,
    required this.logoutUseCase,
    required this.updateProfileUseCase,
    required this.resetPasswordUseCase,
    required this.updatePasswordUseCase,
    required this.isEmailAvailableUseCase,
    required this.isUsernameAvailableUseCase,
  });

  var isLoading = false.obs;
  var isViewAsCustomer = false.obs;
  var currentUser = Rxn<UserEntity>();
  var registrationEmail = ''.obs;
  var pickedAvatar = Rx<File?>(null);
  
  final _picker = ImagePicker();

  Future<void> pickAvatar(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      pickedAvatar.value = File(image.path);
    }
  }

  Future<String?> uploadAvatar(File image) async {
    try {
      final supabase = Get.find<SupabaseClient>();
      final fileName = 'avatars/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.storage.from('avatars').upload(fileName, image);
      return supabase.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      Get.snackbar('خطأ في الرفع', e.toString());
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => currentUser.value = null,
      (user) => currentUser.value = user,
    );
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    final result = await loginUseCase(LoginParams(email: email, password: password));
    result.fold(
      (failure) {
        Get.snackbar('خطأ', failure.message, backgroundColor: Colors.red[200]);
      },
      (user) {
        currentUser.value = user;
        Get.offAllNamed('/home');
      },
    );
    isLoading.value = false;
  }

  Future<void> register(String name, String username, String email, String password, String role) async {
    isLoading.value = true;
    registrationEmail.value = email;

    // Proactive uniqueness check
    final emailResult = await isEmailAvailableUseCase(email);
    final userResult = await isUsernameAvailableUseCase(username);

    bool emailAvailable = false;
    bool userAvailable = false;

    emailResult.fold((f) => null, (available) => emailAvailable = available);
    userResult.fold((f) => null, (available) => userAvailable = available);

    if (!emailAvailable) {
      Get.snackbar('خطأ', 'البريد الإلكتروني مستخدم بالفعل', backgroundColor: Colors.red[200]);
      isLoading.value = false;
      return;
    }
    if (!userAvailable) {
      Get.snackbar('خطأ', 'اسم المستخدم مستخدم بالفعل', backgroundColor: Colors.red[200]);
      isLoading.value = false;
      return;
    }

    final result = await registerUseCase(RegisterParams(
      name: name,
      username: username,
      email: email,
      password: password,
      role: role,
    ));
    
    result.fold(
      (failure) {
        String message = failure.message;
        if (message.contains('already registered') || message.contains('users_email_key')) {
          message = 'هذا البريد الإلكتروني مسجل بالفعل';
        } else if (message.contains('username') || message.contains('users_username_key')) {
          message = 'اسم المستخدم هذا مأخوذ بالفعل';
        }
        Get.snackbar('خطأ في التسجيل', message, backgroundColor: Colors.red[200]);
      },
      (user) {
        currentUser.value = user;
        Get.offAllNamed('/home');
        Get.snackbar('نجاح', 'تم إنشاء الحساب بنجاح', backgroundColor: Colors.green[200]);
      },
    );
    isLoading.value = false;
  }

  Future<void> verifyOtp(String token) async {
    if (registrationEmail.value.isEmpty) {
      Get.snackbar('خطأ', 'البريد الإلكتروني غير مفقود. يرجى إعادة محاولة التسجيل.');
      return;
    }

    isLoading.value = true;
    final result = await verifyOtpUseCase(VerifyOtpParams(
      email: registrationEmail.value,
      token: token,
    ));

    result.fold(
      (failure) {
        Get.snackbar('فشل التحقق', failure.message, backgroundColor: Colors.red[200]);
      },
      (user) {
        currentUser.value = user;
        Get.offAllNamed('/home');
        Get.snackbar('نجاح', 'تم التحقق من حسابك بنجاح', backgroundColor: Colors.green[200]);
      },
    );
    isLoading.value = false;
  }

  Future<void> logout() async {
    isLoading.value = true;
    await logoutUseCase(NoParams());
    currentUser.value = null;
    isLoading.value = false;
  }

  Future<void> updateProfile({String? name, String? username, String? storeName, String? avatarUrl}) async {
    isLoading.value = true;
    
    String? finalAvatarUrl = avatarUrl;
    if (pickedAvatar.value != null) {
      finalAvatarUrl = await uploadAvatar(pickedAvatar.value!);
    }

    if (username != null && username != currentUser.value?.username) {
      final availableResult = await isUsernameAvailableUseCase(username);
      bool isAvailable = false;
      availableResult.fold((f) => null, (available) => isAvailable = available);
      if (!isAvailable) {
        Get.snackbar('خطأ', 'اسم المستخدم هذا مستخدم بالفعل', backgroundColor: Colors.red[200]);
        isLoading.value = false;
        return;
      }
    }

    final result = await updateProfileUseCase(UpdateProfileParams(
      name: name,
      username: username,
      storeName: storeName,
      avatarUrl: finalAvatarUrl,
    ));
    
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message, backgroundColor: Colors.red[200]),
      (user) {
        currentUser.value = user;
        pickedAvatar.value = null; // Clear after success
        Get.snackbar('نجاح', 'تم تحديث الملف الشخصي بنجاح', backgroundColor: Colors.green[200]);
      },
    );
    isLoading.value = false;
  }

  Future<void> requestPasswordReset(String email) async {
    isLoading.value = true;
    final result = await resetPasswordUseCase(email);
    result.fold(
      (failure) => Get.snackbar('خطأ', failure.message, backgroundColor: Colors.red[200]),
      (_) {
        registrationEmail.value = email;
        Get.toNamed('/verify-otp', arguments: {'email': email, 'type': 'recovery'});
        Get.snackbar('نجاح', 'تم إرسال رمز التحقق إلى بريدك الإلكتروني', backgroundColor: Colors.green[200]);
      },
    );
    isLoading.value = false;
  }

  Future<void> verifyRecoveryOtp(String token, String newPassword) async {
    isLoading.value = true;
    final supabase = Get.find<SupabaseClient>();
    try {
      final response = await supabase.auth.verifyOTP(
        email: registrationEmail.value,
        token: token,
        type: OtpType.recovery,
      );

      if (response.user != null) {
        await updatePasswordUseCase(newPassword);
        Get.offAllNamed('/login');
        Get.snackbar('نجاح', 'تم تغيير كلمة المرور بنجاح', backgroundColor: Colors.green[200]);
      } else {
        Get.snackbar('خطأ', 'فشل التحقق من الرمز', backgroundColor: Colors.red[200]);
      }
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), backgroundColor: Colors.red[200]);
    }
    isLoading.value = false;
  }

  void toggleStoreMode() {
    isViewAsCustomer.value = !isViewAsCustomer.value;
    Get.snackbar(
      'وضع المتجر', 
      isViewAsCustomer.value ? 'أنت تتصفح كمتسوق الآن' : 'عدت إلى وضع المورد',
      snackPosition: SnackPosition.BOTTOM
    );
  }
}
