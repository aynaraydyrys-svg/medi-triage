import 'package:flutter/material.dart';

import '../core/enums/appointment_status.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AppointmentStatus.pending => AppColors.warning,
      AppointmentStatus.confirmed => AppColors.primary,
      AppointmentStatus.cancelled => AppColors.danger,
      AppointmentStatus.completed => AppColors.success,
    };
    final background = switch (status) {
      AppointmentStatus.pending => AppColors.warningSoft,
      AppointmentStatus.confirmed => AppColors.backgroundAlt,
      AppointmentStatus.cancelled => AppColors.dangerSoft,
      AppointmentStatus.completed => AppColors.successSoft,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
