import 'package:flutter/material.dart';
import '../models/checklist_model.dart';

class ChecklistItem extends StatelessWidget {
  const ChecklistItem({
    super.key,
    required this.item,
    required this.onMarkTaken,
  });

  final ChecklistModel item;
  final VoidCallback onMarkTaken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF2FBFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (item.taken ? const Color(0xFF10B981) : const Color(0xFF0EA5A4))
              .withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (item.taken ? const Color(0xFF10B981) : const Color(0xFF0EA5A4))
              .withOpacity(0.12),
          child: Icon(
            item.taken ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
            color: item.taken ? const Color(0xFF047857) : const Color(0xFF0F766E),
          ),
        ),
        title: Text(
          item.medicineName,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          item.scheduledTime == null ? 'No specific time' : 'Scheduled: ${item.scheduledTime}',
          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B6B70)),
        ),
        trailing: item.taken
            ? const Text('Taken')
            : FilledButton.tonalIcon(
                onPressed: onMarkTaken,
                icon: const Icon(Icons.done_rounded, size: 18),
                label: const Text('Mark'),
              ),
      ),
    );
  }
}
