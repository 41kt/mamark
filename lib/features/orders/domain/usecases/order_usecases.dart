import 'package:dartz/dartz.dart';
import 'package:mamark/core/error/failures.dart';
import 'package:mamark/core/usecases/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CreateOrderUseCase implements UseCase<void, OrderEntity> {
  final OrderRepository repository;
  CreateOrderUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(OrderEntity order) async {
    return await repository.createOrder(order);
  }
}

class GetOrdersUseCase implements UseCase<List<OrderEntity>, GetOrdersParams> {
  final OrderRepository repository;
  GetOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(GetOrdersParams params) async {
    return await repository.getOrders(params.userId, isSupplier: params.isSupplier);
  }
}

class UpdateOrderStatusUseCase implements UseCase<void, UpdateStatusParams> {
  final OrderRepository repository;
  UpdateOrderStatusUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateStatusParams params) async {
    return await repository.updateOrderStatus(params.orderId, params.status);
  }
}

class GetOrdersParams {
  final String userId;
  final bool isSupplier;
  GetOrdersParams({required this.userId, this.isSupplier = false});
}

class UpdateStatusParams {
  final String orderId;
  final String status;
  UpdateStatusParams({required this.orderId, required this.status});
}
