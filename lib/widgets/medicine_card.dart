import 'package:flutter/material.dart';

import '../models/medicine_model.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
    this.reminderActive = false,
  });

  final MedicineModel medicine;
  final VoidCallback? onTap;
  final bool reminderActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(medicine.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${medicine.dosage} • ${medicine.frequency}'),
            if (reminderActive)
              Text(
                '⏰ Reminder Active',
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        trailing: Text('Stock: ${medicine.stock}'),
      ),
    );
  }
}
