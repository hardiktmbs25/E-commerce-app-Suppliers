// lib/widgets/plan/plan_service_selector.dart
//
// Reusable large-button grid for selecting a service type.
// Used inside the Add Plan bottom sheet.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/plan_constants.dart';

class PlanServiceSelector extends StatelessWidget {
  final RxString selected;
  final ValueChanged<String> onChanged;
  final List<String>? allowedServices; // Optional allowed services

  const PlanServiceSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.allowedServices,
  });

  @override
  Widget build(BuildContext context) {
    final services = allowedServices ?? kServiceTypes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('What do you deliver?'),
        const SizedBox(height: 10),
        Obx(() => Wrap(
          spacing: 10,
          runSpacing: 10,
          children: services.map((type) {
            final isSelected = selected.value == type;
            return _ServiceChip(
              label:      serviceLabel(type),
              icon:       _iconFor(type),
              color:      _colorFor(type),
              isSelected: isSelected,
              onTap:      () => onChanged(type),
            );
          }).toList(),
        )),
      ],
    );
  }

  IconData _iconFor(String s) {
    switch (s) {
      case 'milk':      return Icons.water_drop_rounded;
      case 'water':     return Icons.local_drink_rounded;
      case 'newspaper': return Icons.newspaper_rounded;
      case 'tiffin':    return Icons.lunch_dining_rounded;
      case 'grocery':   return Icons.shopping_basket_rounded;
      default:          return Icons.inventory_2_rounded;
    }
  }

  Color _colorFor(String s) {
    switch (s) {
      case 'milk':      return AppColors.milk;
      case 'water':     return AppColors.water;
      case 'newspaper': return AppColors.newspaper;
      case 'tiffin':    return AppColors.tiffin;
      default:          return AppColors.custom;
    }
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable field label ──────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
      ),
    );
  }
}