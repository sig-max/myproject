import 'package:flutter/material.dart';

class HealthTaskProgress extends StatelessWidget {
  const HealthTaskProgress({
    super.key,
    required this.completed,
    required this.pending,
  });

  final int completed;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = completed + pending;
    final progress = total == 0 ? 0.0 : completed / total;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Today's Health Tasks",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$completed completed • $pending pending',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 850),
              tween: Tween(begin: 0, end: progress),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
