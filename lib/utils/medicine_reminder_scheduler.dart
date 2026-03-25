import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checklist_model.dart';
import '../models/medicine_model.dart';
import '../providers/medicine_provider.dart';
import '../services/notification_service.dart';

class NextMedicineReminder {
  const NextMedicineReminder({
    required this.medicine,
    required this.scheduledAt,
  });

  final MedicineModel medicine;
  final DateTime scheduledAt;
}

class MedicineReminderScheduler {
  MedicineReminderScheduler._();

  static const String _disabledKey = 'disabled_medicine_reminder_ids';

  static Future<Set<String>> getDisabledReminderMedicineIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_disabledKey)?.toSet() ?? <String>{};
  }

  static Future<bool> isReminderEnabled(String medicineId) async {
    final disabled = await getDisabledReminderMedicineIds();
    return !disabled.contains(medicineId);
  }

  static Future<void> setReminderEnabled({
    required String medicineId,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final disabled = prefs.getStringList(_disabledKey)?.toSet() ?? <String>{};

    if (enabled) {
      disabled.remove(medicineId);
    } else {
      disabled.add(medicineId);
    }

    await prefs.setStringList(_disabledKey, disabled.toList());
  }

  static Future<void> scheduleForProvider(MedicineProvider provider) async {
    await scheduleForMedicines(provider.medicines);
  }

  static Future<void> scheduleForMedicines(List<MedicineModel> medicines) async {
    await NotificationService.instance.initialize();
    final disabled = await getDisabledReminderMedicineIds();

    for (final medicine in medicines) {
      await cancelForMedicine(medicine);
      if (disabled.contains(medicine.id)) {
        continue;
      }

      for (final time in medicine.times) {
        final parsed = _parseTime(time);
        if (parsed == null) {
          continue;
        }

        final id = _notificationId(medicine.id, time);
        await NotificationService.instance.scheduleDailyReminder(
          id: id,
          title: 'Medicine Reminder',
          body: 'Time to take ${medicine.name} (${medicine.dosage})',
          hour: parsed.hour,
          minute: parsed.minute,
          payload: 'medicine:${medicine.id}',
        );
      }
    }
  }

  static Future<void> scheduleForMedicine(MedicineModel medicine) async {
    final enabled = await isReminderEnabled(medicine.id);
    await cancelForMedicine(medicine);
    if (!enabled) {
      return;
    }

    for (final time in medicine.times) {
      final parsed = _parseTime(time);
      if (parsed == null) {
        continue;
      }
      final id = _notificationId(medicine.id, time);
      await NotificationService.instance.scheduleDailyReminder(
        id: id,
        title: 'Medicine Reminder',
        body: 'Time to take ${medicine.name} (${medicine.dosage})',
        hour: parsed.hour,
        minute: parsed.minute,
        payload: 'medicine:${medicine.id}',
      );
    }
  }

  static Future<void> cancelForMedicine(MedicineModel medicine) async {
    for (final time in medicine.times) {
      await NotificationService.instance
          .cancelReminder(_notificationId(medicine.id, time));
    }
  }

  static Future<void> checkMissedMedicines({
    required List<MedicineModel> medicines,
    required List<ChecklistModel> checklistItems,
  }) async {
    final now = DateTime.now();
    final disabled = await getDisabledReminderMedicineIds();
    final takenMedicineIds = checklistItems
        .where((item) => item.taken)
        .map((item) => item.medicineId)
        .toSet();

    for (final medicine in medicines) {
      if (disabled.contains(medicine.id) || takenMedicineIds.contains(medicine.id)) {
        continue;
      }

      for (final time in medicine.times) {
        final parsed = _parseTime(time);
        if (parsed == null) {
          continue;
        }

        final scheduled = DateTime(
          now.year,
          now.month,
          now.day,
          parsed.hour,
          parsed.minute,
        );

        if (now.isAfter(scheduled)) {
          await NotificationService.instance.showMissedDoseNotification(
            id: _missedDoseNotificationId(medicine.id, time),
            title: 'Missed Medicine Reminder',
            body: 'You may have missed ${medicine.name} (${medicine.dosage})',
            payload: 'missed:${medicine.id}',
          );
          break;
        }
      }
    }
  }

  static Future<NextMedicineReminder?> nextUpcomingMedicine(
    List<MedicineModel> medicines,
  ) async {
    final disabled = await getDisabledReminderMedicineIds();
    final now = DateTime.now();

    NextMedicineReminder? nearest;
    for (final medicine in medicines) {
      if (disabled.contains(medicine.id)) {
        continue;
      }

      for (final time in medicine.times) {
        final parsed = _parseTime(time);
        if (parsed == null) {
          continue;
        }

        var scheduled = DateTime(
          now.year,
          now.month,
          now.day,
          parsed.hour,
          parsed.minute,
        );

        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        if (nearest == null || scheduled.isBefore(nearest.scheduledAt)) {
          nearest = NextMedicineReminder(
            medicine: medicine,
            scheduledAt: scheduled,
          );
        }
      }
    }

    return nearest;
  }

  static DateTime? _parseTime(String raw) {
    final input = raw.trim();
    final formats = [
      DateFormat('HH:mm'),
      DateFormat('H:mm'),
      DateFormat('hh:mm a'),
      DateFormat('h:mm a'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(input.toUpperCase());
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static int _notificationId(String medicineId, String time) {
    final key = '$medicineId|$time';
    var hash = 17;
    for (final unit in key.codeUnits) {
      hash = 37 * hash + unit;
    }
    return hash.abs() % 2147483647;
  }

  static int _missedDoseNotificationId(String medicineId, String time) {
    return (_notificationId(medicineId, time) + 9000000) % 2147483647;
  }
}
