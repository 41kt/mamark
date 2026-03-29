import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item_model.dart';
import '../../../../core/error/failures.dart';

abstract class CartRemoteDataSource {
  Future<List<CartItemModel>> getCartItems(String userId);
  Future<void> addToCart(CartItemModel item);
  Future<void> removeFromCart(String itemId);
  Future<void> clearCart(String userId);
  Stream<List<CartItemModel>> streamCartItems(String userId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final SupabaseClient supabase;

  CartRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<CartItemModel>> getCartItems(String userId) async {
    try {
      final response = await supabase
          .from('cart')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at');
      
      return (response as List).map((json) => CartItemModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch cart: $e');
    }
  }

  @override
  Future<void> addToCart(CartItemModel item) async {
    try {
      // Check if item already exists to update quantity instead
      final existing = await supabase
          .from('cart')
          .select()
          .eq('user_id', item.userId)
          .eq('product_id', item.productId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('cart')
            .update({'quantity': (existing['quantity'] as int) + item.quantity})
            .eq('id', existing['id']);
      } else {
        await supabase.from('cart').insert(item.toJson());
      }
    } catch (e) {
      throw ServerFailure('Failed to add to cart: $e');
    }
  }

  @override
  Future<void> removeFromCart(String itemId) async {
    try {
      await supabase.from('cart').delete().eq('id', itemId);
    } catch (e) {
      throw ServerFailure('Failed to remove from cart: $e');
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      await supabase.from('cart').delete().eq('user_id', userId);
    } catch (e) {
      throw ServerFailure('Failed to clear cart: $e');
    }
  }

  @override
  Stream<List<CartItemModel>> streamCartItems(String userId) {
    return supabase
        .from('cart')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => CartItemModel.fromJson(json)).toList());
  }
}
