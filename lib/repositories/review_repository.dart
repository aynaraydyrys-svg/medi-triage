import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';
import '../services/preview_data_store.dart';
import 'doctor_repository.dart';

class ReviewRepository {
  ReviewRepository({
    FirebaseFirestore? firestore,
    required DoctorRepository doctorRepository,
    PreviewDataStore? previewStore,
  }) : _doctorRepository = doctorRepository,
       _reviews = firestore?.collection('reviews'),
       _previewStore = previewStore;

  final DoctorRepository _doctorRepository;
  final CollectionReference<Map<String, dynamic>>? _reviews;
  final PreviewDataStore? _previewStore;

  bool get isPreviewMode => _previewStore != null;

  Stream<List<Review>> streamDoctorReviews(String doctorId) {
    if (isPreviewMode) {
      return _previewStore!.watch(
        () => _sortReviews(
          _previewStore.reviews.values
              .where((review) => review.doctorId == doctorId)
              .toList(),
        ),
      );
    }

    return _reviews!.where('doctorId', isEqualTo: doctorId).snapshots().map((
      snapshot,
    ) {
      final reviews = snapshot.docs
          .map((doc) => Review.fromMap(doc.data()))
          .toList();
      return _sortReviews(reviews);
    });
  }

  Future<List<Review>> fetchDoctorReviews(String doctorId) async {
    if (isPreviewMode) {
      return _sortReviews(
        _previewStore!.reviews.values
            .where((review) => review.doctorId == doctorId)
            .toList(),
      );
    }

    final snapshot = await _reviews!
        .where('doctorId', isEqualTo: doctorId)
        .get();
    final reviews = snapshot.docs
        .map((doc) => Review.fromMap(doc.data()))
        .toList();
    return _sortReviews(reviews);
  }

  Future<void> addReview(Review review, {bool recalculateOnly = false}) async {
    if (isPreviewMode) {
      _previewStore!.reviews[review.reviewId] = review;
      await _recalculateDoctorRating(review.doctorId);
      return;
    }

    if (!recalculateOnly) {
      await _reviews!.doc(review.reviewId).set(review.toMap());
    } else {
      await _reviews!
          .doc(review.reviewId)
          .set(review.toMap(), SetOptions(merge: true));
    }
    await _recalculateDoctorRating(review.doctorId);
  }

  Future<void> deleteReview({
    required String reviewId,
    required String doctorId,
  }) async {
    if (isPreviewMode) {
      _previewStore!.reviews.remove(reviewId);
      await _recalculateDoctorRating(doctorId);
      return;
    }

    await _reviews!.doc(reviewId).delete();
    await _recalculateDoctorRating(doctorId);
  }

  Future<bool> hasPatientReviewedDoctor({
    required String doctorId,
    required String patientId,
  }) async {
    return (await fetchPatientReview(
          doctorId: doctorId,
          patientId: patientId,
        )) !=
        null;
  }

  Future<Review?> fetchPatientReview({
    required String doctorId,
    required String patientId,
  }) async {
    if (isPreviewMode) {
      try {
        return _previewStore!.reviews.values.firstWhere(
          (review) =>
              review.doctorId == doctorId && review.patientId == patientId,
        );
      } catch (_) {
        return null;
      }
    }

    final snapshot = await _reviews!
        .where('doctorId', isEqualTo: doctorId)
        .where('patientId', isEqualTo: patientId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return Review.fromMap(snapshot.docs.first.data());
  }

  Future<void> _recalculateDoctorRating(String doctorId) async {
    final reviews = await fetchDoctorReviews(doctorId);
    final total = reviews.fold<int>(
      0,
      (runningTotal, review) => runningTotal + review.rating,
    );
    final reviewCount = reviews.length;
    final average = reviewCount == 0 ? 0.0 : total / reviewCount;

    await _doctorRepository.updateDoctorStats(
      doctorId: doctorId,
      ratingAverage: average,
      reviewCount: reviewCount,
    );
  }

  List<Review> _sortReviews(List<Review> reviews) {
    return reviews..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
