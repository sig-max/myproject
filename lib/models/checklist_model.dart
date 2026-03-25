class ChecklistModel {
  final String medicineId;
  final String medicineName;
  final bool taken;
  final String? scheduledTime;
  final String? logId;

  const ChecklistModel({
    required this.medicineId,
    required this.medicineName,
    required this.taken,
    this.scheduledTime,
    this.logId,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    final medicine = json['medicine'];
    return ChecklistModel(
      medicineId: (json['medicine_id'] ??
              json['medicineId'] ??
              medicine?['_id'] ??
              medicine?['id'] ??
              '')
          .toString(),
      medicineName: (json['medicine_name'] ??
              json['medicineName'] ??
              medicine?['name'] ??
              'Medicine')
          .toString(),
      taken: json['taken'] == true || json['is_taken'] == true,
      scheduledTime: json['scheduled_time']?.toString() ??
          json['time']?.toString() ??
          json['scheduledTime']?.toString(),
      logId: (json['_id'] ?? json['id'])?.toString(),
    );
  }

  ChecklistModel copyWith({
    String? medicineId,
    String? medicineName,
    bool? taken,
    String? scheduledTime,
    String? logId,
  }) {
    return ChecklistModel(
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      taken: taken ?? this.taken,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      logId: logId ?? this.logId,
    );
  }
}
