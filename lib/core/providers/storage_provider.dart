import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

final storageProvider = Provider<StorageService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return StorageService(supabase);
});

class StorageService {
  final SupabaseClient _supabase;
  StorageService(this._supabase);

  // Upload using File (Native platforms only correctly)
  Future<String?> uploadFile({
    required File file,
    required String bucket,
    required String path,
  }) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final fullPath = '$path/$fileName';
      
      await _supabase.storage.from(bucket).upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          
      final String publicUrl = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Upload using Bytes (Cross-platform coverage: Web/Native)
  Future<Map<String, dynamic>> uploadBytes({
    required Uint8List bytes,
    required String bucket,
    required String path,
    String? mimeType,
  }) async {
    try {
      await _supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600', 
              upsert: true,
              contentType: mimeType,
            ),
          );
          
      final String publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      return {'success': true, 'url': publicUrl};
    } catch (e) {
      debugPrint('Error uploading bytes: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // -------------------------------------------------------------
  // Specific Chat Helpers
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> uploadChatAttachment({
    required Uint8List bytes,
    required String chatId,
    required String fileName,
    String? mimeType,
  }) async {
     final time = DateTime.now().millisecondsSinceEpoch;
     final path = 'chats/$chatId/$time-$fileName';
     return uploadBytes(
        bytes: bytes, 
        bucket: 'chat_attachments', 
        path: path, 
        mimeType: mimeType
     );
  }

  // -------------------------------------------------------------
  // Specific Project Helpers
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> uploadProjectFile({
    required Uint8List bytes,
    required String projectId,
    required String fileName,
    String? mimeType,
  }) async {
     final time = DateTime.now().millisecondsSinceEpoch;
     final path = 'projects/$projectId/$time-$fileName';
     return uploadBytes(
        bytes: bytes, 
        bucket: 'projects',
        path: path, 
        mimeType: mimeType
     );
  }
}

