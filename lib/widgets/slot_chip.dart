import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../theme/app_colors.dart';

class SlotChip extends StatelessWidget {
  const SlotChip({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(AppFormatters.appointment.format(slot)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.backgroundAlt,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    );
  }
}
