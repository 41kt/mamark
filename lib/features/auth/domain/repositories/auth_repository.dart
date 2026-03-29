import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> register(
    String name,
    String username,
    String email,
    String password,
    String role,
  );
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, void>> updatePassword(String newPassword);
  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, UserEntity>> updateProfile({String? name, String? username, String? storeName, String? avatarUrl});
  Future<Either<Failure, UserEntity>> verifyOtp(String email, String token);
  Future<Either<Failure, bool>> isEmailAvailable(String email);
  Future<Either<Failure, bool>> isUsernameAvailable(String username);
}
