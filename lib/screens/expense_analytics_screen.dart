import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../widgets/expense_category_chart.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/expense_trend_chart.dart';
import '../widgets/top_expense_list.dart';

class ExpenseAnalyticsScreen extends StatefulWidget {
  const ExpenseAnalyticsScreen({super.key});

  @override
  State<ExpenseAnalyticsScreen> createState() => _ExpenseAnalyticsScreenState();
}

class _ExpenseAnalyticsScreenState extends State<ExpenseAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpenseProvider>();
      if (provider.expenses.isEmpty) {
        provider.fetchExpenses();
      }
      provider.fetchMonthlySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    final content = provider.isLoading && provider.expenses.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : provider.expenses.isEmpty
            ? const _EmptyAnalyticsState()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  return RefreshIndicator(
                    onRefresh: () async {
                      await provider.fetchExpenses();
                      await provider.fetchMonthlySummary();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ExpenseSummaryCard(
                          monthlyTotal: provider.monthlyTotal,
                          yearlyTotal: provider.currentYearTotal,
                          expenseCount: provider.expenseCount,
                        ),
                        const SizedBox(height: 14),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: ExpenseTrendChart(
                                  monthlyTotals:
                                      provider.currentYearMonthlyTotals,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: ExpenseCategoryChart(
                                  categoryTotals:
                                      provider.currentYearCategoryTotals,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          ExpenseTrendChart(
                            monthlyTotals: provider.currentYearMonthlyTotals,
                          ),
                          const SizedBox(height: 14),
                          ExpenseCategoryChart(
                            categoryTotals: provider.currentYearCategoryTotals,
                          ),
                        ],
                        const SizedBox(height: 14),
                        TopExpenseList(items: provider.topExpenseItems),
                      ],
                    ),
                  );
                },
              );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analytics'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: content,
      ),
    );
  }
}

class _EmptyAnalyticsState extends StatelessWidget {
  const _EmptyAnalyticsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'No expense analytics yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Add expense entries to see trends and category insights.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
