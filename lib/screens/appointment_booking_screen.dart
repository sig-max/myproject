import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_slot_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/appointment_service.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({
    super.key,
    required this.specialist,
  });

  final UserModel specialist;

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _notesController = TextEditingController();
  late final AppointmentService _service;
  List<AppointmentSlotModel> _slots = [];
  String? _selectedSlotId;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AppointmentService(ApiService());
    _loadSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slots = await _service.fetchSpecialistSlots(
        widget.specialist.id,
        availableOnly: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _slots = slots;
        _selectedSlotId = slots.isNotEmpty ? slots.first.id : null;
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
        _error = 'Unable to load specialist availability';
        _isLoading = false;
      });
    }
  }

  Future<void> _book() async {
    if (_selectedSlotId == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.bookAppointment(
        slotId: _selectedSlotId!,
        notes: _notesController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Appointment request sent. Specialist can accept it within 1 hour.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.specialist.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(widget.specialist.name),
                    subtitle: Text(
                      '${_stringOrDefault(profile['specialization'], 'Specialist')} - ${_stringOrDefault(profile['city'], 'Unknown city')}',
                    ),
                    trailing: Chip(
                      label: Text(
                        'Rs. ${_numToText(profile['consultation_fee'])}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!),
                  ),
                if (_slots.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No free slots available right now.'),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Slots',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          for (final slot in _slots)
                            RadioListTile<String>(
                              value: slot.id,
                              groupValue: _selectedSlotId,
                              onChanged: (value) {
                                setState(() => _selectedSlotId = value);
                              },
                              title: Text(
                                DateFormat('EEE, d MMM yyyy').format(slot.startAt),
                              ),
                              subtitle: Text(
                                '${DateFormat.jm().format(slot.startAt)} - ${DateFormat.jm().format(slot.endAt)}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Appointments start as pending. If the specialist does not accept within 1 hour, the request will be accepted automatically.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Symptoms / Notes',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _slots.isEmpty || _isSubmitting ? null : _book,
                  child: Text(_isSubmitting ? 'Booking...' : 'Confirm Booking'),
                ),
              ],
            ),
    );
  }
}

String _stringOrDefault(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _numToText(dynamic value) {
  final numeric = double.tryParse(value?.toString() ?? '');
  if (numeric == null) {
    return '0';
  }
  return numeric == numeric.roundToDouble()
      ? numeric.toInt().toString()
      : numeric.toStringAsFixed(1);
}
