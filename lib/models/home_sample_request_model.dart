import '../utils/api_datetime.dart';

class HomeSampleRequestModel {
  const HomeSampleRequestModel({
    required this.id,
    required this.patientUserId,
    required this.testName,
    required this.preferredDate,
    required this.preferredTime,
    required this.address,
    required this.city,
    required this.phone,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.specialistUserId,
    this.patientName,
    this.specialistName,
  });

  final String id;
  final String patientUserId;
  final String? specialistUserId;
  final String testName;
  final String preferredDate;
  final String preferredTime;
  final String address;
  final String city;
  final String phone;
  final String notes;
  final String status;
  final DateTime createdAt;
  final String? patientName;
  final String? specialistName;

  factory HomeSampleRequestModel.fromJson(Map<String, dynamic> json) {
    return HomeSampleRequestModel(
      id: (json['id'] ?? '').toString(),
      patientUserId: (json['patient_user_id'] ?? '').toString(),
      specialistUserId: json['specialist_user_id']?.toString(),
      testName: (json['test_name'] ?? '').toString(),
      preferredDate: (json['preferred_date'] ?? '').toString(),
      preferredTime: (json['preferred_time'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: parseApiDateTime(json['created_at']),
      patientName: json['patient_name']?.toString(),
      specialistName: json['specialist_name']?.toString(),
    );
  }
}
