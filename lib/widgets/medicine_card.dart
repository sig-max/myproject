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
    final theme = Theme.of(context);
    final lowStock = medicine.stock <= 5;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween(begin: 0.98, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
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
                color: const Color(0xFF0F766E).withOpacity(0.09),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  Icons.medication_liquid_outlined,
                  size: 72,
                  color: const Color(0xFF0EA5A4).withOpacity(0.08),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22D3EE), Color(0xFF0EA5A4)],
                    ),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Colors.white),
                ),
                title: Text(
                  medicine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${medicine.dosage} • ${medicine.frequency}',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B6B70)),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lowStock ? 'Low ${medicine.stock}' : 'Stock ${medicine.stock}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: lowStock ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (reminderActive)
                      Text(
                        '⏰ On',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF0F766E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
