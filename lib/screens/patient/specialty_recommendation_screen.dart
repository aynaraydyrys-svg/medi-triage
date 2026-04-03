import 'package:flutter/material.dart';

import '../../core/enums/urgency_level.dart';
import '../../core/utils/app_constants.dart';
import '../../models/care_recommendation.dart';
import '../../models/symptom_log.dart';
import '../../theme/app_colors.dart';
import '../../widgets/adaptive_image.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/section_card.dart';
import '../../widgets/urgency_banner.dart';
import 'doctor_list_screen.dart';

class SpecialtyRecommendationScreen extends StatelessWidget {
  const SpecialtyRecommendationScreen({
    super.key,
    required this.recommendation,
    required this.symptomLog,
  });

  final CareRecommendation recommendation;
  final SymptomLog symptomLog;

  @override
  Widget build(BuildContext context) {
    final urgency = recommendation.triageAssessment.urgencyLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UrgencyBanner(assessment: recommendation.triageAssessment),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best match',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundAlt,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          AppConstants.specialtyLabel(
                            recommendation.recommendedSpecialty,
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(recommendation.reasoningSummary),
                      const SizedBox(height: 12),
                      Text(
                        '${(recommendation.specialtyMatch.confidenceScore * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (recommendation
                          .specialtyMatch
                          .matchedKeywords
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: recommendation
                              .specialtyMatch
                              .matchedKeywords
                              .map((keyword) => Chip(label: Text(keyword)))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (recommendation.photoTriageResult != null) ...[
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photo',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (symptomLog.symptomImageUrl != null &&
                            symptomLog.symptomImageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: AdaptiveImage(
                                imageUrl: symptomLog.symptomImageUrl!,
                                height: 220,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        Text(recommendation.photoTriageResult!.summary),
                        const SizedBox(height: 12),
                        Text(
                          recommendation.photoTriageResult!.sourceLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (recommendation
                            .photoTriageResult!
                            .visualSignals
                            .isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recommendation
                                .photoTriageResult!
                                .visualSignals
                                .map((signal) => Chip(label: Text(signal)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recommendation.triageAssessment.nextSteps
                            .map((step) => Chip(label: Text(step)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DoctorListScreen(
                        specialty: recommendation.recommendedSpecialty,
                        symptomLog: symptomLog,
                      ),
                    ),
                  ),
                  child: Text(
                    urgency == UrgencyLevel.canWait
                        ? 'Find doctor'
                        : 'Find today',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.matchingDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
