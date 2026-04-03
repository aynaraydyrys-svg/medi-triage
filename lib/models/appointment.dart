import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/enums/appointment_status.dart';
import '../core/enums/urgency_level.dart';
import '../core/utils/firestore_parsers.dart';

class Appointment extends Equatable {
  const Appointment({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.symptomsText,
    required this.slotTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.doctorImageUrl,
    this.symptomImageUrl,
    this.urgencyLevel,
    this.aiSummary,
    this.familyMemberId,
    this.careRecipientRelation,
    this.bookedByName,
  });

  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String symptomsText;
  final String? symptomImageUrl;
  final DateTime slotTime;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? doctorImageUrl;
  final UrgencyLevel? urgencyLevel;
  final String? aiSummary;
  final String? familyMemberId;
  final String? careRecipientRelation;
  final String? bookedByName;

  bool get isFamilyBooking =>
      familyMemberId != null && familyMemberId!.trim().isNotEmpty;

  Appointment copyWith({
    AppointmentStatus? status,
    DateTime? updatedAt,
    UrgencyLevel? urgencyLevel,
    String? aiSummary,
  }) {
    return Appointment(
      appointmentId: appointmentId,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty,
      symptomsText: symptomsText,
      symptomImageUrl: symptomImageUrl,
      slotTime: slotTime,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      doctorImageUrl: doctorImageUrl,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      aiSummary: aiSummary ?? this.aiSummary,
      familyMemberId: familyMemberId,
      careRecipientRelation: careRecipientRelation,
      bookedByName: bookedByName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorImageUrl': doctorImageUrl,
      'specialty': specialty,
      'symptomsText': symptomsText,
      'symptomImageUrl': symptomImageUrl,
      'slotTime': Timestamp.fromDate(slotTime),
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'urgencyLevel': urgencyLevel?.value,
      'aiSummary': aiSummary,
      'familyMemberId': familyMemberId,
      'careRecipientRelation': careRecipientRelation,
      'bookedByName': bookedByName,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      appointmentId: map['appointmentId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      doctorId: map['doctorId']?.toString() ?? '',
      doctorName: map['doctorName']?.toString() ?? '',
      doctorImageUrl: map['doctorImageUrl']?.toString(),
      specialty: map['specialty']?.toString() ?? '',
      symptomsText: map['symptomsText']?.toString() ?? '',
      symptomImageUrl: map['symptomImageUrl']?.toString(),
      slotTime: parseDateTime(map['slotTime']) ?? DateTime.now(),
      status: AppointmentStatusX.fromValue(
        map['status']?.toString() ?? AppointmentStatus.pending.value,
      ),
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']) ?? DateTime.now(),
      urgencyLevel: map['urgencyLevel'] == null
          ? null
          : UrgencyLevelX.fromValue(map['urgencyLevel']?.toString() ?? ''),
      aiSummary: map['aiSummary']?.toString(),
      familyMemberId: map['familyMemberId']?.toString(),
      careRecipientRelation: map['careRecipientRelation']?.toString(),
      bookedByName: map['bookedByName']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    appointmentId,
    patientId,
    patientName,
    doctorId,
    doctorName,
    doctorImageUrl,
    specialty,
    symptomsText,
    symptomImageUrl,
    slotTime,
    status,
    createdAt,
    updatedAt,
    urgencyLevel,
    aiSummary,
    familyMemberId,
    careRecipientRelation,
    bookedByName,
  ];
}
