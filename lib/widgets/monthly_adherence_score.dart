import 'package:flutter/material.dart';

class MonthlyAdherenceScore extends StatelessWidget {
  const MonthlyAdherenceScore({
    super.key,
    required this.percentage,
  });

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = (percentage / 100).clamp(0.0, 1.0);
    final scoreColor = percentage >= 80
        ? const Color(0xFF10B981) // green
        : percentage >= 60
            ? const Color(0xFFF59E0B) // amber
            : const Color(0xFFEF4444); // red

    final subtitle = percentage >= 80
        ? 'Excellent consistency'
        : percentage >= 60
            ? 'Good, room to improve'
            : 'Needs attention';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF2FBFA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF0EA5A4).withValues(alpha: 0.10),
        ),
      ),
      child: Stack(
        children: [
          // Subtle background visual
          Positioned(
            right: -14,
            top: -14,
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 86,
              color: const Color(0xFF0EA5A4).withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.donut_large_rounded, color: scoreColor),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly Adherence',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF12343B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF4B6B70),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: value),
                    builder: (context, animatedValue, _) {
                      final animatedPercent = (animatedValue * 100).round();

                      return Semantics(
                        label: 'Monthly adherence $animatedPercent percent',
                        child: SizedBox(
                          height: 154,
                          width: 154,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: animatedValue,
                                strokeWidth: 12,
                                strokeCap: StrokeCap.round,
                                color: scoreColor,
                                backgroundColor:
                                    scoreColor.withValues(alpha: 0.16),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$animatedPercent%',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF12343B),
                                      ),
                                    ),
                                    Text(
                                      'This month',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: const Color(0xFF4B6B70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
