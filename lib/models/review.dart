import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/utils/firestore_parsers.dart';

class Review extends Equatable {
  const Review({
    required this.reviewId,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String reviewId;
  final String doctorId;
  final String patientId;
  final String patientName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      reviewId: map['reviewId']?.toString() ?? '',
      doctorId: map['doctorId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      rating: parseInt(map['rating']),
      comment: map['comment']?.toString() ?? '',
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    reviewId,
    doctorId,
    patientId,
    patientName,
    rating,
    comment,
    createdAt,
  ];
}
