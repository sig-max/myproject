import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TopExpenseList extends StatelessWidget {
  const TopExpenseList({super.key, required this.items});

  final List<MapEntry<String, double>> items;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF2FBFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF0EA5A4).withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -14,
            child: Icon(
              Icons.local_hospital_outlined,
              size: 84,
              color: const Color(0xFF0EA5A4).withOpacity(0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Medicines / Items', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (items.isEmpty) const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('No expenses available'),
                )),
                ...List.generate(items.length, (index) {
                  final e = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF0EA5A4).withOpacity(0.14),
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                        Text(
                          formatter.format(e.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
