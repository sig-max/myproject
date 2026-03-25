import 'package:flutter/material.dart';

import '../models/medicine_model.dart';

class LowStockWarning extends StatelessWidget {
  const LowStockWarning({
    super.key,
    required this.lowStockMedicines,
  });

  final List<MedicineModel> lowStockMedicines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Medicines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (lowStockMedicines.isEmpty)
              Text(
                'All medicines are sufficiently stocked.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...lowStockMedicines.map(
                (medicine) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medication_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          medicine.name,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Stock: ${medicine.stock}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
