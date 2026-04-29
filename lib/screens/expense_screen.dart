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
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final expenseProvider = context.read<ExpenseProvider>();
    await expenseProvider.fetchExpenses();
    await expenseProvider.fetchMonthlySummary();
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FEFD), Color(0xFFEFFAFB), Color(0xFFFFFFFF)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF2FBFA)],
                  ),
                  border: Border.all(
                    color: const Color(0xFF0EA5A4).withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.09),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -14,
                      right: -12,
                      child: Icon(
                        Icons.payments_outlined,
                        size: 82,
                        color: const Color(0xFF0EA5A4).withValues(alpha: 0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Expense',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF12343B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track medicine and healthcare spending.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF4B6B70),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Expense Title',
                                prefixIcon: Icon(Icons.receipt_long_outlined),
                              ),
                              validator: (value) =>
                                  Validators.requiredField(value, fieldName: 'Title'),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.currency_rupee_rounded),
                              ),
                              validator: (value) =>
                                  Validators.number(value, fieldName: 'Amount'),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                prefixIcon: Icon(Icons.sticky_note_2_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            CustomButton(
                              label: 'Add Expense',
                              icon: Icons.add_circle_outline_rounded,
                              isLoading: provider.isLoading,
                              onPressed: _addExpense,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpenseSummaryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart_rounded),
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
              const SizedBox(height: 14),
              Text(
                'Recent Expenses',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF12343B),
                ),
              ),
              const SizedBox(height: 8),
              if (provider.isLoading && provider.expenses.isEmpty)
                const _ExpenseListSkeleton()
              else if (provider.expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: Text('No expenses found')),
                )
              else
                ...provider.expenses.map(
                  (expense) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ExpenseCard(expense: expense),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseListSkeleton extends StatelessWidget {
  const _ExpenseListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFE8F6F6),
          ),
        ),
      ),
    );
  }
}
