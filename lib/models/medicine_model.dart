class MedicineModel {
  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final int stock;
  final String? notes;

  /// Deprecated source field from old records.
  final int? legacyFrequency;

  const MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.stock,
    this.notes,
    this.legacyFrequency,
  });

  /// Always derived.
  int get frequency => times.length;

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    final rawTimes = json['times'];
    final parsedTimes = (rawTimes is List)
        ? rawTimes.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return MedicineModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      dosage: (json['dosage'] ?? '').toString(),
      times: parsedTimes,
      stock: int.tryParse((json['stock'] ?? 0).toString()) ?? 0,
      notes: json['notes']?.toString(),
      legacyFrequency: int.tryParse((json['frequency'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson({bool includeDeprecatedFrequency = false}) {
    final data = <String, dynamic>{
      'name': name,
      'dosage': dosage,
      'times': times,
      'stock': stock,
      if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
    };

    // Optional bridge for older backend behavior (if ever needed).
    if (includeDeprecatedFrequency) {
      data['frequency'] = frequency;
    }
    return data;
  }
}
