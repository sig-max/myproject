class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.slotId,
    required this.patientUserId,
    required this.specialistUserId,
    required this.status,
    required this.notes,
    required this.createdAt,
    this.patientName,
    this.specialistName,
    this.slotStartAt,
    this.slotEndAt,
  });

  final String id;
  final String slotId;
  final String patientUserId;
  final String specialistUserId;
  final String status;
  final String notes;
  final DateTime createdAt;
  final String? patientName;
  final String? specialistName;
  final DateTime? slotStartAt;
  final DateTime? slotEndAt;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final slot = json['slot'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['slot'])
        : <String, dynamic>{};

    return AppointmentModel(
      id: (json['id'] ?? '').toString(),
      slotId: (json['slot_id'] ?? '').toString(),
      patientUserId: (json['patient_user_id'] ?? '').toString(),
      specialistUserId: (json['specialist_user_id'] ?? '').toString(),
      status: (json['status'] ?? 'booked').toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt: DateTime.parse((json['created_at'] ?? '').toString()).toLocal(),
      patientName: json['patient_name']?.toString(),
      specialistName: json['specialist_name']?.toString(),
      slotStartAt: slot['start_at'] != null
          ? DateTime.parse(slot['start_at'].toString()).toLocal()
          : null,
      slotEndAt: slot['end_at'] != null
          ? DateTime.parse(slot['end_at'].toString()).toLocal()
          : null,
    );
  }
}
