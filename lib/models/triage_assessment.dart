import 'package:equatable/equatable.dart';

import '../core/enums/urgency_level.dart';

class TriageAssessment extends Equatable {
  const TriageAssessment({
    required this.urgencyLevel,
    required this.headline,
    required this.summary,
    required this.matchedSignals,
    required this.nextSteps,
    required this.disclaimer,
    required this.confidenceScore,
    required this.usedExternalAi,
  });

  final UrgencyLevel urgencyLevel;
  final String headline;
  final String summary;
  final List<String> matchedSignals;
  final List<String> nextSteps;
  final String disclaimer;
  final double confidenceScore;
  final bool usedExternalAi;

  @override
  List<Object?> get props => [
    urgencyLevel,
    headline,
    summary,
    matchedSignals,
    nextSteps,
    disclaimer,
    confidenceScore,
    usedExternalAi,
  ];
}
