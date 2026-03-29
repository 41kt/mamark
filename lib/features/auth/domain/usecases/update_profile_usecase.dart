import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileParams {
  final String? name;
  final String? username;
  final String? storeName;
  final String? avatarUrl;

  UpdateProfileParams({this.name, this.username, this.storeName, this.avatarUrl});
}

class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      name: params.name,
      username: params.username,
      storeName: params.storeName,
      avatarUrl: params.avatarUrl,
    );
  }
}
