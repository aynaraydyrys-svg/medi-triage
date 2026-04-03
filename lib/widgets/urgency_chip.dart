import 'package:flutter/material.dart';

import '../core/enums/urgency_level.dart';
import '../theme/app_colors.dart';

class UrgencyChip extends StatelessWidget {
  const UrgencyChip({
    super.key,
    required this.urgencyLevel,
    this.compact = false,
  });

  final UrgencyLevel urgencyLevel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (urgencyLevel) {
      UrgencyLevel.canWait => AppColors.success,
      UrgencyLevel.bookToday => AppColors.warning,
      UrgencyLevel.emergency => AppColors.danger,
    };
    final background = switch (urgencyLevel) {
      UrgencyLevel.canWait => AppColors.successSoft,
      UrgencyLevel.bookToday => AppColors.warningSoft,
      UrgencyLevel.emergency => AppColors.dangerSoft,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        urgencyLevel.shortLabel,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 12 : 13,
        ),
      ),
    );
  }
}
