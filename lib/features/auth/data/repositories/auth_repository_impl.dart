import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(
    String name,
    String username,
    String email,
    String password,
    String role,
  ) async {
    try {
      final userModel = await remoteDataSource.register(name, username, email, password, role);
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to logout.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Right(userModel);
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      await remoteDataSource.updatePassword(newPassword);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({String? name, String? username, String? storeName, String? avatarUrl}) async {
    try {
      final userModel = await remoteDataSource.updateProfile(
        name: name,
        username: username,
        storeName: storeName,
        avatarUrl: avatarUrl,
      );
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp(String email, String token) async {
    try {
      final userModel = await remoteDataSource.verifyOtp(email, token);
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('حدث خطأ أثناء التحقق من الرمز.'));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailAvailable(String email) async {
    try {
      final isAvailable = await remoteDataSource.isEmailAvailable(email);
      return Right(isAvailable);
    } catch (e) {
      return Left(ServerFailure('خطأ في التحقق من توافر البريد.'));
    }
  }

  @override
  Future<Either<Failure, bool>> isUsernameAvailable(String username) async {
    try {
      final isAvailable = await remoteDataSource.isUsernameAvailable(username);
      return Right(isAvailable);
    } catch (e) {
      return Left(ServerFailure('خطأ في التحقق من توافر اسم المستخدم.'));
    }
  }
}
