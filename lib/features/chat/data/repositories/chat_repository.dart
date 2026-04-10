import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/storage_provider.dart';

class ChatRepository {
  final SupabaseClient _supabase;
  final StorageService _storage;

  ChatRepository(this._supabase, this._storage);

  /// Handle main message sending with multi-attachments support (mapped to user schema)
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String? text,
    List<ChatAttachmentMetadata>? attachments,
  }) async {
    try {
      final firstAttachment = (attachments != null && attachments.isNotEmpty) ? attachments.first : null;
      
      // 1. Insert message record (Map to User's Schema: message_text, message_type, attachment_url)
      final msgResponse = await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'message_text': text ?? (firstAttachment != null ? 'أرسل مرفقاً' : ''),
        'message_type': firstAttachment != null ? firstAttachment.type : 'text',
        'attachment_url': firstAttachment?.url,
        'attachment_name': firstAttachment?.name,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      }).select().single();

      final messageId = msgResponse['id'];

      // 2. Insert into message_attachments if multi-attachments are desired 
      if (attachments != null && attachments.length > 1) {
        for (int i = 1; i < attachments.length; i++) {
           final att = attachments[i];
           try {
             await _supabase.from('message_attachments').insert({
               'message_id': messageId,
               'file_url': att.url,
               'file_type': att.type,
               'file_name': att.name,
               'file_size': att.size,
             });
           } catch (_) {
             // If table doesn't exist, we fallback to just the first attachment in messages table
           }
        }
      }

      // 3. Update chat header meta (user schema: last_message, updated_at)
      await _supabase.from('chats').update({
        'last_message': text ?? (firstAttachment != null ? 'أرسل مرفقاً' : ''),
        'updated_at': DateTime.now().toIso8601String(),
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

    } catch (e) {
      rethrow;
    }
  }

  /// Specialized upload for chat
  Future<ChatAttachmentMetadata> uploadFile({
    required String chatId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final res = await _storage.uploadChatAttachment(
      bytes: bytes,
      chatId: chatId,
      fileName: fileName,
      mimeType: mimeType,
    );
    
    if (res['success'] == true) {
       return ChatAttachmentMetadata(
         url: res['url'],
         name: fileName,
         type: _identifyType(mimeType),
         size: bytes.length,
       );
    } else {
       throw Exception("فشل رفع الملف: ${res['error']}");
    }
  }

  String _identifyType(String mime) {
    if (mime.startsWith('image/')) return 'image';
    if (mime.contains('pdf')) return 'file';
    if (mime.contains('doc') || mime.contains('msword')) return 'file';
    return 'file';
  }

  /// Find or create a chat room for a project
  Future<String> getOrCreateProjectChat({
    required String projectId,
    required String customerId,
    required String contractorId,
  }) async {
    try {
       final res = await _supabase.from('chats')
          .select('id')
          .eq('project_id', projectId)
          .maybeSingle();

       if (res != null) return res['id'].toString();

       final newChat = await _supabase.from('chats').insert({
         'project_id': projectId,
         'chat_type': 'project',
         'user1_id': customerId,
         'user2_id': contractorId,
         'updated_at': DateTime.now().toIso8601String(),
       }).select('id').single();

       return newChat['id'].toString();
    } catch (e) {
      rethrow;
    }
  }
}

class ChatAttachmentMetadata {
  final String url;
  final String name;
  final String type;
  final int size;

  ChatAttachmentMetadata({required this.url, required this.name, required this.type, required this.size});
}

