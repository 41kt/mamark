import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/rating_remote_data_source.dart';

class RatingController extends GetxController {
  final RatingRemoteDataSource _dataSource;
  RatingController(this._dataSource);

  var averageRating = 0.0.obs;
  var userRating = 0.obs;     // 0 = not yet rated
  var isLoading = false.obs;

  Future<void> loadRatings(String productId) async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser.value?.id;

      final avg = await _dataSource.getAverageRating(productId);
      averageRating.value = avg;

      if (userId != null) {
        final myRating = await _dataSource.getUserRating(productId, userId);
        userRating.value = myRating ?? 0;
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> submitRating(String productId, int rating) async {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUser.value?.id;
    if (userId == null) {
      Get.snackbar('تنبيه', 'يجب تسجيل الدخول أولاً لإضافة تقييم');
      return;
    }
    isLoading.value = true;
    try {
      await _dataSource.submitRating(productId, userId, rating);
      userRating.value = rating;
      final newAvg = await _dataSource.getAverageRating(productId);
      averageRating.value = newAvg;
      Get.snackbar('rating_success'.tr, '', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('rating_error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

/// Factory helper — create a fresh controller per product page
RatingController buildRatingController() {
  final supabase = Get.find<SupabaseClient>();
  return RatingController(RatingRemoteDataSourceImpl(supabase));
}
