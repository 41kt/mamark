import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String username, String email, String password, String role);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> updatePassword(String newPassword);
  Future<void> resetPassword(String email);
  Future<UserModel> updateProfile({String? name, String? username, String? storeName, String? avatarUrl});
  Future<UserModel> verifyOtp(String email, String token);
  Future<bool> isEmailAvailable(String email);
  Future<bool> isUsernameAvailable(String username);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSourceImpl(this.supabase);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(email: email, password: password);
      if (response.user == null) throw AuthFailure('Login failed');
      
      final userData = await supabase.from('users').select().eq('id', response.user!.id).single();
      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<UserModel> register(String name, String username, String email, String password, String role) async {
    try {
      // 1. Check uniqueness
      if (!await isEmailAvailable(email)) throw AuthFailure('البريد الإلكتروني مستخدم بالفعل');
      if (!await isUsernameAvailable(username)) throw AuthFailure('اسم المستخدم مستخدم بالفعل');

      // 2. Create auth user
      final response = await supabase.auth.signUp(email: email, password: password);
      if (response.user == null) throw AuthFailure('Registration failed');
      
      // 3. Insert into public.users
      final userData = {
        'id': response.user!.id,
        'name': name,
        'username': username,
        'email': email,
        'role': role,
      };
      
      await supabase.from('users').insert(userData);
      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    try {
      final userData = await supabase.from('users').select().eq('id', session.user.id).single();
      return UserModel.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<UserModel> updateProfile({String? name, String? username, String? storeName, String? avatarUrl}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw AuthFailure('Not authenticated');

      // Check uniqueness for username if changing
      if (username != null) {
        final currentData = await supabase.from('users').select('username').eq('id', user.id).single();
        if (currentData['username'] != username) {
          if (!await isUsernameAvailable(username)) throw AuthFailure('اسم المستخدم مستخدم بالفعل');
        }
      }

      final updateData = {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (storeName != null) 'store_name': storeName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      if (updateData.isEmpty) throw AuthFailure('No data to update');

      final response = await supabase.from('users').update(updateData).eq('id', user.id).select().single();
      return UserModel.fromJson(response);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<UserModel> verifyOtp(String email, String token) async {
    try {
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      if (response.user == null) {
        throw AuthFailure('التحقق فشل. الرمز قد يكون خطأ أو منتهي الصلاحية.');
      }

      final userData = await supabase.from('users').select().eq('id', response.user!.id).single();
      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('حدث خطأ غير متوقع: $e');
    }
  }
  @override
  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await supabase.from('users').select('email').eq('email', email).maybeSingle();
      return response == null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await supabase.from('users').select('username').eq('username', username).maybeSingle();
      return response == null;
    } catch (e) {
      return false;
    }
  }
}
