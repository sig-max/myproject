import 'package:flutter/material.dart';

class ChecklistProgressCard extends StatelessWidget {
  const ChecklistProgressCard({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF2FBFA)],
        ),
        border: Border.all(color: const Color(0xFF0EA5A4).withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Completion', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2EEEF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF0EA5A4)),
            ),
          ),
          const SizedBox(height: 6),
          Text('$completed of $total completed'),
        ],
      ),
    );
  }
}