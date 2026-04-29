import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/validators.dart';

class SpecialistProfileScreen extends StatefulWidget {
  const SpecialistProfileScreen({super.key});

  static const routeName = '/specialist-profile';

  @override
  State<SpecialistProfileScreen> createState() => _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState extends State<SpecialistProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _languagesController = TextEditingController();
  final _bioController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final user = context.read<AuthProvider>().user;
    final profile = user?.profile ?? const <String, dynamic>{};
    _nameController.text = user?.name ?? '';
    _phoneController.text = (profile['phone'] ?? '').toString();
    _specializationController.text = (profile['specialization'] ?? '').toString();
    _experienceController.text = _numToText(profile['years_of_experience']);
    _feeController.text = _numToText(profile['consultation_fee']);
    _cityController.text = (profile['city'] ?? '').toString();
    _stateController.text = (profile['state'] ?? '').toString();
    _languagesController.text = _listToCsv(profile['languages']);
    _bioController.text = (profile['bio'] ?? '').toString();
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _languagesController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final ok = await context.read<AuthProvider>().updateCurrentUser({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'years_of_experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'consultation_fee': double.tryParse(_feeController.text.trim()) ?? 0,
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'languages': _splitCsv(_languagesController.text),
        'bio': _bioController.text.trim(),
      });

      if (!mounted) return;

      if (!ok) {
        setState(() => _error = 'Unable to save profile changes.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save profile changes')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error while saving: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Specialist Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  validator: (value) =>
                      Validators.requiredField(value, fieldName: 'Full Name'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _phoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  validator: (value) =>
                      Validators.phone(value, fieldName: 'Phone'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _specializationController,
                  label: 'Specialization',
                  validator: (value) => Validators.requiredField(
                    value,
                    fieldName: 'Specialization',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _experienceController,
                        label: 'Experience (Years)',
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            Validators.number(value, fieldName: 'Experience'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _feeController,
                        label: 'Consultation Fee',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => Validators.number(
                          value,
                          fieldName: 'Consultation Fee',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _cityController,
                        label: 'City',
                        validator: (value) =>
                            Validators.requiredField(value, fieldName: 'City'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _stateController,
                        label: 'State',
                        validator: (value) =>
                            Validators.requiredField(value, fieldName: 'State'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _languagesController,
                  label: 'Languages (comma separated)',
                  validator: (value) => Validators.requiredField(
                    value,
                    fieldName: 'Languages',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

String _listToCsv(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).join(', ');
  }
  return '';
}

List<String> _splitCsv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _numToText(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is int) {
    return value.toString();
  }
  if (value is double) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
  return value.toString();
}
