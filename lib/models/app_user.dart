import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/enums/subscription_plan.dart';
import '../core/enums/user_role.dart';
import '../core/utils/firestore_parsers.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.isEmailVerified,
    this.photoUrl,
    this.fcmToken,
    this.city = '',
    this.age,
    this.gender = '',
    this.basicMedicalInfo = '',
    this.medicalHistory = const <String>[],
    this.pastDiseases = const <String>[],
    this.allergies = const <String>[],
    this.treatments = const <String>[],
    this.bloodTestResults = const <String>[],
    this.notes = '',
    this.isPremium = false,
    this.subscriptionPlan = SubscriptionPlan.basic,
    this.usageDateKey = '',
    this.photoAnalysesUsedToday = 0,
    this.aiAnalysesUsedToday = 0,
  });

  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isEmailVerified;
  final String? fcmToken;
  final String city;
  final int? age;
  final String gender;
  final String basicMedicalInfo;
  final List<String> medicalHistory;
  final List<String> pastDiseases;
  final List<String> allergies;
  final List<String> treatments;
  final List<String> bloodTestResults;
  final String notes;
  final bool isPremium;
  final SubscriptionPlan subscriptionPlan;
  final String usageDateKey;
  final int photoAnalysesUsedToday;
  final int aiAnalysesUsedToday;

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    UserRole? role,
    String? photoUrl,
    bool? isEmailVerified,
    String? fcmToken,
    String? city,
    int? age,
    String? gender,
    String? basicMedicalInfo,
    List<String>? medicalHistory,
    List<String>? pastDiseases,
    List<String>? allergies,
    List<String>? treatments,
    List<String>? bloodTestResults,
    String? notes,
    bool? isPremium,
    SubscriptionPlan? subscriptionPlan,
    String? usageDateKey,
    int? photoAnalysesUsedToday,
    int? aiAnalysesUsedToday,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      fcmToken: fcmToken ?? this.fcmToken,
      city: city ?? this.city,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      basicMedicalInfo: basicMedicalInfo ?? this.basicMedicalInfo,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      pastDiseases: pastDiseases ?? this.pastDiseases,
      allergies: allergies ?? this.allergies,
      treatments: treatments ?? this.treatments,
      bloodTestResults: bloodTestResults ?? this.bloodTestResults,
      notes: notes ?? this.notes,
      isPremium: isPremium ?? this.isPremium,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      usageDateKey: usageDateKey ?? this.usageDateKey,
      photoAnalysesUsedToday:
          photoAnalysesUsedToday ?? this.photoAnalysesUsedToday,
      aiAnalysesUsedToday: aiAnalysesUsedToday ?? this.aiAnalysesUsedToday,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role.value,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEmailVerified': isEmailVerified,
      'fcmToken': fcmToken,
      'city': city,
      'age': age,
      'gender': gender,
      'basicMedicalInfo': basicMedicalInfo,
      'medicalHistory': medicalHistory,
      'pastDiseases': pastDiseases,
      'allergies': allergies,
      'treatments': treatments,
      'bloodTestResults': bloodTestResults,
      'notes': notes,
      'isPremium': isPremium,
      'subscriptionPlan': subscriptionPlan.value,
      'usageDateKey': usageDateKey,
      'photoAnalysesUsedToday': photoAnalysesUsedToday,
      'aiAnalysesUsedToday': aiAnalysesUsedToday,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final resolvedPlan = SubscriptionPlanX.fromValue(
      map['subscriptionPlan']?.toString() ??
          (parseBool(map['isPremium']) ? 'pro' : 'basic'),
    );

    return AppUser(
      uid: map['uid']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: UserRoleX.fromValue(map['role']?.toString() ?? 'patient'),
      photoUrl: map['photoUrl']?.toString(),
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      isEmailVerified: map['isEmailVerified'] == true,
      fcmToken: map['fcmToken']?.toString(),
      city: map['city']?.toString() ?? '',
      age: map['age'] == null ? null : parseInt(map['age']),
      gender: map['gender']?.toString() ?? '',
      basicMedicalInfo: map['basicMedicalInfo']?.toString() ?? '',
      medicalHistory: parseStringList(map['medicalHistory']),
      pastDiseases: parseStringList(map['pastDiseases']),
      allergies: parseStringList(map['allergies']),
      treatments: parseStringList(map['treatments']),
      bloodTestResults: parseStringList(map['bloodTestResults']),
      notes: map['notes']?.toString() ?? '',
      isPremium: parseBool(map['isPremium']) || resolvedPlan.isPremium,
      subscriptionPlan: resolvedPlan,
      usageDateKey: map['usageDateKey']?.toString() ?? '',
      photoAnalysesUsedToday: parseInt(map['photoAnalysesUsedToday']),
      aiAnalysesUsedToday: parseInt(map['aiAnalysesUsedToday']),
    );
  }

  @override
  List<Object?> get props => [
        uid,
        fullName,
        email,
        role,
        photoUrl,
        createdAt,
        isEmailVerified,
        fcmToken,
        city,
        age,
        gender,
        basicMedicalInfo,
        medicalHistory,
        pastDiseases,
        allergies,
        treatments,
        bloodTestResults,
        notes,
        isPremium,
        subscriptionPlan,
        usageDateKey,
        photoAnalysesUsedToday,
        aiAnalysesUsedToday,
      ];
}