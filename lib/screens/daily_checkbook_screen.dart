import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/checklist_provider.dart';
import '../widgets/checklist_item.dart';

class DailyCheckbookScreen extends StatelessWidget {
  const DailyCheckbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();

    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.items.isEmpty) {
      return Center(child: Text(provider.error!));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ChecklistProvider>().fetchTodayChecklist(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Consistency',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: provider.progress),
                  const SizedBox(height: 6),
                  Text(
                    '${(provider.progress * 100).toStringAsFixed(0)}% completed',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (provider.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: Text('No checklist for today')),
            )
          else
            ...provider.items.map(
              (item) => ChecklistItem(
                item: item,
                onMarkTaken: () async {
                  final success =
                      await context.read<ChecklistProvider>().markAsTaken(item.medicineId);
                  if (!context.mounted || success) {
                    return;
                  }
                  final message =
                      context.read<ChecklistProvider>().error ?? 'Unable to update';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
