import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/inventory_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  InventoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<InventoryEntity>>> getStoreInventory(String storeId) async {
    try {
      final models = await remoteDataSource.getStoreInventory(storeId);
      return Right(models);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, void>> updateInventory(String id, int quantityAvailable, int quantitySold) async {
    try {
      await remoteDataSource.updateInventory(id, quantityAvailable, quantitySold);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }
}
