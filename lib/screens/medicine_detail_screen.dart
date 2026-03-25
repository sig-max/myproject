import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/medicine_reminder_scheduler.dart';
import 'add_medicine_screen.dart';

class MedicineDetailScreen extends StatefulWidget {
  const MedicineDetailScreen({super.key, required this.medicine});

  final MedicineModel medicine;

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  bool? _reminderEnabled;
  bool _updatingReminder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final enabled =
          await MedicineReminderScheduler.isReminderEnabled(widget.medicine.id);
      if (!mounted) {
        return;
      }
      setState(() => _reminderEnabled = enabled);
    });
  }

  Future<void> _delete() async {
    final pageContext = context;
    final navigator = Navigator.of(pageContext);
    final messenger = ScaffoldMessenger.of(pageContext);
    final provider = pageContext.read<MedicineProvider>();

    final ok = await showDialog<bool>(
      context: pageContext,
      builder: (_) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) {
      return;
    }

    final success = await provider.deleteMedicine(widget.medicine.id);

    if (!mounted) {
      return;
    }

    if (success) {
      await MedicineReminderScheduler.cancelForMedicine(widget.medicine);
      navigator.pop();
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Delete failed')),
    );
  }

  Future<void> _toggleReminder(bool enabled) async {
    setState(() => _updatingReminder = true);
    await MedicineReminderScheduler.setReminderEnabled(
      medicineId: widget.medicine.id,
      enabled: enabled,
    );

    if (enabled) {
      await MedicineReminderScheduler.scheduleForMedicine(widget.medicine);
    } else {
      await MedicineReminderScheduler.cancelForMedicine(widget.medicine);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _reminderEnabled = enabled;
      _updatingReminder = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.medicine.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Dosage: ${widget.medicine.dosage}'),
                  Text('Frequency: ${widget.medicine.frequency}'),
                  Text('Stock: ${widget.medicine.stock}'),
                  Text('Times: ${widget.medicine.times.join(', ')}'),
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${(widget.medicine.notes ?? '').isEmpty ? '-' : widget.medicine.notes}',
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    value: _reminderEnabled ?? false,
                    onChanged: _updatingReminder || _reminderEnabled == null
                        ? null
                        : _toggleReminder,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Medicine Reminder'),
                    subtitle: const Text('Enable daily reminder notifications'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final provider = context.read<MedicineProvider>();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddMedicineScreen(initialMedicine: widget.medicine),
                ),
              );
              if (mounted) {
                await provider.fetchMedicines();
                await MedicineReminderScheduler.scheduleForProvider(
                  provider,
                );
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
