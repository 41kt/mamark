import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import 'package:mamark/core/error/failures.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders(String userId, {bool isSupplier = false});
  Future<void> createOrder(OrderModel order);
  Future<void> updateOrderStatus(String orderId, String status);
  Stream<List<OrderModel>> streamOrders(String supplierId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient supabase;

  OrderRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<OrderModel>> getOrders(String userId, {bool isSupplier = false}) async {
    try {
      final query = supabase.from('orders').select();
      if (isSupplier) {
        query.eq('supplier_id', userId);
      } else {
        query.eq('customer_id', userId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch orders: $e');
    }
  }

  @override
  Future<void> createOrder(OrderModel order) async {
    try {
      await supabase.from('orders').insert(order.toJson());
    } catch (e) {
      throw ServerFailure('Failed to create order: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await supabase.from('orders').update({'status': status}).eq('id', orderId);
    } catch (e) {
      throw ServerFailure('Failed to update order status: $e');
    }
  }

  @override
  Stream<List<OrderModel>> streamOrders(String supplierId) {
    return supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('supplier_id', supplierId)
        .map((data) => data.map((json) => OrderModel.fromJson(json)).toList());
  }
}
