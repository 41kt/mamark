import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class AddProductUseCase implements UseCase<ProductEntity, ProductEntity> {
  final ProductRepository repository;
  AddProductUseCase(this.repository);
  
  @override
  Future<Either<Failure, ProductEntity>> call(ProductEntity product) async {
    return await repository.addProduct(product);
  }
}

class UpdateProductUseCase implements UseCase<ProductEntity, ProductEntity> {
  final ProductRepository repository;
  UpdateProductUseCase(this.repository);
  
  @override
  Future<Either<Failure, ProductEntity>> call(ProductEntity product) async {
    return await repository.updateProduct(product);
  }
}

class DeleteProductUseCase implements UseCase<void, String> {
  final ProductRepository repository;
  DeleteProductUseCase(this.repository);
  
  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteProduct(id);
  }
}

class StreamProductsUseCase {
  final ProductRepository repository;
  StreamProductsUseCase(this.repository);
  
  Stream<Either<Failure, List<ProductEntity>>> call({String? category}) {
    return repository.streamProducts(category: category);
  }
}
