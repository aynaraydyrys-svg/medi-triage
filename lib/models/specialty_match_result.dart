import 'package:equatable/equatable.dart';

class SpecialtyMatchResult extends Equatable {
  const SpecialtyMatchResult({
    required this.specialty,
    required this.explanation,
    required this.matchedKeywords,
    required this.confidenceScore,
    required this.usedExternalAi,
  });

  final String specialty;
  final String explanation;
  final List<String> matchedKeywords;
  final double confidenceScore;
  final bool usedExternalAi;

  @override
  List<Object?> get props => [
    specialty,
    explanation,
    matchedKeywords,
    confidenceScore,
    usedExternalAi,
  ];
}
