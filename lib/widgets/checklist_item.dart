import 'package:flutter/material.dart';

import '../models/checklist_model.dart';

class ChecklistItem extends StatelessWidget {
  const ChecklistItem({
    super.key,
    required this.item,
    required this.onMarkTaken,
  });

  final ChecklistModel item;
  final VoidCallback onMarkTaken;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          item.taken ? Icons.check_circle : Icons.radio_button_unchecked,
          color: item.taken ? Colors.green : Colors.grey,
        ),
        title: Text(item.medicineName),
        subtitle: Text(item.scheduledTime == null
            ? 'No specific time'
            : 'Scheduled: ${item.scheduledTime}'),
        trailing: item.taken
            ? const Text('Taken')
            : TextButton(
                onPressed: onMarkTaken,
                child: const Text('Mark Taken'),
              ),
      ),
    );
  }
}
