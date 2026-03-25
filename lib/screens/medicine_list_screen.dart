import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_provider.dart';
import '../services/notification_service.dart';
import '../utils/medicine_reminder_scheduler.dart';
import '../widgets/medicine_card.dart';
import '../widgets/next_medicine_reminder_card.dart';
import 'add_medicine_screen.dart';
import 'medicine_detail_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  Future<void>? _startupFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startupFuture = _initializeReminders();
      setState(() {});
    });
  }

  Future<void> _initializeReminders() async {
    final provider = context.read<MedicineProvider>();
    if (provider.medicines.isEmpty) {
      await provider.fetchMedicines();
    }
    await MedicineReminderScheduler.scheduleForProvider(provider);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();

    if (provider.isLoading && provider.medicines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.medicines.isEmpty) {
      return Center(child: Text(provider.error!));
    }

    return Scaffold(
      body: FutureBuilder(
        future: _startupFuture,
        builder: (context, _) {
          return FutureBuilder<Set<String>>(
            future: MedicineReminderScheduler.getDisabledReminderMedicineIds(),
            builder: (context, disabledSnapshot) {
              final disabled = disabledSnapshot.data ?? <String>{};

              return FutureBuilder<NextMedicineReminder?>(
                future: MedicineReminderScheduler.nextUpcomingMedicine(
                  provider.medicines,
                ),
                builder: (context, nextSnapshot) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      final medicineProvider = context.read<MedicineProvider>();
                      await medicineProvider.fetchMedicines();
                      await MedicineReminderScheduler.scheduleForProvider(medicineProvider);
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: provider.medicines.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 180),
                              Center(child: Text('No medicines added yet')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: provider.medicines.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return NextMedicineReminderCard(
                                  nextReminder: nextSnapshot.data,
                                );
                              }

                              final medicine = provider.medicines[index - 1];
                              final reminderActive =
                                  medicine.times.isNotEmpty &&
                                  !disabled.contains(medicine.id);

                              return MedicineCard(
                                medicine: medicine,
                                reminderActive: reminderActive,
                                onTap: () async {
                                  final medicineProvider =
                                      context.read<MedicineProvider>();
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MedicineDetailScreen(medicine: medicine),
                                    ),
                                  );

                                  if (!mounted) {
                                    return;
                                  }

                                  await medicineProvider.fetchMedicines();
                                  await MedicineReminderScheduler.scheduleForProvider(
                                    medicineProvider,
                                  );
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                              );
                            },
                          ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: kDebugMode
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'test-reminder-fab',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!NotificationService
                        .instance.supportsScheduledNotifications) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chrome web does not support scheduled local reminders. Use Android/iOS/Desktop build.',
                          ),
                        ),
                      );
                      return;
                    }

                    await NotificationService.instance.scheduleDebugNotification(
                      id: 987654,
                      title: 'Medicine Reminder (Test)',
                      body: 'This is a debug reminder after 10 seconds.',
                      secondsFromNow: 10,
                    );
                    if (!mounted) {
                      return;
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Test reminder scheduled in 10 seconds'),
                      ),
                    );
                  },
                  tooltip: 'Test reminder in 10s',
                  child: const Icon(Icons.notifications_active_outlined),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'add-medicine-fab',
                  onPressed: () async {
                    final medicineProvider = context.read<MedicineProvider>();
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
                    );
                    if (mounted) {
                      await medicineProvider.fetchMedicines();
                      await MedicineReminderScheduler.scheduleForProvider(
                        medicineProvider,
                      );
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                final medicineProvider = context.read<MedicineProvider>();
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
                );
                if (mounted) {
                  await medicineProvider.fetchMedicines();
                  await MedicineReminderScheduler.scheduleForProvider(
                    medicineProvider,
                  );
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
    );
  }
}
