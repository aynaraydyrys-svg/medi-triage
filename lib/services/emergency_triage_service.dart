import 'dart:math';

import '../core/enums/urgency_level.dart';
import '../core/utils/app_constants.dart';
import '../models/photo_triage_result.dart';
import '../models/triage_assessment.dart';

class EmergencyTriageService {
  Future<TriageAssessment> assessUrgency({
    required String symptomsText,
    String? specialtyHint,
    PhotoTriageResult? photoTriageResult,
  }) async {
    final text = symptomsText.toLowerCase();
    final emergencySignals = <String>[];

    if ((_containsAny(text, _chestPainSignals) &&
            _containsAny(text, _breathingSignals)) ||
        _containsAny(text, _directEmergencySignals)) {
      emergencySignals.add('Chest or breathing');
    }
    if (_containsAny(text, _strokeSignals)) {
      emergencySignals.add('Stroke risk');
    }
    if (_containsAny(text, _severeAllergySignals)) {
      emergencySignals.add('Severe allergy');
    }
    if (_containsAny(text, _lossOfConsciousnessSignals)) {
      emergencySignals.add('Loss of consciousness');
    }
    if (_containsAny(text, _majorBleedingSignals)) {
      emergencySignals.add('Bleeding');
    }

    if (emergencySignals.isNotEmpty) {
      return TriageAssessment(
        urgencyLevel: UrgencyLevel.emergency,
        headline: 'Red risk',
        summary: 'Get help now',
        matchedSignals: emergencySignals,
        nextSteps: const <String>['103', 'Now', 'Do not wait'],
        disclaimer: AppConstants.triageDisclaimer,
        confidenceScore: min(0.99, 0.9 + (emergencySignals.length * 0.03)),
        usedExternalAi: false,
      );
    }

    final sameDaySignals = <String>[];
    if (_containsAny(text, _persistentSignals)) {
      sameDaySignals.add('Symptoms continue');
    }
    if (_containsAny(text, _sameDayReviewSignals)) {
      sameDaySignals.add('Doctor needed');
    }
    if (_needsSameDayBySpecialty(specialtyHint)) {
      sameDaySignals.add('Do not delay');
    }
    if (photoTriageResult != null &&
        photoTriageResult.needsInPersonExam &&
        photoTriageResult.confidenceScore >= 0.68) {
      sameDaySignals.add('Photo suggests in-person care');
    }

    if (sameDaySignals.isNotEmpty) {
      return TriageAssessment(
        urgencyLevel: UrgencyLevel.bookToday,
        headline: 'Doctor needed',
        summary: 'Best today',
        matchedSignals: sameDaySignals,
        nextSteps: const <String>['Book', 'Today', 'Photo'],
        disclaimer: AppConstants.triageDisclaimer,
        confidenceScore: min(0.92, 0.72 + (sameDaySignals.length * 0.05)),
        usedExternalAi: false,
      );
    }

    final routineSignals = <String>[
      if (specialtyHint != null && specialtyHint.isNotEmpty)
        'No high risk found',
      if (photoTriageResult != null) 'Photo saved',
    ];

    return TriageAssessment(
      urgencyLevel: UrgencyLevel.canWait,
      headline: 'Low risk',
      summary: 'Can wait',
      matchedSignals: routineSignals,
      nextSteps: const <String>['Monitor', 'Later'],
      disclaimer: AppConstants.triageDisclaimer,
      confidenceScore: 0.62,
      usedExternalAi: false,
    );
  }

  bool _containsAny(String text, List<String> patterns) {
    return patterns.any(text.contains);
  }

  bool _needsSameDayBySpecialty(String? specialtyHint) {
    if (specialtyHint == null || specialtyHint.isEmpty) {
      return false;
    }
    return const <String>{
      'Cardiologist',
      'Neurologist',
      'Pulmonologist',
      'Gastroenterologist',
    }.contains(specialtyHint);
  }

  static const List<String> _chestPainSignals = <String>[
    'chest pain',
    'боль в груди',
    'chest tightness',
    'давит в груди',
    'chest pressure',
    'crushing chest',
  ];

  static const List<String> _breathingSignals = <String>[
    'shortness of breath',
    'одышка',
    'breathless',
    'trouble breathing',
    'трудно дышать',
    'cannot breathe',
    'cant breathe',
    'difficulty breathing',
  ];

  static const List<String> _directEmergencySignals = <String>[
    'throat closing',
    'перекрывает горло',
    'blue lips',
    'синие губы',
    'severe burns',
    'сильный ожог',
    'severe allergic reaction',
  ];

  static const List<String> _strokeSignals = <String>[
    'slurred speech',
    'невнятная речь',
    'face droop',
    'facial droop',
    'перекос лица',
    'one-sided weakness',
    'слабость с одной стороны',
    'weakness on one side',
    'sudden confusion',
    'спутанность',
    'unable to speak',
  ];

  static const List<String> _severeAllergySignals = <String>[
    'swollen lips',
    'отек губ',
    'swollen tongue',
    'отек языка',
    'throat swelling',
    'отек горла',
    'anaphylaxis',
    'wheezing after allergy',
  ];

  static const List<String> _lossOfConsciousnessSignals = <String>[
    'passed out',
    'потеря сознания',
    'fainted',
    'обморок',
    'unconscious',
    'seizure',
    'convulsion',
  ];

  static const List<String> _majorBleedingSignals = <String>[
    'heavy bleeding',
    'сильное кровотечение',
    'bleeding will not stop',
    'кровь не останавливается',
    'blood everywhere',
    'deep cut',
    'глубокий порез',
    'serious injury',
  ];

  static const List<String> _persistentSignals = <String>[
    'worsening',
    'хуже',
    'getting worse',
    'ухудшается',
    'persistent',
    'не проходит',
    'for three days',
    'for 3 days',
    'три дня',
    'for two days',
    'for 2 days',
    'два дня',
    'for a week',
    'неделю',
  ];

  static const List<String> _sameDayReviewSignals = <String>[
    'high fever',
    'высокая температура',
    'vomiting',
    'рвота',
    'severe pain',
    'сильная боль',
    'spreading rash',
    'сыпь распространяется',
    'swelling',
    'отек',
    'infection',
    'инфекция',
    'migraine',
    'мигрень',
    'dizziness',
    'головокружение',
    'blood in stool',
    'кровь в стуле',
    'blood in urine',
    'кровь в моче',
  ];
}
