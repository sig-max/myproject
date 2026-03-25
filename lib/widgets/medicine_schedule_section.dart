import 'package:flutter/material.dart';

class ScheduleEntry {
  const ScheduleEntry({
    required this.medicineName,
    required this.dosage,
    required this.timeLabel,
  });

  final String medicineName;
  final String dosage;
  final String timeLabel;
}

class MedicineScheduleSection extends StatelessWidget {
  const MedicineScheduleSection({
    super.key,
    required this.groupedSchedule,
  });

  final Map<String, List<ScheduleEntry>> groupedSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const groups = ['Morning', 'Afternoon', 'Evening', 'Night'];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Daily Medicine Schedule',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...groups.map((group) {
              final entries = groupedSchedule[group] ?? const <ScheduleEntry>[];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        Text(
                          'No medicines',
                          style: theme.textTheme.bodySmall,
                        )
                      else
                        ...entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.medication, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${entry.medicineName} • ${entry.dosage}',
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.timeLabel,
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
