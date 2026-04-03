import '../models/care_recommendation.dart';
import '../models/photo_triage_result.dart';
import '../models/specialty_match_result.dart';
import 'ai_specialty_matcher_service.dart';
import 'emergency_triage_service.dart';
import 'symptom_photo_triage_service.dart';

class CareRecommendationService {
  CareRecommendationService({
    required AiSpecialtyMatcherService specialtyMatcher,
    required EmergencyTriageService emergencyTriageService,
    required SymptomPhotoTriageService symptomPhotoTriageService,
  }) : _specialtyMatcher = specialtyMatcher,
       _emergencyTriageService = emergencyTriageService,
       _symptomPhotoTriageService = symptomPhotoTriageService;

  final AiSpecialtyMatcherService _specialtyMatcher;
  final EmergencyTriageService _emergencyTriageService;
  final SymptomPhotoTriageService _symptomPhotoTriageService;

  Future<CareRecommendation> analyzeCareNeed({
    required String symptomsText,
    String? symptomImageUrl,
    String? imageName,
  }) async {
    final specialtyMatch = await _specialtyMatcher.matchSymptoms(
      symptomsText: symptomsText,
      symptomImageUrl: symptomImageUrl,
    );

    PhotoTriageResult? photoTriageResult;
    if ((symptomImageUrl != null && symptomImageUrl.isNotEmpty) ||
        (imageName != null && imageName.isNotEmpty)) {
      photoTriageResult = await _symptomPhotoTriageService.analyzePhoto(
        symptomsText: symptomsText,
        imageName: imageName ?? 'symptom-photo.jpg',
        imageUrl: symptomImageUrl,
        specialtyHint: specialtyMatch.specialty,
      );
    }

    final triageAssessment = await _emergencyTriageService.assessUrgency(
      symptomsText: symptomsText,
      specialtyHint: specialtyMatch.specialty,
      photoTriageResult: photoTriageResult,
    );

    final recommendedSpecialty = _resolveSpecialty(
      specialtyMatch: specialtyMatch,
      photoTriageResult: photoTriageResult,
    );

    return CareRecommendation(
      recommendedSpecialty: recommendedSpecialty,
      specialtyMatch: specialtyMatch,
      triageAssessment: triageAssessment,
      photoTriageResult: photoTriageResult,
      reasoningSummary: _buildReasoningSummary(
        specialtyMatch: specialtyMatch,
        photoTriageResult: photoTriageResult,
        recommendedSpecialty: recommendedSpecialty,
      ),
    );
  }

  String _resolveSpecialty({
    required SpecialtyMatchResult specialtyMatch,
    PhotoTriageResult? photoTriageResult,
  }) {
    if (photoTriageResult == null) {
      return specialtyMatch.specialty;
    }

    if (photoTriageResult.suggestedSpecialty == specialtyMatch.specialty) {
      return specialtyMatch.specialty;
    }

    if (specialtyMatch.specialty == 'General Practitioner' &&
        photoTriageResult.confidenceScore >= 0.64) {
      return photoTriageResult.suggestedSpecialty;
    }

    if (photoTriageResult.suggestedSpecialty == 'Dermatologist' &&
        photoTriageResult.visualSignals.isNotEmpty) {
      return photoTriageResult.suggestedSpecialty;
    }

    if (photoTriageResult.suggestedSpecialty == 'Surgeon' &&
        photoTriageResult.confidenceScore >= 0.68) {
      return photoTriageResult.suggestedSpecialty;
    }

    return specialtyMatch.specialty;
  }

  String _buildReasoningSummary({
    required SpecialtyMatchResult specialtyMatch,
    required String recommendedSpecialty,
    PhotoTriageResult? photoTriageResult,
  }) {
    if (photoTriageResult == null) {
      return specialtyMatch.explanation;
    }

    if (recommendedSpecialty == specialtyMatch.specialty &&
        recommendedSpecialty == photoTriageResult.suggestedSpecialty) {
      return 'Text and photo match';
    }

    if (recommendedSpecialty == photoTriageResult.suggestedSpecialty &&
        recommendedSpecialty != specialtyMatch.specialty) {
      return 'Photo refined the choice';
    }

    return 'Text leads, photo helps';
  }
}
