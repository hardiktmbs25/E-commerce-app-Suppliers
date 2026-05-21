// lib/module/subscriptions/widgets/time_slot_picker.dart
//
// Shows N time-slot buttons based on how many slots are required.
// Each button opens a TimePicker when tapped.
// Used on the Add Subscription screen for twice/thrice daily frequencies.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TimeSlotPicker extends StatelessWidget {
  /// Current slot values (may be empty string for unset slots)
  final List<String> slots;
  final int requiredCount;
  /// Called when user taps a slot – controller handles the picker
  final void Function(int index) onTapSlot;

  const TimeSlotPicker({
    super.key,
    required this.slots,
    required this.requiredCount,
    required this.onTapSlot,
  });

  static const _slotLabels = ['1st Delivery', '2nd Delivery', '3rd Delivery'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(requiredCount, (i) {
        final value = i < slots.length ? slots[i] : '';
        final isSet = value.isNotEmpty;
        final label = requiredCount > 1
            ? _slotLabels[i]
            : 'Delivery Time';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onTapSlot(i),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSet
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSet ? AppColors.primary : AppColors.border,
                  width: isSet ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 22,
                    color: isSet ? AppColors.primary : AppColors.textHint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isSet ? value : 'Tap to set $label',
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                        color: isSet ? AppColors.primary : AppColors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  if (requiredCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}