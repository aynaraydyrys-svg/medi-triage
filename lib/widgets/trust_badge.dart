import 'package:flutter/material.dart';

import '../models/doctor_trust_insight.dart';
import '../theme/app_colors.dart';

class TrustBadge extends StatelessWidget {
  const TrustBadge({super.key, required this.insight, this.compact = false});

  final DoctorTrustInsight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!insight.hasTrustedVisits) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              insight.badgeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
