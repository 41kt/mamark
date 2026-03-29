import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class IsUsernameAvailableUseCase {
  final AuthRepository repository;

  IsUsernameAvailableUseCase(this.repository);

  Future<Either<Failure, bool>> call(String username) async {
    return await repository.isUsernameAvailable(username);
  }
}
