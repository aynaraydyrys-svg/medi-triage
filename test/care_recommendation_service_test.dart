import 'package:flutter_test/flutter_test.dart';
import 'package:medimatch/services/ai_specialty_matcher_service.dart';
import 'package:medimatch/services/care_recommendation_service.dart';
import 'package:medimatch/services/emergency_triage_service.dart';
import 'package:medimatch/services/symptom_photo_triage_service.dart';

void main() {
  group('CareRecommendationService', () {
    test(
      'uses photo-assisted analysis to sharpen a visual specialty',
      () async {
        final service = CareRecommendationService(
          specialtyMatcher: AiSpecialtyMatcherService(),
          emergencyTriageService: EmergencyTriageService(),
          symptomPhotoTriageService: SymptomPhotoTriageService(),
        );

        final result = await service.analyzeCareNeed(
          symptomsText: 'There is redness and itching on my skin.',
          imageName: 'rash_photo.jpg',
        );

        expect(result.recommendedSpecialty, 'Dermatologist');
        expect(result.photoTriageResult, isNotNull);
      },
    );
  });
}
