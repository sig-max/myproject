import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/home_sample_request_model.dart';
import '../services/api_service.dart';
import '../services/home_sample_service.dart';

class SpecialistHomeSamplesScreen extends StatefulWidget {
  const SpecialistHomeSamplesScreen({super.key});

  static const routeName = '/specialist-home-samples';

  @override
  State<SpecialistHomeSamplesScreen> createState() =>
      _SpecialistHomeSamplesScreenState();
}

class _SpecialistHomeSamplesScreenState
    extends State<SpecialistHomeSamplesScreen> {
  late final HomeSampleService _service;
  List<HomeSampleRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = HomeSampleService(ApiService());
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchMyRequests();
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = items;
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
        _error = 'Unable to load home sample requests';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(
    HomeSampleRequestModel request,
    String status,
  ) async {
    try {
      await _service.updateStatus(requestId: request.id, status: status);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request marked as $status')),
      );
      _loadRequests();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Sample Requests')),
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
    if (_requests.isEmpty) {
      return const Center(child: Text('No home sample requests available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = _requests[index];
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
                          request.testName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Chip(label: Text(request.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Patient: ${request.patientName ?? 'Patient'}'),
                  const SizedBox(height: 4),
                  Text(
                    '${request.preferredDate} | ${request.preferredTime}',
                  ),
                  const SizedBox(height: 4),
                  Text('City: ${request.city}'),
                  const SizedBox(height: 4),
                  Text('Address: ${request.address}'),
                  const SizedBox(height: 4),
                  Text('Phone: ${request.phone}'),
                  if (request.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(request.notes),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Requested on ${DateFormat('d MMM yyyy, h:mm a').format(request.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (request.status == 'pending')
                        FilledButton(
                          onPressed: () => _updateStatus(request, 'accepted'),
                          child: const Text('Accept'),
                        ),
                      if (request.status == 'accepted')
                        FilledButton.tonal(
                          onPressed: () => _updateStatus(request, 'completed'),
                          child: const Text('Complete'),
                        ),
                      if (request.status == 'pending' ||
                          request.status == 'accepted')
                        OutlinedButton(
                          onPressed: () => _updateStatus(request, 'cancelled'),
                          child: const Text('Cancel'),
                        ),
                    ],
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
