import 'package:dartz/dartz.dart';
import 'package:mamark/core/error/failures.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';
import '../models/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;

  CartRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<CartItemEntity>>> getCartItems(String userId) async {
    try {
      final items = await remoteDataSource.getCartItems(userId);
      return Right(items);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, void>> addToCart(CartItemEntity item) async {
    try {
      final model = CartItemModel(
        id: item.id,
        userId: item.userId,
        productId: item.productId,
        quantity: item.quantity,
      );
      await remoteDataSource.addToCart(model);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, void>> removeFromCart(String itemId) async {
    try {
      await remoteDataSource.removeFromCart(itemId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, void>> clearCart(String userId) async {
    try {
      await remoteDataSource.clearCart(userId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Stream<List<CartItemEntity>> streamCartItems(String userId) {
    return remoteDataSource.streamCartItems(userId);
  }
}
