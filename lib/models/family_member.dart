import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/utils/firestore_parsers.dart';

class FamilyMember extends Equatable {
  const FamilyMember({
    required this.memberId,
    required this.ownerId,
    required this.name,
    required this.age,
    required this.gender,
    required this.relation,
    required this.createdAt,
    required this.updatedAt,
    this.chronicConditions = const <String>[],
    this.notes = '',
    this.visitHistory = const <String>[],
  });

  final String memberId;
  final String ownerId;
  final String name;
  final int age;
  final String gender;
  final String relation;
  final List<String> chronicConditions;
  final String notes;
  final List<String> visitHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyMember copyWith({
    String? name,
    int? age,
    String? gender,
    String? relation,
    List<String>? chronicConditions,
    String? notes,
    List<String>? visitHistory,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      memberId: memberId,
      ownerId: ownerId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      relation: relation ?? this.relation,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      notes: notes ?? this.notes,
      visitHistory: visitHistory ?? this.visitHistory,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'ownerId': ownerId,
      'name': name,
      'age': age,
      'gender': gender,
      'relation': relation,
      'chronicConditions': chronicConditions,
      'notes': notes,
      'visitHistory': visitHistory,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      memberId: map['memberId']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      age: parseInt(map['age']),
      gender: map['gender']?.toString() ?? '',
      relation: map['relation']?.toString() ?? '',
      chronicConditions: parseStringList(map['chronicConditions']),
      notes: map['notes']?.toString() ?? '',
      visitHistory: parseStringList(map['visitHistory']),
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    memberId,
    ownerId,
    name,
    age,
    gender,
    relation,
    chronicConditions,
    notes,
    visitHistory,
    createdAt,
    updatedAt,
  ];
}
