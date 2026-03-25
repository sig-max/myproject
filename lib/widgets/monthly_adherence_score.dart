import 'package:flutter/material.dart';

class MonthlyAdherenceScore extends StatelessWidget {
  const MonthlyAdherenceScore({
    super.key,
    required this.percentage,
  });

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final value = (percentage / 100).clamp(0, 1);
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 60
            ? Colors.orange
            : Colors.red;
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
                Icon(Icons.donut_large, color: color),
                const SizedBox(width: 8),
                const Text('Monthly Adherence'),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                tween: Tween(begin: 0, end: value.toDouble()),
                builder: (context, animatedValue, _) {
                  return SizedBox(
                    height: 150,
                    width: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: animatedValue,
                          strokeWidth: 12,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.18),
                        ),
                        Center(
                          child: Text(
                            '${(animatedValue * 100).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
