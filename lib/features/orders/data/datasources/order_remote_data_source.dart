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
      List<dynamic> response;
      if (isSupplier) {
        response = await supabase
            .from('orders')
            .select()
            .eq('supplier_id', userId)
            .order('created_at', ascending: false);
      } else {
        response = await supabase
            .from('orders')
            .select()
            .eq('customer_id', userId)
            .order('created_at', ascending: false);
      }
      
      // Manually fetch users to avoid PostgREST ambiguous foreign key errors
      Map<String, dynamic> userMap = {};
      try {
        if (response.isNotEmpty) {
           final userIds = response.map((e) => e['customer_id'].toString()).toSet().toList();
           final usersRes = await supabase.from('users').select('id, name, avatar_url').filter('id', 'in', userIds);
           for (var u in usersRes) {
             userMap[u['id'].toString()] = u;
           }
        }
      } catch (e) {
        // Warning: Failed to fetch customer profiles
      }

      return response.map((json) {
        try {
          final cid = json['customer_id'].toString();
          final userJson = userMap[cid];
          return OrderModel(
            id: json['id'] ?? '',
            userId: json['customer_id'] ?? '',
            supplierId: json['supplier_id'] ?? '',
            items: List<Map<String, dynamic>>.from(json['items'] ?? []),
            totalAmount: (json['total_amount'] as num).toDouble(),
            status: json['status'] ?? 'pending',
            createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
            customerName: userJson != null ? userJson['name'] : null,
            customerAvatarUrl: userJson != null ? userJson['avatar_url'] : null,
          );
        } catch (e) {
          return OrderModel(
            id: json['id'] ?? '',
            userId: json['customer_id'] ?? '',
            supplierId: json['supplier_id'] ?? '',
            items: [],
            totalAmount: 0.0,
            status: 'pending',
            createdAt: DateTime.now(),
            customerName: 'خطأ',
          );
        }
      }).toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch orders: \$e');
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
        .asyncMap((events) async {
          try {
            final res = await supabase
                .from('orders')
                .select()
                .eq('supplier_id', supplierId)
                .order('created_at', ascending: false);
                
            Map<String, dynamic> userMap = {};
            if (res.isNotEmpty) {
               final userIds = res.map((e) => e['customer_id'].toString()).toSet().toList();
               final usersRes = await supabase.from('users').select('id, name, avatar_url').filter('id', 'in', userIds);
               for (var u in usersRes) {
                 userMap[u['id'].toString()] = u;
               }
            }

            return res.map((json) {
              try {
                final cid = json['customer_id'].toString();
                final userJson = userMap[cid];
                return OrderModel(
                  id: json['id'] ?? '',
                  userId: json['customer_id'] ?? '',
                  supplierId: json['supplier_id'] ?? '',
                  items: List<Map<String, dynamic>>.from(json['items'] ?? []),
                  totalAmount: (json['total_amount'] as num).toDouble(),
                  status: json['status'] ?? 'pending',
                  createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
                  customerName: userJson != null ? userJson['name'] : null,
                  customerAvatarUrl: userJson != null ? userJson['avatar_url'] : null,
                );
              } catch (_) {
                return OrderModel(
                  id: json['id'] ?? '',
                  userId: json['customer_id'] ?? '',
                  supplierId: json['supplier_id'] ?? '',
                  items: [],
                  totalAmount: 0.0,
                  status: 'pending',
                  createdAt: DateTime.now(),
                  customerName: 'خطأ مزامنة',
                );
              }
            }).toList();
          } catch (e) {
             return [];
          }
        });
  }
}
