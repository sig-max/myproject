import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MissedDoseAlert extends StatelessWidget {
  const MissedDoseAlert({super.key, required this.missedDays});

  final List<DateTime> missedDays;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM d');
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Missed Medicines',
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (missedDays.isEmpty)
              Text(
                'No fully missed medicine days recently.',
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              Text(
                'You missed medicines on:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              ...missedDays.map(
                (day) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${formatter.format(day)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
