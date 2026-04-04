import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/message_entity.dart';
import 'dart:async';

class ChatController extends GetxController {
  final ChatRemoteDataSource _dataSource;
  final String orderId;
  final String currentUserId;

  ChatController({
    required ChatRemoteDataSource dataSource,
    required this.orderId,
    required this.currentUserId,
  }) : _dataSource = dataSource;

  var messages = <MessageEntity>[].obs;
  var isSending = false.obs;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _dataSource.streamMessages(orderId).listen((msgs) {
      messages.assignAll(msgs);
    });
  }

  Future<void> send(String content) async {
    if (content.trim().isEmpty) return;
    isSending.value = true;
    final msg = MessageModel(
      id: '',
      orderId: orderId,
      senderId: currentUserId,
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await _dataSource.sendMessage(msg);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إرسال الرسالة: $e');
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

/// Build a fresh ChatController per chat screen
ChatController buildChatController(String orderId) {
  final supabase = Get.find<SupabaseClient>();
  final authCtrl = Get.find(); // AuthController
  return ChatController(
    dataSource: ChatRemoteDataSourceImpl(supabase),
    orderId: orderId,
    currentUserId: authCtrl.currentUser.value!.id,
  );
}
