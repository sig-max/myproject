import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/expense_card.dart';
import 'expense_analytics_screen.dart';
import 'expense_summary_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Medicine');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final expenseProvider = context.read<ExpenseProvider>();
      expenseProvider.fetchExpenses();
      expenseProvider.fetchMonthlySummary();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final model = ExpenseModel(
      id: '',
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: DateTime.now(),
      notes: _notesController.text.trim(),
    );

    final provider = context.read<ExpenseProvider>();
    final success = await provider.addExpense(model);

    if (!mounted) {
      return;
    }

    if (success) {
      _titleController.clear();
      _amountController.clear();
      _notesController.clear();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Unable to add expense')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final expenseProvider = context.read<ExpenseProvider>();
          await expenseProvider.fetchExpenses();
          await expenseProvider.fetchMonthlySummary();
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration:
                            const InputDecoration(labelText: 'Expense Title'),
                        validator: (value) =>
                            Validators.requiredField(value, fieldName: 'Title'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        validator: (value) =>
                            Validators.number(value, fieldName: 'Amount'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Add Expense',
                        isLoading: provider.isLoading,
                        onPressed: _addExpense,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ExpenseSummaryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text('View Monthly Summary'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ExpenseAnalyticsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Open Expense Analytics Dashboard'),
            ),
            const SizedBox(height: 10),
            if (provider.expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: Text('No expenses found')),
              )
            else
              ...provider.expenses.map((expense) => ExpenseCard(expense: expense)),
          ],
        ),
      ),
    );
  }
}
