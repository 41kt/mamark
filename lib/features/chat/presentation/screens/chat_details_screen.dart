import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/chat_providers.dart';

class ChatDetailsScreen extends ConsumerStatefulWidget {
  final String chatId;
  final Map<String, dynamic>? chatData;
  const ChatDetailsScreen({super.key, required this.chatId, this.chatData});

  @override
  ConsumerState<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends ConsumerState<ChatDetailsScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && !_isSending) return;
    
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repo = ref.read(chatRepositoryProvider);

    try {
      setState(() => _isSending = true);
      await repo.sendMessage(
        chatId: widget.chatId,
        senderId: user.id,
        text: text,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الإرسال: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _pickAndSendImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    _handleAttachmentUpload(bytes, image.name, image.mimeType ?? 'image/jpeg');
  }

  void _pickAndSendFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    if (res == null || res.files.isEmpty) return;

    final file = res.files.first;
    if (file.bytes == null) return;

    _handleAttachmentUpload(file.bytes!, file.name, 'application/octet-stream');
  }

  void _handleAttachmentUpload(Uint8List bytes, String name, String mime) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(chatRepositoryProvider);

    try {
      setState(() => _isSending = true);
      final metadata = await repo.uploadFile(
        chatId: widget.chatId,
        bytes: bytes,
        fileName: name,
        mimeType: mime,
      );

      await repo.sendMessage(
        chatId: widget.chatId,
        senderId: user.id,
        attachments: [metadata],
      );
      
      _scrollToBottom();
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في رفع الملف: $e")));
    } finally {
       if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = ref.watch(chatMessagesStreamProvider(widget.chatId));
    final currentUser = ref.watch(currentUserProvider);
    
    final name = widget.chatData?['name'] ?? "المحادثة";
    final projectTitle = widget.chatData?['projectTitle'] ?? "مشروع";

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(projectTitle, style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Expanded(
            child: messagesStream.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState();
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == currentUser?.id;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text("خطأ: $e", style: GoogleFonts.cairo())),
            ),
          ),
          
          if (_isSending) 
            const LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.white, valueColor: AlwaysStoppedAnimation(AppColors.primary)),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text("ابدأ المراسلة الآن", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildAttachButton(),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "اكتب رسالة...",
                  hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF3F5F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _isSending ? Colors.grey : AppColors.primary,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachButton() {
    return IconButton(
      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("إرفاق ملف", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _attachOption(Icons.image, "الاستوديو", Colors.deepPurple, () {
                       Navigator.pop(ctx);
                       _pickAndSendImage(ImageSource.gallery);
                    }),
                    _attachOption(Icons.camera_alt, "الكاميرا", Colors.orange, () {
                       Navigator.pop(ctx);
                       _pickAndSendImage(ImageSource.camera);
                    }),
                    _attachOption(Icons.insert_drive_file, "ملف", Colors.blue, () {
                       Navigator.pop(ctx);
                       _pickAndSendFile();
                    }),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // User Schema uses message_text and attachment_url
    final text = message['message_text'] ?? '';
    final attachmentUrl = message['attachment_url'];
    final attachmentName = message['attachment_name'] ?? 'ملف';
    final type = message['message_type'] ?? 'text';
    final time = _formatTime(message['created_at']);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (attachmentUrl != null)
                    _buildAttachment(context, attachmentUrl, attachmentName, type),
                  
                  if (text.isNotEmpty && (attachmentUrl == null || text != 'أرسل مرفقاً'))
                    Text(
                      text,
                      style: GoogleFonts.cairo(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(message['is_read'] == true ? Icons.done_all : Icons.done, size: 12, color: message['is_read'] == true ? Colors.blue : Colors.grey),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, String url, String name, String type) {
    final isImage = type == 'image';
    return InkWell(
      onTap: () {
         // View or Download
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url, fit: BoxFit.cover, height: 150, width: double.infinity),
              )
            : Row(
                children: [
                  Icon(Icons.insert_drive_file, color: isMe ? Colors.white : AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.cairo(fontSize: 12, color: isMe ? Colors.white : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.download, size: 18, color: Colors.grey),
                ],
              ),
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return "الآن";
    try {
      final dt = DateTime.parse(ts.toString());
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "الآن";
    }
  }
}

