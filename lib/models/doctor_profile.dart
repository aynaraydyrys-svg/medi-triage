import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/enums/doctor_availability_status.dart';
import '../core/utils/firestore_parsers.dart';

class DoctorProfile extends Equatable {
  const DoctorProfile({
    required this.doctorId,
    required this.uid,
    required this.name,
    required this.specialty,
    required this.bio,
    required this.clinicName,
    this.address = '',
    required this.city,
    required this.yearsExperience,
    required this.ratingAverage,
    required this.reviewCount,
    required this.availableSlots,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
    this.availabilityStatus = DoctorAvailabilityStatus.accepting,
    this.statusNote,
    this.offersTelehealth = false,
  });

  final String doctorId;
  final String uid;
  final String name;
  final String specialty;
  final String bio;
  final String clinicName;
  final String address;
  final String city;
  final int yearsExperience;
  final double ratingAverage;
  final int reviewCount;
  final String? profileImageUrl;
  final List<DateTime> availableSlots;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DoctorAvailabilityStatus availabilityStatus;
  final String? statusNote;
  final bool offersTelehealth;

  DoctorProfile copyWith({
    String? name,
    String? specialty,
    String? bio,
    String? clinicName,
    String? address,
    String? city,
    int? yearsExperience,
    double? ratingAverage,
    int? reviewCount,
    String? profileImageUrl,
    List<DateTime>? availableSlots,
    DateTime? updatedAt,
    DoctorAvailabilityStatus? availabilityStatus,
    String? statusNote,
    bool? offersTelehealth,
  }) {
    return DoctorProfile(
      doctorId: doctorId,
      uid: uid,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
      clinicName: clinicName ?? this.clinicName,
      address: address ?? this.address,
      city: city ?? this.city,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      reviewCount: reviewCount ?? this.reviewCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      availableSlots: availableSlots ?? this.availableSlots,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      statusNote: statusNote ?? this.statusNote,
      offersTelehealth: offersTelehealth ?? this.offersTelehealth,
    );
  }

  bool get isAvailableToday {
    final now = DateTime.now();
    return availableSlots.any(
      (slot) =>
          slot.isAfter(now) &&
          slot.year == now.year &&
          slot.month == now.month &&
          slot.day == now.day,
    );
  }

  DateTime? get nextAvailableSlot {
    final now = DateTime.now();
    for (final slot in availableSlots) {
      if (slot.isAfter(now)) {
        return slot;
      }
    }
    return null;
  }

  DateTime? get nextAvailableTodaySlot {
    final now = DateTime.now();
    for (final slot in availableSlots) {
      if (!slot.isAfter(now)) {
        continue;
      }
      if (slot.year == now.year &&
          slot.month == now.month &&
          slot.day == now.day) {
        return slot;
      }
    }
    return null;
  }

  bool get hasUrgentSlotToday => nextAvailableTodaySlot != null;

  String get displayAddress =>
      address.trim().isEmpty ? '$clinicName, $city' : address;

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'uid': uid,
      'name': name,
      'specialty': specialty,
      'bio': bio,
      'clinicName': clinicName,
      'address': address,
      'city': city,
      'yearsExperience': yearsExperience,
      'ratingAverage': ratingAverage,
      'reviewCount': reviewCount,
      'profileImageUrl': profileImageUrl,
      'availableSlots': availableSlots
          .map((slot) => slot.toIso8601String())
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'availabilityStatus': availabilityStatus.value,
      'statusNote': statusNote,
      'offersTelehealth': offersTelehealth,
    };
  }

  factory DoctorProfile.fromMap(Map<String, dynamic> map) {
    return DoctorProfile(
      doctorId: map['doctorId']?.toString() ?? '',
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      specialty: map['specialty']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      clinicName: map['clinicName']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      yearsExperience: parseInt(map['yearsExperience']),
      ratingAverage: parseDouble(map['ratingAverage']),
      reviewCount: parseInt(map['reviewCount']),
      profileImageUrl: map['profileImageUrl']?.toString(),
      availableSlots:
          parseStringList(map['availableSlots'])
              .map((item) => DateTime.tryParse(item))
              .whereType<DateTime>()
              .toList()
            ..sort(),
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']) ?? DateTime.now(),
      availabilityStatus: DoctorAvailabilityStatusX.fromValue(
        map['availabilityStatus']?.toString() ?? 'accepting',
      ),
      statusNote: map['statusNote']?.toString(),
      offersTelehealth: parseBool(map['offersTelehealth']),
    );
  }

  @override
  List<Object?> get props => [
    doctorId,
    uid,
    name,
    specialty,
    bio,
    clinicName,
    address,
    city,
    yearsExperience,
    ratingAverage,
    reviewCount,
    profileImageUrl,
    availableSlots,
    createdAt,
    updatedAt,
    availabilityStatus,
    statusNote,
    offersTelehealth,
  ];
}
