import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'appointment_booking_screen.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/specialist_service.dart';
import 'chat_thread_screen.dart';

class SpecialistDiscoveryScreen extends StatefulWidget {
  const SpecialistDiscoveryScreen({super.key});

  static const routeName = '/specialists';

  @override
  State<SpecialistDiscoveryScreen> createState() =>
      _SpecialistDiscoveryScreenState();
}

class _SpecialistDiscoveryScreenState extends State<SpecialistDiscoveryScreen> {
  final _specializationController = TextEditingController();
  final _cityController = TextEditingController();
  final _languageController = TextEditingController();
  final _minFeeController = TextEditingController();
  final _maxFeeController = TextEditingController();
  late final SpecialistService _service;
  late final ChatService _chatService;

  List<UserModel> _specialists = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = SpecialistService(ApiService());
    _chatService = ChatService(ApiService());
    _search();
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _cityController.dispose();
    _languageController.dispose();
    _minFeeController.dispose();
    _maxFeeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.fetchSpecialists(
        specialization: _specializationController.text,
        city: _cityController.text,
        language: _languageController.text,
        minFee: _minFeeController.text,
        maxFee: _maxFeeController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _specialists = results;
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
        _error = 'Unable to load specialists';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Specialist')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Specialization',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _languageController,
                        decoration: const InputDecoration(
                          labelText: 'Language',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minFeeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Fee',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxFeeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Fee',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _search,
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _specializationController.clear();
                                _cityController.clear();
                                _languageController.clear();
                                _minFeeController.clear();
                                _maxFeeController.clear();
                                _search();
                              },
                        child: const Text('Clear Filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_specialists.isEmpty) {
      return const Center(
        child: Text('No specialists found for the selected filters'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _specialists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final specialist = _specialists[index];
        final profile = specialist.profile;
        final languages = profile['languages'] is List
            ? (profile['languages'] as List).join(', ')
            : 'Not added';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        specialist.name.isNotEmpty
                            ? specialist.name[0].toUpperCase()
                            : 'S',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialist.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _stringOrDefault(
                              profile['specialization'],
                              'Specialization not added',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Rs. ${_numToText(profile['consultation_fee'])}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('City: ${_stringOrDefault(profile['city'], 'Not added')}'),
                const SizedBox(height: 4),
                Text('Languages: $languages'),
                const SizedBox(height: 4),
                Text(
                  'Experience: ${_numToText(profile['years_of_experience'])} years',
                ),
                const SizedBox(height: 8),
                Text(
                  _stringOrDefault(
                    profile['bio'],
                    'No bio added yet.',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AppointmentBookingScreen(
                                specialist: specialist,
                              ),
                            ),
                          );
                        },
                        child: const Text('Book Appointment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            final thread =
                                await _chatService.startThread(specialist.id);
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatThreadScreen(
                                  thread: thread,
                                  role: 'patient',
                                ),
                              ),
                            );
                          } on ApiException catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                        child: const Text('Start Chat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
