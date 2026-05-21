// lib/module/subscriptions/widgets/frequency_chip.dart
//
// A single selectable chip for DeliveryFrequency.
// Large, tap-friendly for less educated users.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_constants.dart';

class FrequencyChipRow extends StatelessWidget {
  final DeliveryFrequency selected;
  final ValueChanged<DeliveryFrequency> onChanged;

  const FrequencyChipRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: FrequencyConstants.all.map((f) {
        final isSelected = selected == f;
        return GestureDetector(
          onTap: () => onChanged(f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
                  : null,
            ),
            child: Text(
              FrequencyConstants.shortLabel(f),
              style: TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}