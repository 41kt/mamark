import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

class GetCartUseCase implements UseCase<List<CartItemEntity>, String> {
  final CartRepository repository;
  GetCartUseCase(this.repository);

  @override
  Future<Either<Failure, List<CartItemEntity>>> call(String userId) async {
    return await repository.getCartItems(userId);
  }
}

class AddToCartUseCase implements UseCase<void, CartItemEntity> {
  final CartRepository repository;
  AddToCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CartItemEntity item) async {
    return await repository.addToCart(item);
  }
}

class RemoveFromCartUseCase implements UseCase<void, String> {
  final CartRepository repository;
  RemoveFromCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String itemId) async {
    return await repository.removeFromCart(itemId);
  }
}

class ClearCartUseCase implements UseCase<void, String> {
  final CartRepository repository;
  ClearCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String userId) async {
    return await repository.clearCart(userId);
  }
}
