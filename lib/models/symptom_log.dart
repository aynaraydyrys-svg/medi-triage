import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/enums/urgency_level.dart';
import '../core/utils/firestore_parsers.dart';

class SymptomLog extends Equatable {
  const SymptomLog({
    required this.logId,
    required this.patientId,
    required this.symptomsText,
    required this.aiRecommendedSpecialty,
    required this.createdAt,
    required this.matchedKeywords,
    this.symptomImageUrl,
    this.urgencyLevel,
    this.triageSummary,
    this.photoSuggestedSpecialty,
    this.photoTriageSummary,
  });

  final String logId;
  final String patientId;
  final String symptomsText;
  final String? symptomImageUrl;
  final String aiRecommendedSpecialty;
  final DateTime createdAt;
  final List<String> matchedKeywords;
  final UrgencyLevel? urgencyLevel;
  final String? triageSummary;
  final String? photoSuggestedSpecialty;
  final String? photoTriageSummary;

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'patientId': patientId,
      'symptomsText': symptomsText,
      'symptomImageUrl': symptomImageUrl,
      'aiRecommendedSpecialty': aiRecommendedSpecialty,
      'matchedKeywords': matchedKeywords,
      'createdAt': Timestamp.fromDate(createdAt),
      'urgencyLevel': urgencyLevel?.value,
      'triageSummary': triageSummary,
      'photoSuggestedSpecialty': photoSuggestedSpecialty,
      'photoTriageSummary': photoTriageSummary,
    };
  }

  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    return SymptomLog(
      logId: map['logId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      symptomsText: map['symptomsText']?.toString() ?? '',
      symptomImageUrl: map['symptomImageUrl']?.toString(),
      aiRecommendedSpecialty:
          map['aiRecommendedSpecialty']?.toString() ?? 'General Practitioner',
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      matchedKeywords: parseStringList(map['matchedKeywords']),
      urgencyLevel: map['urgencyLevel'] == null
          ? null
          : UrgencyLevelX.fromValue(map['urgencyLevel']?.toString() ?? ''),
      triageSummary: map['triageSummary']?.toString(),
      photoSuggestedSpecialty: map['photoSuggestedSpecialty']?.toString(),
      photoTriageSummary: map['photoTriageSummary']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    logId,
    patientId,
    symptomsText,
    symptomImageUrl,
    aiRecommendedSpecialty,
    createdAt,
    matchedKeywords,
    urgencyLevel,
    triageSummary,
    photoSuggestedSpecialty,
    photoTriageSummary,
  ];
}
