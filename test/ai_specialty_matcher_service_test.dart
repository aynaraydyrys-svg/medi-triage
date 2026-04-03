import 'package:flutter_test/flutter_test.dart';
import 'package:medimatch/services/ai_specialty_matcher_service.dart';

void main() {
  group('AiSpecialtyMatcherService', () {
    test('returns dermatologist for rash keywords', () async {
      final service = AiSpecialtyMatcherService();

      final result = await service.matchSymptoms(
        symptomsText: 'I have a skin rash with itching for three days.',
      );

      expect(result.specialty, 'Dermatologist');
      expect(result.matchedKeywords, isNotEmpty);
    });

    test('falls back to general practitioner for broad symptoms', () async {
      final service = AiSpecialtyMatcherService();

      final result = await service.matchSymptoms(
        symptomsText: 'I feel generally unwell and tired.',
      );

      expect(result.specialty, 'General Practitioner');
    });
  });
}
