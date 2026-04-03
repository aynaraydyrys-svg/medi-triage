import 'package:flutter_test/flutter_test.dart';
import 'package:medimatch/core/enums/urgency_level.dart';
import 'package:medimatch/services/emergency_triage_service.dart';

void main() {
  group('EmergencyTriageService', () {
    test('flags chest pain with breathing trouble as emergency', () async {
      final service = EmergencyTriageService();

      final result = await service.assessUrgency(
        symptomsText:
            'I have chest pain and shortness of breath that is getting worse.',
      );

      expect(result.urgencyLevel, UrgencyLevel.emergency);
      expect(result.matchedSignals, isNotEmpty);
    });

    test('recommends same-day care for persistent rash and swelling', () async {
      final service = EmergencyTriageService();

      final result = await service.assessUrgency(
        symptomsText:
            'I have a spreading rash with swelling for three days and it is worsening.',
      );

      expect(result.urgencyLevel, UrgencyLevel.bookToday);
    });
  });
}
