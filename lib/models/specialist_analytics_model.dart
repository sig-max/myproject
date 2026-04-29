class SpecialistAnalyticsModel {
  const SpecialistAnalyticsModel({
    required this.summary,
    required this.lineChart,
    required this.monthlyBreakdown,
    required this.yearlyBreakdown,
  });

  final Map<String, int> summary;
  final List<SpecialistProgressPoint> lineChart;
  final Map<String, int> monthlyBreakdown;
  final Map<String, int> yearlyBreakdown;

  factory SpecialistAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return SpecialistAnalyticsModel(
      summary: _intMap(json['summary']),
      lineChart: json['line_chart'] is List
          ? (json['line_chart'] as List)
              .whereType<Map>()
              .map(
                (item) => SpecialistProgressPoint.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      monthlyBreakdown: _intMap(json['monthly_breakdown']),
      yearlyBreakdown: _intMap(json['yearly_breakdown']),
    );
  }
}

class SpecialistProgressPoint {
  const SpecialistProgressPoint({
    required this.label,
    required this.appointments,
    required this.followUps,
    required this.testsCompleted,
    required this.progressScore,
  });

  final String label;
  final int appointments;
  final int followUps;
  final int testsCompleted;
  final int progressScore;

  factory SpecialistProgressPoint.fromJson(Map<String, dynamic> json) {
    return SpecialistProgressPoint(
      label: (json['label'] ?? '').toString(),
      appointments: _toInt(json['appointments']),
      followUps: _toInt(json['follow_ups']),
      testsCompleted: _toInt(json['tests_completed']),
      progressScore: _toInt(json['progress_score']),
    );
  }
}

Map<String, int> _intMap(dynamic value) {
  if (value is! Map) {
    return const {};
  }
  return value.map(
    (key, item) => MapEntry(key.toString(), _toInt(item)),
  );
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
