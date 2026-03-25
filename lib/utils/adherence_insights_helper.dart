import '../models/checklist_model.dart';
import '../models/medicine_model.dart';

class BestWeekResult {
  const BestWeekResult({
    required this.weekLabel,
    required this.percentage,
    required this.hasData,
  });

  final String weekLabel;
  final double percentage;
  final bool hasData;
}

int calculateStreak({
  required List<ChecklistModel> checklistItems,
  required List<MedicineModel> medicines,
  DateTime? now,
}) {
  final reference = _dateOnly(now ?? DateTime.now());
  final daily = _buildDailyCounts(checklistItems, reference: reference);

  if (daily.isEmpty || medicines.isEmpty) {
    return 0;
  }

  int streak = 0;
  var cursor = reference;

  while (true) {
    final counts = daily[cursor];
    if (counts == null || counts.total == 0 || counts.completed < counts.total) {
      break;
    }
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}

double calculateMonthlyAdherence({
  required List<ChecklistModel> checklistItems,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final daily = _buildDailyCounts(checklistItems, reference: reference);

  double completed = 0;
  double total = 0;

  for (final entry in daily.entries) {
    final day = entry.key;
    if (day.year == reference.year && day.month == reference.month) {
      completed += entry.value.completed;
      total += entry.value.total;
    }
  }

  if (total == 0) {
    return 0;
  }
  return (completed / total) * 100;
}

BestWeekResult calculateBestWeek({
  required List<ChecklistModel> checklistItems,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final daily = _buildDailyCounts(checklistItems, reference: reference);

  final weekly = <int, _DayCounts>{};

  for (final entry in daily.entries) {
    final day = entry.key;
    if (day.year != reference.year || day.month != reference.month) {
      continue;
    }

    final week = ((day.day - 1) ~/ 7) + 1;
    final current = weekly[week] ?? const _DayCounts(completed: 0, total: 0);
    weekly[week] = _DayCounts(
      completed: current.completed + entry.value.completed,
      total: current.total + entry.value.total,
    );
  }

  if (weekly.isEmpty) {
    return const BestWeekResult(
      weekLabel: 'Week -',
      percentage: 0,
      hasData: false,
    );
  }

  int bestWeek = 1;
  double bestPct = -1;

  for (final entry in weekly.entries) {
    final totals = entry.value;
    if (totals.total == 0) {
      continue;
    }
    final pct = (totals.completed / totals.total) * 100;
    if (pct > bestPct) {
      bestPct = pct;
      bestWeek = entry.key;
    }
  }

  if (bestPct < 0) {
    return const BestWeekResult(
      weekLabel: 'Week -',
      percentage: 0,
      hasData: false,
    );
  }

  return BestWeekResult(
    weekLabel: 'Week $bestWeek',
    percentage: bestPct,
    hasData: true,
  );
}

List<DateTime> findMissedDays({
  required List<ChecklistModel> checklistItems,
  int limit = 5,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final daily = _buildDailyCounts(checklistItems, reference: reference);

  final missed = daily.entries
      .where(
        (entry) =>
            entry.key.year == reference.year &&
            entry.key.month == reference.month &&
            entry.value.total > 0 &&
            entry.value.completed == 0,
      )
      .map((entry) => entry.key)
      .toList()
    ..sort((a, b) => b.compareTo(a));

  return missed.take(limit).toList();
}

Map<DateTime, _DayCounts> _buildDailyCounts(
  List<ChecklistModel> items, {
  required DateTime reference,
}) {
  final byDay = <DateTime, _DayCounts>{};

  for (final item in items) {
    final parsed = _resolveChecklistDate(item, reference);
    final day = _dateOnly(parsed);

    final current = byDay[day] ?? const _DayCounts(completed: 0, total: 0);
    byDay[day] = _DayCounts(
      completed: current.completed + (item.taken ? 1 : 0),
      total: current.total + 1,
    );
  }

  return byDay;
}

DateTime _resolveChecklistDate(ChecklistModel item, DateTime fallback) {
  final raw = item.scheduledTime?.trim();
  if (raw == null || raw.isEmpty) {
    return fallback;
  }

  final direct = DateTime.tryParse(raw);
  if (direct != null) {
    return direct;
  }

  final normalized = raw.toUpperCase();
  final twelveHour = RegExp(r'^(\d{1,2}):(\d{2})\s?(AM|PM)$').firstMatch(normalized);
  if (twelveHour != null) {
    var hour = int.tryParse(twelveHour.group(1) ?? '') ?? fallback.hour;
    final minute = int.tryParse(twelveHour.group(2) ?? '') ?? fallback.minute;
    final period = twelveHour.group(3) ?? 'AM';
    if (period == 'PM' && hour < 12) {
      hour += 12;
    }
    if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    return DateTime(fallback.year, fallback.month, fallback.day, hour, minute);
  }

  final hhmm = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
  if (hhmm != null) {
    final hour = int.tryParse(hhmm.group(1) ?? '') ?? fallback.hour;
    final minute = int.tryParse(hhmm.group(2) ?? '') ?? fallback.minute;
    return DateTime(fallback.year, fallback.month, fallback.day, hour, minute);
  }

  return fallback;
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

class _DayCounts {
  const _DayCounts({required this.completed, required this.total});

  final int completed;
  final int total;
}
