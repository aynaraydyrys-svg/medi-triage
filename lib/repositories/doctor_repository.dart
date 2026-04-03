import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/doctor_profile.dart';
import '../services/preview_data_store.dart';

class DoctorRepository {
  DoctorRepository({
    FirebaseFirestore? firestore,
    PreviewDataStore? previewStore,
  }) : _firestore = firestore,
       _doctors = firestore?.collection('doctors'),
       _previewStore = previewStore;

  static const Duration _writeTimeout = Duration(seconds: 20);

  final FirebaseFirestore? _firestore;
  final CollectionReference<Map<String, dynamic>>? _doctors;
  final PreviewDataStore? _previewStore;

  bool get isPreviewMode => _previewStore != null;

  Stream<List<DoctorProfile>> streamDoctors({String? specialty, String? city}) {
    if (isPreviewMode) {
      return _previewStore!.watch(() {
        final doctors = _previewStore.doctors.values.where((doctor) {
          final matchesSpecialty =
              specialty == null ||
              specialty.isEmpty ||
              doctor.specialty == specialty;
          final matchesCity =
              city == null || city.isEmpty || doctor.city == city;
          return matchesSpecialty && matchesCity;
        }).toList()..sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
        return doctors;
      });
    }

    return _doctors!.snapshots().map((snapshot) {
      final doctors =
          snapshot.docs.map((doc) => DoctorProfile.fromMap(doc.data())).where((
              doctor,
            ) {
              final matchesSpecialty =
                  specialty == null ||
                  specialty.isEmpty ||
                  doctor.specialty == specialty;
              final matchesCity =
                  city == null || city.isEmpty || doctor.city == city;
              return matchesSpecialty && matchesCity;
            }).toList()
            ..sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
      return doctors;
    });
  }

  Stream<DoctorProfile?> streamDoctor(String doctorId) {
    if (isPreviewMode) {
      return _previewStore!.watch(() => _previewStore.doctors[doctorId]);
    }

    return _doctors!.doc(doctorId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return DoctorProfile.fromMap(snapshot.data()!);
    });
  }

  Future<DoctorProfile?> fetchDoctor(String doctorId) async {
    if (isPreviewMode) {
      return _previewStore!.doctors[doctorId];
    }

    final snapshot = await _doctors!.doc(doctorId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return DoctorProfile.fromMap(snapshot.data()!);
  }

  Future<void> upsertDoctorProfile(DoctorProfile doctor) {
    if (isPreviewMode) {
      debugPrint(
        'PHOTO DETAIL: upsertDoctorProfile started in preview mode for doctorId=${doctor.doctorId}',
      );
      _previewStore!.doctors[doctor.doctorId] = doctor;
      _previewStore.notify();
      debugPrint(
        'PHOTO DETAIL: upsertDoctorProfile finished in preview mode for doctorId=${doctor.doctorId}',
      );
      return Future.value();
    }

    debugPrint(
      'PHOTO DETAIL: upsertDoctorProfile started for doctorId=${doctor.doctorId}',
    );
    return _upsertDoctorProfileFirestore(doctor);
  }

  Future<void> _upsertDoctorProfileFirestore(DoctorProfile doctor) async {
    try {
      await _doctors!
          .doc(doctor.doctorId)
          .set(doctor.toMap(), SetOptions(merge: true))
          .timeout(_writeTimeout);
      debugPrint(
        'PHOTO DETAIL: upsertDoctorProfile finished for doctorId=${doctor.doctorId}',
      );
    } on TimeoutException catch (error, stackTrace) {
      debugPrint(
        'PHOTO DETAIL: upsertDoctorProfile timed out for doctorId=${doctor.doctorId}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      throw Exception('Doctor profile save timed out. Please try again.');
    } catch (error, stackTrace) {
      debugPrint(
        'PHOTO DETAIL: upsertDoctorProfile failed for doctorId=${doctor.doctorId}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> addAvailableSlot(String doctorId, DateTime slot) async {
    if (isPreviewMode) {
      final doctor = _previewStore!.doctors[doctorId];
      if (doctor == null) {
        return;
      }
      final slots = [...doctor.availableSlots];
      if (!slots.contains(slot)) {
        slots.add(slot);
      }
      slots.sort();
      _previewStore.doctors[doctorId] = doctor.copyWith(
        availableSlots: slots,
        updatedAt: DateTime.now(),
      );
      _previewStore.notify();
      return;
    }

    final doctorsCollection = _doctors!;
    final firestore = _firestore!;
    final ref = doctorsCollection.doc(doctorId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final slots = List<String>.from(
        snapshot.data()?['availableSlots'] ?? <String>[],
      );
      final slotIso = slot.toIso8601String();
      if (!slots.contains(slotIso)) {
        slots.add(slotIso);
      }
      slots.sort();
      transaction.set(ref, {
        'availableSlots': slots,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    });
  }

  Future<void> removeAvailableSlot(String doctorId, DateTime slot) async {
    if (isPreviewMode) {
      final doctor = _previewStore!.doctors[doctorId];
      if (doctor == null) {
        return;
      }
      final slots = [...doctor.availableSlots]..remove(slot);
      _previewStore.doctors[doctorId] = doctor.copyWith(
        availableSlots: slots,
        updatedAt: DateTime.now(),
      );
      _previewStore.notify();
      return;
    }

    final doctorsCollection = _doctors!;
    final firestore = _firestore!;
    final ref = doctorsCollection.doc(doctorId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final slots = List<String>.from(
        snapshot.data()?['availableSlots'] ?? <String>[],
      );
      slots.remove(slot.toIso8601String());
      transaction.set(ref, {
        'availableSlots': slots,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    });
  }

  Future<void> restoreSlotIfNeeded(String doctorId, DateTime slot) async {
    await addAvailableSlot(doctorId, slot);
  }

  Future<void> updateDoctorStats({
    required String doctorId,
    required double ratingAverage,
    required int reviewCount,
  }) {
    if (isPreviewMode) {
      final doctor = _previewStore!.doctors[doctorId];
      if (doctor != null) {
        _previewStore.doctors[doctorId] = doctor.copyWith(
          ratingAverage: ratingAverage,
          reviewCount: reviewCount,
          updatedAt: DateTime.now(),
        );
        _previewStore.notify();
      }
      return Future.value();
    }

    return _doctors!.doc(doctorId).set({
      'ratingAverage': ratingAverage,
      'reviewCount': reviewCount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<bool> hasAnyDoctors() async {
    if (isPreviewMode) {
      return _previewStore!.doctors.isNotEmpty;
    }

    final snapshot = await _doctors!.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}
