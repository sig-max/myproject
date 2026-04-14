import 'package:flutter/material.dart';

class DashboardActionButtons extends StatelessWidget {
  const DashboardActionButtons({
    super.key,
    required this.onAddMedicine,
    required this.onAddExpense,
    required this.onAddChecklistTask,
    this.onFindSpecialist,
  });

  final VoidCallback onAddMedicine;
  final VoidCallback onAddExpense;
  final VoidCallback onAddChecklistTask;
  final VoidCallback? onFindSpecialist;

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
                Icon(Icons.flash_on, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onAddMedicine,
                  icon: const Icon(Icons.medication_outlined),
                  label: const Text('Add Medicine'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAddExpense,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Add Expense'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddChecklistTask,
                  icon: const Icon(Icons.checklist_outlined),
                  label: const Text('Add Checklist Task'),
                ),
                if (onFindSpecialist != null)
                  OutlinedButton.icon(
                    onPressed: onFindSpecialist,
                    icon: const Icon(Icons.person_search_outlined),
                    label: const Text('Find Specialist'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
