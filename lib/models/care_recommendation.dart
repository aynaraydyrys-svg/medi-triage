import 'package:equatable/equatable.dart';

import 'photo_triage_result.dart';
import 'specialty_match_result.dart';
import 'triage_assessment.dart';

class CareRecommendation extends Equatable {
  const CareRecommendation({
    required this.recommendedSpecialty,
    required this.specialtyMatch,
    required this.triageAssessment,
    required this.reasoningSummary,
    this.photoTriageResult,
  });

  final String recommendedSpecialty;
  final SpecialtyMatchResult specialtyMatch;
  final TriageAssessment triageAssessment;
  final PhotoTriageResult? photoTriageResult;
  final String reasoningSummary;

  bool get hasPhotoInsight => photoTriageResult != null;

  @override
  List<Object?> get props => [
    recommendedSpecialty,
    specialtyMatch,
    triageAssessment,
    photoTriageResult,
    reasoningSummary,
  ];
}
