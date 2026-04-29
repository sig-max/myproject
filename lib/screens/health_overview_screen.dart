import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/checklist_model.dart';
import '../models/medicine_model.dart';
import '../providers/checklist_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/medicine_provider.dart';
import '../utils/adherence_insights_helper.dart';
import '../utils/medicine_reminder_scheduler.dart';
import '../widgets/adherence_indicator.dart';
import '../widgets/adherence_streak_card.dart';
import '../widgets/best_week_badge.dart';
import '../widgets/dashboard_action_buttons.dart';
import '../widgets/health_task_progress.dart';
import '../widgets/low_stock_warning.dart';
import '../widgets/medicine_schedule_section.dart';
import '../widgets/missed_dose_alert.dart';
import '../widgets/monthly_adherence_score.dart';
import '../widgets/upcoming_medicine_widget.dart';
import 'add_medicine_screen.dart';
import 'daily_checkbook_screen.dart';
import 'expense_screen.dart';
import 'home_sample_request_screen.dart';
import 'specialist_discovery_screen.dart';

class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<HealthOverviewScreen> createState() => _HealthOverviewScreenState();
}

class _HealthOverviewScreenState extends State<HealthOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final medicineProvider = context.read<MedicineProvider>();
    final checklistProvider = context.read<ChecklistProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    await Future.wait([
      medicineProvider.fetchMedicines(),
      checklistProvider.fetchTodayChecklist(),
      expenseProvider.fetchExpenses(),
    ]);

    await MedicineReminderScheduler.scheduleForProvider(medicineProvider);
    await MedicineReminderScheduler.checkMissedMedicines(
      medicines: medicineProvider.medicines,
      checklistItems: checklistProvider.items,
    );
  }

  Map<String, List<ScheduleEntry>> _buildTodayMedicineSchedule(
    List<MedicineModel> medicines,
  ) {
    final grouped = <String, List<ScheduleEntry>>{
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
      'Night': [],
    };

    for (final medicine in medicines) {
      for (final rawTime in medicine.times) {
        final group = _toScheduleGroup(rawTime);
        final scheduledAt = _resolveScheduledDateTime(rawTime, DateTime.now());
        final timeLabel = DateFormat.jm().format(scheduledAt);

        grouped[group]!.add(
          ScheduleEntry(
            medicineName: medicine.name,
            dosage: medicine.dosage,
            timeLabel: timeLabel,
          ),
        );
      }
    }

    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
    }

    return grouped;
  }

  List<MedicineModel> _lowStockMedicines(List<MedicineModel> medicines) {
    final lowStock = medicines.where((medicine) => medicine.stock < 5).toList();
    lowStock.sort((a, b) => a.stock.compareTo(b.stock));
    return lowStock;
  }

  double _adherencePercentage(List<ChecklistModel> items) {
    if (items.isEmpty) {
      return 0;
    }
    final completed = items.where((item) => item.taken).length;
    return completed / items.length;
  }

  List<UpcomingDose> _upcomingMedicines(List<MedicineModel> medicines) {
    final now = DateTime.now();
    final nextWindow = now.add(const Duration(hours: 4));
    final upcoming = <UpcomingDose>[];

    for (final medicine in medicines) {
      for (final timeToken in medicine.times) {
        final scheduledAt = _resolveScheduledDateTime(timeToken, now);
        if (scheduledAt.isBefore(now) || scheduledAt.isAfter(nextWindow)) {
          continue;
        }

        upcoming.add(
          UpcomingDose(
            medicineName: medicine.name,
            dosage: medicine.dosage,
            scheduledAt: scheduledAt,
            displayTime: DateFormat.jm().format(scheduledAt),
          ),
        );
      }
    }

    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming;
  }

  String _toScheduleGroup(String token) {
    final lower = token.trim().toLowerCase();
    if (lower.contains('morning')) {
      return 'Morning';
    }
    if (lower.contains('afternoon') || lower.contains('noon')) {
      return 'Afternoon';
    }
    if (lower.contains('night')) {
      return 'Night';
    }
    if (lower.contains('evening')) {
      return 'Evening';
    }

    final resolved = _resolveScheduledDateTime(token, DateTime.now());
    final hour = resolved.hour;
    if (hour >= 5 && hour < 12) {
      return 'Morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    }
    if (hour >= 17 && hour < 21) {
      return 'Evening';
    }
    return 'Night';
  }

  DateTime _resolveScheduledDateTime(String token, DateTime reference) {
    final lower = token.trim().toLowerCase();

    if (lower.contains('morning')) {
      return DateTime(reference.year, reference.month, reference.day, 8, 0);
    }
    if (lower.contains('afternoon') || lower.contains('noon')) {
      return DateTime(reference.year, reference.month, reference.day, 13, 0);
    }
    if (lower.contains('evening')) {
      return DateTime(reference.year, reference.month, reference.day, 18, 0);
    }
    if (lower.contains('night')) {
      return DateTime(reference.year, reference.month, reference.day, 21, 0);
    }

    final normalized = token.trim().toUpperCase();
    final formats = [DateFormat('HH:mm'), DateFormat('H:mm'), DateFormat('h:mm a')];

    for (final format in formats) {
      try {
        final parsed = format.parseStrict(normalized);
        return DateTime(
          reference.year,
          reference.month,
          reference.day,
          parsed.hour,
          parsed.minute,
        );
      } catch (_) {
        continue;
      }
    }

    return DateTime(reference.year, reference.month, reference.day, 9, 0);
  }

  Widget _buildAdherenceInsightsSection({required bool isWide}) {
    return Consumer2<MedicineProvider, ChecklistProvider>(
      builder: (context, medicineProvider, checklistProvider, _) {
        final medicines = medicineProvider.medicines;
        final checklistItems = checklistProvider.items;

        final streakDays = calculateStreak(
          checklistItems: checklistItems,
          medicines: medicines,
        );
        final monthlyAdherence =
            calculateMonthlyAdherence(checklistItems: checklistItems);
        final bestWeek = calculateBestWeek(checklistItems: checklistItems);
        final missedDays = findMissedDays(checklistItems: checklistItems);

        final cards = <Widget>[
          AdherenceStreakCard(streakDays: streakDays),
          MonthlyAdherenceScore(percentage: monthlyAdherence),
          BestWeekBadge(
            weekLabel: bestWeek.weekLabel,
            percentage: bestWeek.percentage,
            hasData: bestWeek.hasData,
          ),
          MissedDoseAlert(missedDays: missedDays),
        ];

        final compact = !isWide;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adherence Insights',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (compact) ...[
              cards[0],
              const SizedBox(height: 10),
              cards[1],
              const SizedBox(height: 10),
              cards[2],
              const SizedBox(height: 10),
              cards[3],
            ] else ...[
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.watch<MedicineProvider>();
    final checklistProvider = context.watch<ChecklistProvider>();

    final medicines = medicineProvider.medicines;
    final checklistItems = checklistProvider.items;

    final isLoading =
        (medicineProvider.isLoading || checklistProvider.isLoading) &&
            medicines.isEmpty &&
            checklistItems.isEmpty;

    Widget content;

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      final groupedSchedule = _buildTodayMedicineSchedule(medicines);
      final lowStockMedicines = _lowStockMedicines(medicines);
      final adherence = _adherencePercentage(checklistItems);
      final completedTasks = checklistItems.where((item) => item.taken).length;
      final pendingTasks = checklistItems.length - completedTasks;
      final upcoming = _upcomingMedicines(medicines);

      content = RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;

            if (medicines.isEmpty && checklistItems.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.health_and_safety_outlined, size: 56),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'No health data available yet. Add medicines to get started.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DashboardActionButtons(
                    onAddMedicine: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddMedicineScreen(),
                        ),
                      );
                    },
                    onAddExpense: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExpenseScreen(),
                        ),
                      );
                    },
                    onAddChecklistTask: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DailyCheckbookScreen(),
                        ),
                      );
                    },
                    onFindSpecialist: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SpecialistDiscoveryScreen(),
                        ),
                      );
                    },
                    onBookHomeTest: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HomeSampleRequestScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            }

            if (isWide) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            MedicineScheduleSection(
                              groupedSchedule: groupedSchedule,
                            ),
                            const SizedBox(height: 12),
                            UpcomingMedicineWidget(
                              upcomingMedicines: upcoming,
                              now: DateTime.now(),
                            ),
                            const SizedBox(height: 12),
                            DashboardActionButtons(
                              onAddMedicine: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AddMedicineScreen(),
                                  ),
                                );
                              },
                              onAddExpense: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ExpenseScreen(),
                                  ),
                                );
                              },
                              onAddChecklistTask: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DailyCheckbookScreen(),
                                  ),
                                );
                              },
                              onFindSpecialist: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SpecialistDiscoveryScreen(),
                                  ),
                                );
                              },
                              onBookHomeTest: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const HomeSampleRequestScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            AdherenceIndicator(
                              adherencePercentage: adherence,
                              completed: completedTasks,
                              total: checklistItems.length,
                            ),
                            const SizedBox(height: 12),
                            HealthTaskProgress(
                              completed: completedTasks,
                              pending: pendingTasks,
                            ),
                            const SizedBox(height: 12),
                            _buildAdherenceInsightsSection(
                              isWide: true,
                            ),
                            const SizedBox(height: 12),
                            LowStockWarning(lowStockMedicines: lowStockMedicines),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AdherenceIndicator(
                  adherencePercentage: adherence,
                  completed: completedTasks,
                  total: checklistItems.length,
                ),
                const SizedBox(height: 12),
                HealthTaskProgress(
                  completed: completedTasks,
                  pending: pendingTasks,
                ),
                const SizedBox(height: 12),
                MedicineScheduleSection(groupedSchedule: groupedSchedule),
                const SizedBox(height: 12),
                _buildAdherenceInsightsSection(isWide: false),
                const SizedBox(height: 12),
                UpcomingMedicineWidget(
                  upcomingMedicines: upcoming,
                  now: DateTime.now(),
                ),
                const SizedBox(height: 12),
                LowStockWarning(lowStockMedicines: lowStockMedicines),
                const SizedBox(height: 12),
                DashboardActionButtons(
                  onAddMedicine: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddMedicineScreen(),
                      ),
                    );
                  },
                  onAddExpense: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExpenseScreen(),
                      ),
                    );
                  },
                  onAddChecklistTask: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DailyCheckbookScreen(),
                      ),
                    );
                  },
                  onFindSpecialist: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SpecialistDiscoveryScreen(),
                      ),
                    );
                  },
                  onBookHomeTest: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HomeSampleRequestScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Health Overview'))
          : null,
      body: content,
    );
  }
}
