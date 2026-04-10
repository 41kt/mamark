import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/chat_controller.dart';
import '../../domain/entities/message_entity.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  ChatController? _controller;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String _chatTitle = 'المحادثة';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      
      if (args == null) {
        Get.back();
        Get.snackbar('خطأ', 'لا توجد بيانات المحادثة');
        return;
      }
      
      final orderId = args['orderId'] as String?;
      final isSupplier = args['isSupplier'] as bool? ?? false;
      
      if (orderId == null || orderId.isEmpty) {
        Get.back();
        Get.snackbar('خطأ', 'رقم الطلب غير صحيح');
        return;
      }

      setState(() {
        _chatTitle = isSupplier ? 'الدردشة مع المشتري' : 'الدردشة مع المورد';
      });

      final controller = buildChatController(orderId);
      setState(() => _controller = controller);

      ever(controller.messages, (_) => _scrollToBottom());
    } catch (e) {
      debugPrint('ChatView init error: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل المحادثة: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_chatTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chatTitle,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '🔒 محادثة آمنة ومشفرة',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              final msgs = _controller!.messages;
              if (msgs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد رسائل بعد.\nابدأ المحادثة الآن!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: msgs.length,
                itemBuilder: (ctx, i) {
                  final msg = msgs[i];
                  final isMine = msg.senderId == currentUserId;
                  return _MessageBubble(
                    message: msg,
                    isMine: isMine,
                    theme: theme,
                  );
                },
              );
            }),
          ),

          // Input bar
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) => _send(),
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => InkWell(
              onTap: _controller!.isSending.value ? null : _send,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _controller!.isSending.value ? Colors.grey : const Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                ),
                child: _controller!.isSending.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _controller?.send(text);
    _textController.clear();
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;
  final ThemeData theme;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF1E3A8A) : Colors.grey.shade100,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(18),
            topEnd: const Radius.circular(18),
            bottomStart: isMine ? const Radius.circular(18) : const Radius.circular(4),
            bottomEnd: isMine ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: GoogleFonts.cairo(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: GoogleFonts.cairo(
                color: isMine ? Colors.white.withValues(alpha: 0.7) : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
