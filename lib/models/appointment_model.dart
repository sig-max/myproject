import '../utils/api_datetime.dart';

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
    this.autoAcceptAt,
    this.acceptedAt,
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
  final DateTime? autoAcceptAt;
  final DateTime? acceptedAt;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final slot = json['slot'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['slot'])
        : <String, dynamic>{};

    return AppointmentModel(
      id: (json['id'] ?? '').toString(),
      slotId: (json['slot_id'] ?? '').toString(),
      patientUserId: (json['patient_user_id'] ?? '').toString(),
      specialistUserId: (json['specialist_user_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt: parseApiDateTime(json['created_at']),
      patientName: json['patient_name']?.toString(),
      specialistName: json['specialist_name']?.toString(),
      slotStartAt: slot['start_at'] != null
          ? parseApiDateTime(slot['start_at'])
          : null,
      slotEndAt: slot['end_at'] != null
          ? parseApiDateTime(slot['end_at'])
          : null,
      autoAcceptAt: json['auto_accept_at'] != null
          ? parseApiDateTime(json['auto_accept_at'])
          : null,
      acceptedAt: json['accepted_at'] != null
          ? parseApiDateTime(json['accepted_at'])
          : null,
    );
  }
}
