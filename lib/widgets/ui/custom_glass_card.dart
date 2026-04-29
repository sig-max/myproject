import 'dart:ui';
import 'package:flutter/material.dart';

class CustomGlassCard extends StatelessWidget {
  const CustomGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 16,
    this.iconWatermark,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final IconData? iconWatermark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.88),
                const Color(0xFFF2FBFA).withOpacity(0.86),
              ],
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
              if (iconWatermark != null)
                Positioned(
                  right: -14,
                  top: -14,
                  child: Icon(
                    iconWatermark,
                    size: 84,
                    color: const Color(0xFF0EA5A4).withOpacity(0.08),
                  ),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}