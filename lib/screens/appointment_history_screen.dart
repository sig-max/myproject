import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_model.dart';
import '../services/api_service.dart';
import '../services/appointment_service.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({
    super.key,
    required this.role,
  });

  static const patientRouteName = '/patient-appointments';
  static const specialistRouteName = '/specialist-appointments';

  final String role;

  @override
  State<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  late final AppointmentService _service;
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AppointmentService(ApiService());
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchMyAppointments();
      if (!mounted) {
        return;
      }
      setState(() {
        _appointments = items;
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
        _error = 'Unable to load appointments';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == 'specialist'
        ? 'Patient Appointments'
        : 'My Appointments';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
    if (_appointments.isEmpty) {
      return const Center(child: Text('No appointments yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          final name = widget.role == 'specialist'
              ? (appointment.patientName ?? 'Patient')
              : (appointment.specialistName ?? 'Specialist');

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Chip(label: Text(appointment.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (appointment.slotStartAt != null &&
                      appointment.slotEndAt != null)
                    Text(
                      '${DateFormat('EEE, d MMM yyyy').format(appointment.slotStartAt!)} | ${DateFormat.jm().format(appointment.slotStartAt!)} - ${DateFormat.jm().format(appointment.slotEndAt!)}',
                    ),
                  const SizedBox(height: 8),
                  Text(
                    appointment.notes.trim().isEmpty
                        ? 'No notes added'
                        : appointment.notes,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booked on ${DateFormat('d MMM yyyy, h:mm a').format(appointment.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
