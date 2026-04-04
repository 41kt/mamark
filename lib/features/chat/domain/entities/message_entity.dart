class MessageEntity {
  final String id;
  final String orderId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });
}
