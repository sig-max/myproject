import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key, this.initialMedicine});

  final MedicineModel? initialMedicine;

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  static const Map<String, String> _presetTimeMap = {
    'Morning (08:00)': '08:00',
    'Afternoon (13:00)': '13:00',
    'Evening (18:00)': '18:00',
    'Night (21:00)': '21:00',
  };

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _stockController;
  late final TextEditingController _notesController;

  final Set<String> _selectedTimes = <String>{};
  final Set<String> _customTimes = <String>{};

  bool get _isEdit => widget.initialMedicine != null;

  @override
  void initState() {
    super.initState();
    final medicine = widget.initialMedicine;

    _nameController = TextEditingController(text: medicine?.name ?? '');
    _dosageController = TextEditingController(text: medicine?.dosage ?? '');
    _stockController = TextEditingController(text: (medicine?.stock ?? 0).toString());
    _notesController = TextEditingController(text: medicine?.notes ?? '');

    final existingTimes = medicine?.times ?? const <String>[];
    for (final time in existingTimes) {
      _selectedTimes.add(time);
      if (!_presetTimeMap.containsValue(time)) {
        _customTimes.add(time);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;

    final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      _customTimes.add(value);
      _selectedTimes.add(value);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one medicine time')),
      );
      return;
    }

    final stock = int.tryParse(_stockController.text.trim()) ?? -1;
    if (stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock must be 0 or greater')),
      );
      return;
    }

    final times = _selectedTimes.toList()..sort();

    final model = MedicineModel(
      id: widget.initialMedicine?.id ?? '',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      times: times,
      stock: stock,
      notes: _notesController.text.trim(),
    );

    final provider = context.read<MedicineProvider>();
    final success = _isEdit
        ? await provider.updateMedicine(model)
        : await provider.addMedicine(model);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Operation failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Medicine' : 'Add Medicine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (value) => Validators.requiredField(value, fieldName: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage'),
                validator: (value) => Validators.requiredField(value, fieldName: 'Dosage'),
              ),
              const SizedBox(height: 18),
              const Text(
                'Take Medicine At',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              ..._presetTimeMap.entries.map((entry) {
                final label = entry.key;
                final value = entry.value;
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(label),
                  value: _selectedTimes.contains(value),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedTimes.add(value);
                      } else {
                        _selectedTimes.remove(value);
                      }
                    });
                  },
                );
              }),

              TextButton.icon(
                onPressed: _addCustomTime,
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Time'),
              ),

              if (_customTimes.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Text('Custom Times'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customTimes.map((time) {
                    final selected = _selectedTimes.contains(time);
                    return FilterChip(
                      label: Text(time),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedTimes.add(time);
                          } else {
                            _selectedTimes.remove(time);
                          }
                        });
                      },
                      onDeleted: () {
                        setState(() {
                          _customTimes.remove(time);
                          _selectedTimes.remove(time);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Text('Selected Times Preview'),
              const SizedBox(height: 8),
              if (_selectedTimes.isEmpty)
                const Text('No times selected')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_selectedTimes.toList()..sort())
                      .map((t) => Chip(label: Text(t)))
                      .toList(),
                ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
                validator: (value) {
                  final base = Validators.number(value, fieldName: 'Stock');
                  if (base != null) return base;
                  final n = int.tryParse(value?.trim() ?? '');
                  if (n == null || n < 0) return 'Stock must be 0 or greater';
                  return null;
                },
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),

              const SizedBox(height: 24),
              CustomButton(
                label: _isEdit ? 'Update Medicine' : 'Save Medicine',
                isLoading: provider.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
