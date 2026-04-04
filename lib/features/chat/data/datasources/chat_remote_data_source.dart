import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> streamMessages(String orderId);
  Future<void> sendMessage(MessageModel message);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient supabase;
  ChatRemoteDataSourceImpl(this.supabase);

  @override
  Stream<List<MessageModel>> streamMessages(String orderId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at')
        .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    await supabase.from('messages').insert(message.toJson());
  }
}
