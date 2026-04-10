import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../data/repositories/chat_repository.dart';

// ────────────────────────────────────────────────
// Chat Repository Instance
// ────────────────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final storage = ref.watch(storageProvider);
  return ChatRepository(supabase, storage);
});

// ────────────────────────────────────────────────
// Chat List
// ────────────────────────────────────────────────
final chatsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return [];

  try {
    // نجلب أولاً كل المحادثات الخاصة بالمستخدم بدون Join لتفادي مشاكل الـ Foreign Keys
    final response = await supabase
        .from('chats')
        .select('*')
        .or('user1_id.eq.${user.id},user2_id.eq.${user.id}');
    
    // الترتيب باستخدام Dart
    List<Map<String, dynamic>> chats = List<Map<String, dynamic>>.from(response);
    chats.sort((a, b) {
      final t1 = a['last_message_at'] ?? a['updated_at'] ?? a['created_at'] ?? '';
      final t2 = b['last_message_at'] ?? b['updated_at'] ?? b['created_at'] ?? '';
      return t2.toString().compareTo(t1.toString());
    });

    // جلب معلومات المستخدمين الآخرين لتعويض الـ Join المباشر كحماية إضافية
    for (int i = 0; i < chats.length; i++) {
        final chat = chats[i];
        final otherId = chat['user1_id'] == user.id ? chat['user2_id'] : chat['user1_id'];
        
        if (otherId != null) {
           try {
              final otherProfile = await supabase.from('profiles').select('*').eq('user_id', otherId).maybeSingle();
              final otherContractor = await supabase.from('contractors').select('*').eq('user_id', otherId).maybeSingle();
              final otherCustomer = await supabase.from('customers').select('*').eq('user_id', otherId).maybeSingle();
              
              final mergedProfile = {
                 ...?otherProfile,
                 ...?otherContractor,
                 ...?otherCustomer,
              };

              if (mergedProfile.isNotEmpty) {
                  if (chat['user1_id'] == user.id) {
                     chat['profiles2'] = mergedProfile;
                  } else {
                     chat['profiles1'] = mergedProfile;
                  }
              }
           } catch (_) {}
        }
    }

    return chats;
  } catch (e) {
    debugPrint("ERROR fetching chats: $e");
    return [];
  }
});

// ────────────────────────────────────────────────
// Real-time Chat Messages Stream
// ────────────────────────────────────────────────
final chatMessagesStreamProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, chatId) {
  final supabase = ref.read(supabaseProvider);
  
  // Create a stream that emits updates on messages for this chat
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('chat_id', chatId)
      .order('created_at', ascending: true)
      .map((event) {
         // Mark unread as read (User Schema uses is_read)
         final user = ref.read(currentUserProvider);
         if (user != null) {
            supabase.from('messages')
                .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
                .eq('chat_id', chatId)
                .neq('sender_id', user.id)
                .eq('is_read', false)
                .then((_) {});
         }
         return List<Map<String, dynamic>>.from(event);
      });
});

// ────────────────────────────────────────────────
// Project Chat Room Helper
// ────────────────────────────────────────────────
final projectChatProvider = FutureProvider.family<String?, String>((ref, projectId) async {
  final supabase = ref.read(supabaseProvider);
  final res = await supabase.from('chats').select('id').eq('project_id', projectId).maybeSingle();
  return res?['id']?.toString();
});

