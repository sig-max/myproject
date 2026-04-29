import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/home_sample_request_model.dart';
import '../services/api_service.dart';
import '../services/home_sample_service.dart';
import '../utils/validators.dart';

class HomeSampleRequestScreen extends StatefulWidget {
  const HomeSampleRequestScreen({super.key});

  static const routeName = '/home-sample-request';

  @override
  State<HomeSampleRequestScreen> createState() =>
      _HomeSampleRequestScreenState();
}

class _HomeSampleRequestScreenState extends State<HomeSampleRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();
  final _preferredDateController = TextEditingController();
  final _preferredTimeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  late final HomeSampleService _service;
  List<HomeSampleRequestModel> _requests = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = HomeSampleService(ApiService());
    _loadRequests();
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await _service.fetchMyRequests();
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = requests;
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      initialDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      _preferredDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _preferredTimeController.text = picked.format(context);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _service.createRequest(
        testName: _testNameController.text.trim(),
        preferredDate: _preferredDateController.text.trim(),
        preferredTime: _preferredTimeController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample request submitted successfully')),
      );

      _formKey.currentState!.reset();
      _testNameController.clear();
      _preferredDateController.clear();
      _preferredTimeController.clear();
      _addressController.clear();
      _cityController.clear();
      _phoneController.clear();
      _notesController.clear();
      setState(() => _isSubmitting = false);
      _loadRequests();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      const message = 'Something went wrong. Please try again.';
      setState(() => _error = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message ($error)')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Sample Collection')),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request Home Sample Collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _testNameController,
                        label: 'Test Name',
                        validator: (value) => Validators.requiredField(
                          value,
                          fieldName: 'Test Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _preferredDateController,
                              label: 'Preferred Date',
                              readOnly: true,
                              onTap: _pickDate,
                              validator: (value) => Validators.requiredField(
                                value,
                                fieldName: 'Preferred Date',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _preferredTimeController,
                              label: 'Preferred Time',
                              readOnly: true,
                              onTap: _pickTime,
                              validator: (value) => Validators.requiredField(
                                value,
                                fieldName: 'Preferred Time',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _addressController,
                        label: 'Address',
                        maxLines: 2,
                        validator: (value) => Validators.requiredField(
                          value,
                          fieldName: 'Address',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _cityController,
                              label: 'City',
                              validator: (value) => Validators.requiredField(
                                value,
                                fieldName: 'City',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _phoneController,
                              label: 'Phone',
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]'),
                                ),
                              ],
                              validator: (value) =>
                                  Validators.phone(value, fieldName: 'Phone'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _notesController,
                        label: 'Notes',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: Text(
                          _isSubmitting ? 'Submitting...' : 'Submit Request',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'My Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!)
            else if (_requests.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No home sample requests yet.'),
                ),
              )
            else
              ..._requests.map(_buildRequestCard),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(HomeSampleRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            Text('${request.preferredDate} | ${request.preferredTime}'),
            const SizedBox(height: 4),
            Text(request.address),
            const SizedBox(height: 4),
            Text('City: ${request.city}'),
            const SizedBox(height: 4),
            Text('Phone: ${request.phone}'),
            if (request.specialistName != null) ...[
              const SizedBox(height: 4),
              Text('Assigned Specialist: ${request.specialistName}'),
            ],
            if (request.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
