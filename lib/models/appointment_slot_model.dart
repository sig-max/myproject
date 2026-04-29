import '../utils/api_datetime.dart';

class AppointmentSlotModel {
  const AppointmentSlotModel({
    required this.id,
    required this.specialistUserId,
    required this.startAt,
    required this.endAt,
    required this.isBooked,
  });

  final String id;
  final String specialistUserId;
  final DateTime startAt;
  final DateTime endAt;
  final bool isBooked;

  factory AppointmentSlotModel.fromJson(Map<String, dynamic> json) {
    return AppointmentSlotModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      specialistUserId: (json['specialist_user_id'] ?? '').toString(),
      startAt: parseApiDateTime(json['start_at']),
      endAt: parseApiDateTime(json['end_at']),
      isBooked: json['is_booked'] == true,
    );
  }
}
