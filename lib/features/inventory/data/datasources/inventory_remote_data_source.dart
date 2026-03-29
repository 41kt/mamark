import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../models/inventory_model.dart';
import 'dart:async';

abstract class InventoryRemoteDataSource {
  Future<List<InventoryModel>> getStoreInventory(String storeId);
  Future<void> updateInventory(String id, int quantityAvailable, int quantitySold);
  Stream<List<InventoryModel>> streamStoreInventory(String storeId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final SupabaseClient supabase;
  InventoryRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<InventoryModel>> getStoreInventory(String storeId) async {
    try {
      final response = await supabase.from('inventory').select().eq('store_id', storeId);
      return (response as List).map((e) => InventoryModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch inventory: $e');
    }
  }

  @override
  Future<void> updateInventory(String id, int quantityAvailable, int quantitySold) async {
    try {
      await supabase.from('inventory').update({
        'quantity_available': quantityAvailable,
        'quantity_sold': quantitySold,
      }).eq('id', id);
    } catch (e) {
      throw ServerFailure('Failed to update inventory: $e');
    }
  }

  @override
  Stream<List<InventoryModel>> streamStoreInventory(String storeId) {
    return supabase
        .from('inventory')
        .stream(primaryKey: ['id'])
        .eq('store_id', storeId)
        .map((events) => events.map((e) => InventoryModel.fromJson(e)).toList());
  }
}
