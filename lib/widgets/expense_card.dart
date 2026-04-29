import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({super.key, required this.expense});

  final ExpenseModel expense;

  Color _categoryColor(String category) {
    switch (category.trim().toLowerCase()) {
      case 'medicine':
      case 'medicines':
        return const Color(0xFF0EA5A4);
      case 'consultation':
      case 'doctor':
        return const Color(0xFF3B82F6);
      case 'lab':
      case 'tests':
        return const Color(0xFF8B5CF6);
      case 'transport':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.trim().toLowerCase()) {
      case 'medicine':
      case 'medicines':
        return Icons.medication_outlined;
      case 'consultation':
      case 'doctor':
        return Icons.medical_services_outlined;
      case 'lab':
      case 'tests':
        return Icons.science_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(expense.category);
    final amountText = NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(expense.amount);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 220),
      tween: Tween(begin: 0.98, end: 1),
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF2FBFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: catColor.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: catColor.withOpacity(0.14),
            child: Icon(_categoryIcon(expense.category), color: catColor, size: 20),
          ),
          title: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${expense.category} • ${DateFormat.yMMMd().format(expense.date)}'),
          trailing: Text(
            amountText,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
          ),
        ),
      ),
    );
  }
}
