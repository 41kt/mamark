import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RatingRemoteDataSource {
  Future<double> getAverageRating(String productId);
  Future<int?> getUserRating(String productId, String userId);
  Future<void> submitRating(String productId, String userId, int rating);
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  final SupabaseClient supabase;
  RatingRemoteDataSourceImpl(this.supabase);

  @override
  Future<double> getAverageRating(String productId) async {
    final response = await supabase
        .from('ratings')
        .select('rating')
        .eq('product_id', productId);
    if ((response as List).isEmpty) return 0.0;
    final total = response.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
    return total / response.length;
  }

  @override
  Future<int?> getUserRating(String productId, String userId) async {
    final response = await supabase
        .from('ratings')
        .select('rating')
        .eq('product_id', productId)
        .eq('user_id', userId)
        .maybeSingle();
    return response?['rating'] as int?;
  }

  @override
  Future<void> submitRating(String productId, String userId, int rating) async {
    await supabase.from('ratings').upsert({
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
    }, onConflict: 'product_id,user_id');
  }
}
