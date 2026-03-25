import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/medicine_reminder_scheduler.dart';

class NextMedicineReminderCard extends StatelessWidget {
  const NextMedicineReminderCard({
    super.key,
    required this.nextReminder,
  });

  final NextMedicineReminder? nextReminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: nextReminder == null
            ? Row(
                children: [
                  Icon(Icons.alarm_off, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('No upcoming medicine reminders'),
                  ),
                ],
              )
            : _ReminderBody(nextReminder: nextReminder!),
      ),
    );
  }
}

class _ReminderBody extends StatelessWidget {
  const _ReminderBody({required this.nextReminder});

  final NextMedicineReminder nextReminder;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = nextReminder.scheduledAt.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    final timeLeft = hours > 0 ? 'In ${hours}h ${minutes}m' : 'In ${minutes}m';
    final timeLabel = DateFormat.jm().format(nextReminder.scheduledAt);

    return Row(
      children: [
        Icon(Icons.alarm, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next Medicine',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                nextReminder.medicine.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$timeLeft • $timeLabel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
