import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

class GetStoreInventoryUseCase implements UseCase<List<InventoryEntity>, String> {
  final InventoryRepository repository;
  GetStoreInventoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<InventoryEntity>>> call(String storeId) async {
    return await repository.getStoreInventory(storeId);
  }
}
