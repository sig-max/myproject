import '../utils/api_datetime.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.senderRole,
    required this.messageText,
    required this.createdAt,
    required this.attachments,
    this.senderName,
  });

  final String id;
  final String threadId;
  final String senderUserId;
  final String senderRole;
  final String messageText;
  final DateTime createdAt;
  final List<Map<String, dynamic>> attachments;
  final String? senderName;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] ?? '').toString(),
      threadId: (json['thread_id'] ?? '').toString(),
      senderUserId: (json['sender_user_id'] ?? '').toString(),
      senderRole: (json['sender_role'] ?? '').toString(),
      messageText: (json['message_text'] ?? '').toString(),
      createdAt: parseApiDateTime(json['created_at']),
      attachments: json['attachments'] is List
          ? (json['attachments'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : const [],
      senderName: json['sender_name']?.toString(),
    );
  }
}
