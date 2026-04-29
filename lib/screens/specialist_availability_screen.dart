import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_slot_model.dart';
import '../services/api_service.dart';
import '../services/appointment_service.dart';

class SpecialistAvailabilityScreen extends StatefulWidget {
  const SpecialistAvailabilityScreen({super.key});

  static const routeName = '/specialist-availability';

  @override
  State<SpecialistAvailabilityScreen> createState() =>
      _SpecialistAvailabilityScreenState();
}

class _SpecialistAvailabilityScreenState
    extends State<SpecialistAvailabilityScreen> {
  late final AppointmentService _service;
  List<AppointmentSlotModel> _slots = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AppointmentService(ApiService());
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slots = await _service.fetchMySlots();
      if (!mounted) {
        return;
      }
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to load appointment slots';
        _isLoading = false;
      });
    }
  }

  Future<void> _createSlot() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year, now.month, now.day + 1, 10);
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      initialDate: initialDate,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (startTime == null || !mounted) {
      return;
    }

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime.hour + 1) % 24,
        minute: startTime.minute,
      ),
    );
    if (endTime == null || !mounted) {
      return;
    }

    final repeatWeekdays = await _pickRepeatWeekdays(
      initialWeekday: pickedDate.weekday - 1,
    );
    if (repeatWeekdays == null || !mounted) {
      return;
    }

    final startAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      startTime.hour,
      startTime.minute,
    );
    final endAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      endTime.hour,
      endTime.minute,
    );

    try {
      await _service.createSlot(
        startAt: startAt,
        endAt: endAt,
        repeatWeekdays: repeatWeekdays,
        repeatWeeks: repeatWeekdays.isEmpty ? 1 : 8,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            repeatWeekdays.isEmpty
                ? 'Availability slot created'
                : 'Recurring availability created for the next 8 weeks',
          ),
        ),
      );
      _loadSlots();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<List<int>?> _pickRepeatWeekdays({
    required int initialWeekday,
  }) async {
    final initialSelection = <int>{initialWeekday};
    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var repeatWeekly = false;
        final selectedDays = <int>{...initialSelection};
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Repeat Availability',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Turn this on if you want the same slot to repeat on selected days, just like a recurring alarm.',
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Repeat weekly'),
                    subtitle: const Text(
                      'Create the same slot for selected weekdays',
                    ),
                    value: repeatWeekly,
                    onChanged: (value) {
                      setModalState(() {
                        repeatWeekly = value;
                        if (!repeatWeekly) {
                          selectedDays
                            ..clear()
                            ..add(initialWeekday);
                        }
                      });
                    },
                  ),
                  if (repeatWeekly) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_weekdayLabels.length, (index) {
                        final isSelected = selectedDays.contains(index);
                        return FilterChip(
                          label: Text(_weekdayLabels[index]),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedDays.add(index);
                              } else {
                                selectedDays.remove(index);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'We will create upcoming slots for the next 8 weeks on these days.',
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (repeatWeekly && selectedDays.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Select at least one day for recurring availability',
                              ),
                            ),
                          );
                          return;
                        }
                        final List<int> result;
                        if (repeatWeekly) {
                          result = selectedDays.toList();
                          result.sort();
                        } else {
                          result = <int>[];
                        }
                        Navigator.of(context).pop(
                          result,
                        );
                      },
                      child: const Text('Save Availability'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Availability')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSlot,
        icon: const Icon(Icons.add),
        label: const Text('Add Slot'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_slots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No slots created yet. Add your first availability slot or create a recurring weekly schedule.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSlots,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _slots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final slot = _slots[index];
          return Card(
            child: ListTile(
              leading: Icon(
                slot.isBooked
                    ? Icons.event_busy_outlined
                    : Icons.event_available,
              ),
              title: Text(DateFormat('EEE, d MMM yyyy').format(slot.startAt)),
              subtitle: Text(
                '${DateFormat.jm().format(slot.startAt)} - ${DateFormat.jm().format(slot.endAt)}',
              ),
              trailing: Chip(
                label: Text(slot.isBooked ? 'Booked' : 'Open'),
              ),
            ),
          );
        },
      ),
    );
  }
}

const List<String> _weekdayLabels = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
