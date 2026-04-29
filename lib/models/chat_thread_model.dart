import '../utils/api_datetime.dart';

class ChatThreadModel {
  const ChatThreadModel({
    required this.id,
    required this.patientUserId,
    required this.specialistUserId,
    required this.lastMessageText,
    required this.updatedAt,
    this.patientName,
    this.specialistName,
  });

  final String id;
  final String patientUserId;
  final String specialistUserId;
  final String lastMessageText;
  final DateTime updatedAt;
  final String? patientName;
  final String? specialistName;

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: (json['id'] ?? '').toString(),
      patientUserId: (json['patient_user_id'] ?? '').toString(),
      specialistUserId: (json['specialist_user_id'] ?? '').toString(),
      lastMessageText: (json['last_message_text'] ?? '').toString(),
      updatedAt: parseApiDateTime(json['updated_at']),
      patientName: json['patient_name']?.toString(),
      specialistName: json['specialist_name']?.toString(),
    );
  }
}
