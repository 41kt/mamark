import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class IsEmailAvailableUseCase {
  final AuthRepository repository;

  IsEmailAvailableUseCase(this.repository);

  Future<Either<Failure, bool>> call(String email) async {
    return await repository.isEmailAvailable(email);
  }
}
