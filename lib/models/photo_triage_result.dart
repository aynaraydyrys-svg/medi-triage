import 'package:equatable/equatable.dart';

class PhotoTriageResult extends Equatable {
  const PhotoTriageResult({
    required this.suggestedSpecialty,
    required this.summary,
    required this.visualSignals,
    required this.needsInPersonExam,
    required this.confidenceScore,
    required this.usedExternalAi,
    required this.sourceLabel,
  });

  final String suggestedSpecialty;
  final String summary;
  final List<String> visualSignals;
  final bool needsInPersonExam;
  final double confidenceScore;
  final bool usedExternalAi;
  final String sourceLabel;

  @override
  List<Object?> get props => [
    suggestedSpecialty,
    summary,
    visualSignals,
    needsInPersonExam,
    confidenceScore,
    usedExternalAi,
    sourceLabel,
  ];
}
