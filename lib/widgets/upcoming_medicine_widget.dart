import 'package:flutter/material.dart';

class UpcomingDose {
  const UpcomingDose({
    required this.medicineName,
    required this.dosage,
    required this.scheduledAt,
    required this.displayTime,
  });

  final String medicineName;
  final String dosage;
  final DateTime scheduledAt;
  final String displayTime;
}

class UpcomingMedicineWidget extends StatelessWidget {
  const UpcomingMedicineWidget({
    super.key,
    required this.upcomingMedicines,
    required this.now,
  });

  final List<UpcomingDose> upcomingMedicines;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Medicines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (upcomingMedicines.isEmpty)
              Text(
                'No upcoming medicines in the next few hours.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...upcomingMedicines.map((dose) {
                final countdown = dose.scheduledAt.difference(now);
                final minutes = countdown.inMinutes;
                final hours = (minutes / 60).floor();
                final remainingMinutes = minutes % 60;

                final countdownText = hours > 0
                    ? 'Next dose in ${hours}h ${remainingMinutes}m'
                    : 'Next dose in ${remainingMinutes}m';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.medication)),
                  title: Text(
                    '${dose.medicineName} • ${dose.dosage}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${dose.displayTime} • $countdownText'),
                );
              }),
          ],
        ),
      ),
    );
  }
}
