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
      startAt: DateTime.parse((json['start_at'] ?? '').toString()).toLocal(),
      endAt: DateTime.parse((json['end_at'] ?? '').toString()).toLocal(),
      isBooked: json['is_booked'] == true,
    );
  }
}
