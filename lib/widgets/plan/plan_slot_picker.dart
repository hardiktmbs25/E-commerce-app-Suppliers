// lib/widgets/plan/plan_slot_picker.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/time_slot_model.dart';

class PlanSlotPicker extends StatelessWidget {
  final List<TimeSlotModel> slots;
  final List<String> selectedIds;  // Plain List, not RxList
  final int required;
  final ValueChanged<String> onToggle;

  const PlanSlotPicker({
    super.key,
    required this.slots,
    required this.selectedIds,
    required this.required,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No time slots found. Add delivery time slots first\n(Time Slots tab).',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.warning,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Time  (${selectedIds.length} / $required selected)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selectedIds.length == required
                ? AppColors.success
                : AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        ...slots.map((slot) => _SlotTile(
          slot: slot,
          isSelected: selectedIds.contains(slot.id),
          onToggle: onToggle,
        )),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  final TimeSlotModel slot;
  final bool isSelected;
  final ValueChanged<String> onToggle;

  const _SlotTile({
    required this.slot,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(slot.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (slot.startTime.isNotEmpty && slot.endTime.isNotEmpty)
                  Text(
                    '${slot.startTime}  →  ${slot.endTime}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.7) : AppColors.textHint,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}