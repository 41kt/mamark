import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';
import 'dart:async';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({String? category}) async {
    try {
      final models = await remoteDataSource.getProducts(category: category);
      return Right(models);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    try {
      final model = await remoteDataSource.getProductById(id);
      return Right(model);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> addProduct(ProductEntity product) async {
    try {
      final model = ProductModel(
        id: product.id,
        supplierId: product.supplierId,
        name: product.name,
        category: product.category,
        unit: product.unit,
        quantity: product.quantity,
        price: product.price,
        description: product.description,
        imageUrl: product.imageUrl,
      );
      final addedModel = await remoteDataSource.addProduct(model);
      return Right(addedModel);
    } catch (e) {
      return Left(ServerFailure('Failed to add product.'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(ProductEntity product) async {
    try {
      final model = ProductModel(
        id: product.id,
        supplierId: product.supplierId,
        name: product.name,
        category: product.category,
        unit: product.unit,
        quantity: product.quantity,
        price: product.price,
        description: product.description,
        imageUrl: product.imageUrl,
      );
      final updatedModel = await remoteDataSource.updateProduct(model);
      return Right(updatedModel);
    } catch (e) {
      return Left(ServerFailure('Failed to update product.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await remoteDataSource.deleteProduct(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete product.'));
    }
  }

  @override
  Stream<Either<Failure, List<ProductEntity>>> streamProducts({String? category}) {
    return remoteDataSource.streamProducts(category: category).map(
      (models) => Right<Failure, List<ProductEntity>>(models)
    ).handleError((error) {
      return Left<Failure, List<ProductEntity>>(ServerFailure('Stream error: $error'));
    });
  }
}
