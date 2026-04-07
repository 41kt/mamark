import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../models/product_model.dart';
import 'dart:async';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({String? category});
  Future<ProductModel> getProductById(String id);
  Future<ProductModel> addProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Stream<List<ProductModel>> streamProducts({String? category});
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient supabase;

  ProductRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<ProductModel>> getProducts({String? category}) async {
    try {
      var query = supabase.from('products').select('*, users!supplier_id(*)');
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      final response = await query;
      return (response as List).map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch products: $e');
    }
  }

  @override
  Stream<List<ProductModel>> streamProducts({String? category}) {
    // Note: Supabase limits stream joins. To get joined data on stream, we fetch normally or rely on initial fetch.
    // However, since we use `select` after stream if needed or simply just let getProducts do the heavy lifting:
    final streamBase = supabase.from('products').stream(primaryKey: ['id']);
    
    if (category != null && category.isNotEmpty) {
      return streamBase.eq('category', category).asyncMap((events) async {
        // Due to Supabase stream limitations with joins, we refetch fully or rely on getProducts.
        // For strict real-time joins, we fetch manually after trigger.
        final res = await supabase.from('products').select('*, users!supplier_id(*)').eq('category', category);
        return res.map((e) => ProductModel.fromJson(e)).toList();
      });
    }
    
    return streamBase.asyncMap((events) async {
      final res = await supabase.from('products').select('*, users!supplier_id(*)');
      return res.map((e) => ProductModel.fromJson(e)).toList();
    });
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await supabase.from('products').select().eq('id', id).single();
      return ProductModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Product not found: $e');
    }
  }

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    try {
      final response = await supabase.from('products').insert(product.toJson()).select().single();
      return ProductModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Failed to add product (check supplier role/auth): $e');
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await supabase.from('products')
          .update(product.toJson())
          .eq('id', product.id)
          .select()
          .single();
      return ProductModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
    } catch (e) {
      throw ServerFailure('Failed to delete product: $e');
    }
  }
}
