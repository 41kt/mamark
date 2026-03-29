import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/inventory_entity.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<InventoryEntity>>> getStoreInventory(String storeId);
  Future<Either<Failure, void>> updateInventory(String id, int quantityAvailable, int quantitySold);
}
