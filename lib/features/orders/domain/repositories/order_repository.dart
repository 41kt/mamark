import 'package:dartz/dartz.dart';
import 'package:mamark/core/error/failures.dart';
import 'package:mamark/features/orders/domain/entities/order_entity.dart';
import 'package:mamark/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:mamark/features/orders/data/models/order_model.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderEntity>>> getOrders(String userId, {bool isSupplier = false});
  Future<Either<Failure, void>> createOrder(OrderEntity order);
  Future<Either<Failure, void>> updateOrderStatus(String orderId, String status);
  Stream<List<OrderEntity>> streamOrders(String supplierId);
}

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders(String userId, {bool isSupplier = false}) async {
    try {
      final orders = await remoteDataSource.getOrders(userId, isSupplier: isSupplier);
      return Right(orders);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, void>> createOrder(OrderEntity order) async {
    try {
      final model = OrderModel(
        id: order.id,
        userId: order.userId,
        supplierId: order.supplierId,
        items: order.items,
        totalAmount: order.totalAmount,
        status: order.status,
        createdAt: order.createdAt,
      );
      await remoteDataSource.createOrder(model);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(String orderId, String status) async {
    try {
      await remoteDataSource.updateOrderStatus(orderId, status);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Stream<List<OrderEntity>> streamOrders(String supplierId) {
    return remoteDataSource.streamOrders(supplierId);
  }
}
