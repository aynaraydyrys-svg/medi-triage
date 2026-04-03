import 'package:flutter/material.dart';

import '../core/enums/urgency_level.dart';
import '../models/triage_assessment.dart';
import '../theme/app_colors.dart';
import 'section_card.dart';

class UrgencyBanner extends StatelessWidget {
  const UrgencyBanner({super.key, required this.assessment});

  final TriageAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final urgency = assessment.urgencyLevel;
    final color = switch (urgency) {
      UrgencyLevel.canWait => AppColors.success,
      UrgencyLevel.bookToday => AppColors.warning,
      UrgencyLevel.emergency => AppColors.danger,
    };
    final softColor = switch (urgency) {
      UrgencyLevel.canWait => AppColors.successSoft,
      UrgencyLevel.bookToday => AppColors.warningSoft,
      UrgencyLevel.emergency => AppColors.dangerSoft,
    };
    final icon = switch (urgency) {
      UrgencyLevel.canWait => Icons.check_circle_outline_rounded,
      UrgencyLevel.bookToday => Icons.watch_later_outlined,
      UrgencyLevel.emergency => Icons.emergency_rounded,
    };

    return SectionCard(
      backgroundColor: softColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      urgency.label,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assessment.headline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (assessment.summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              assessment.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (assessment.matchedSignals.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: assessment.matchedSignals
                  .map(
                    (signal) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        signal,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            assessment.disclaimer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
