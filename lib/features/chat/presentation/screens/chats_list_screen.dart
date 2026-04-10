import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/chat_providers.dart';

class ChatsListScreen extends ConsumerStatefulWidget {
  const ChatsListScreen({super.key});

  @override
  ConsumerState<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends ConsumerState<ChatsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("المحادثات", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "الكل"),
            Tab(text: "غير مقروءة"),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return _buildEmptyState();
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildChatsList(chats, user?.id, false), // All
              _buildChatsList(chats, user?.id, true),  // Unread only
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text("خطأ: $e", style: GoogleFonts.cairo())),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("لا توجد محادثات حالياً", style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChatsList(List<Map<String, dynamic>> chats, String? currentUserId, bool unreadOnly) {
    var filteredChats = chats;
    if (unreadOnly) {
      filteredChats = chats.where((c) {
        final isUser1 = c['user1_id'] == currentUserId;
        final count = isUser1 ? (c['user1_unread_count'] ?? 0) : (c['user2_unread_count'] ?? 0);
        return count > 0;
      }).toList();
    }

    if (filteredChats.isEmpty) {
      return Center(
        child: Text(
          unreadOnly ? "لا توجد رسائل غير مقروءة" : "لا توجد محادثات",
          style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredChats.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        final isUser1 = chat['user1_id'] == currentUserId;
        final unreadCount = isUser1 ? (chat['user1_unread_count'] ?? 0) : (chat['user2_unread_count'] ?? 0);
        
        final otherUser = isUser1 ? chat['profiles2'] : chat['profiles1'];
        final otherUserId = isUser1 ? chat['user2_id'] : chat['user1_id'];
        final name = otherUser?['display_name'] ?? otherUser?['user_name'] ?? otherUser?['full_name'] ?? otherUser?['name'] ?? 'مستخدم';
        final avatar = otherUser?['avatar_url'] ?? otherUser?['profile_picture'] ?? otherUser?['profile_image_url'];
        
        final projectTitle = chat['project']?['title'] ?? 'محادثة خاصة';
        final lastMessage = chat['last_message'] ?? 'لا توجد رسائل';
        final time = _formatTime(chat['last_message_at'] ?? chat['updated_at']);

        return InkWell(
          onTap: () => Get.toNamed('/chat-details/${chat['id']}', arguments: {
            'id': chat['id'], 
            'name': name, 
            'otherUserId': otherUserId,
            'projectTitle': projectTitle,
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: unreadCount > 0 ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null ? const Icon(Icons.person, color: AppColors.primary, size: 30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: GoogleFonts.cairo(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600, fontSize: 16)),
                          Text(time, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        projectTitle, 
                        style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Badge(
                              label: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              backgroundColor: AppColors.accent,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "الآن";
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
      }
      return "${dt.year}-${dt.month}-${dt.day}";
    } catch (_) {
      return "الآن";
    }
  }
}

