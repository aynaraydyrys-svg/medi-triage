import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/enums/subscription_plan.dart';
import '../models/app_user.dart';
import '../services/preview_data_store.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore, PreviewDataStore? previewStore})
    : _users = firestore?.collection('users'),
      _previewStore = previewStore;

  static const Duration _writeTimeout = Duration(seconds: 20);

  final CollectionReference<Map<String, dynamic>>? _users;
  final PreviewDataStore? _previewStore;

  bool get isPreviewMode => _previewStore != null;

  Future<void> createUserDocument(AppUser user) {
    if (isPreviewMode) {
      _previewStore!.users[user.uid] = user;
      _previewStore.notify();
      return Future.value();
    }
    return _users!.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<AppUser?> streamUser(String uid) {
    if (isPreviewMode) {
      return _previewStore!.watch(() => _previewStore.users[uid]);
    }

    return _users!.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return AppUser.fromMap(snapshot.data()!);
    });
  }

  Future<AppUser?> fetchUser(String uid) async {
    if (isPreviewMode) {
      return _previewStore!.users[uid];
    }

    final snapshot = await _users!.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return AppUser.fromMap(snapshot.data()!);
  }

  Future<bool> userExistsByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (isPreviewMode) {
      return _previewStore!.users.values.any(
        (user) => user.email.trim().toLowerCase() == normalizedEmail,
      );
    }

    final snapshot = await _users!
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<AppUser?> fetchUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (isPreviewMode) {
      try {
        return _previewStore!.users.values.firstWhere(
          (user) => user.email.trim().toLowerCase() == normalizedEmail,
        );
      } catch (_) {
        return null;
      }
    }

    final snapshot = await _users!
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return AppUser.fromMap(snapshot.docs.first.data());
  }

  Future<void> saveLocalPassword({
    required String email,
    required String password,
  }) {
    if (!isPreviewMode) {
      return Future.value();
    }
    _previewStore!.localPasswords[email.trim().toLowerCase()] = password.trim();
    return Future.value();
  }

  Future<AppUser?> authenticateLocalUser({
    required String email,
    required String password,
  }) async {
    if (!isPreviewMode) {
      return null;
    }
    final normalizedEmail = email.trim().toLowerCase();
    final storedPassword = _previewStore!.localPasswords[normalizedEmail];
    if (storedPassword == null || storedPassword != password.trim()) {
      return null;
    }
    return fetchUserByEmail(normalizedEmail);
  }

  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? photoUrl,
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
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) {
      updates['fullName'] = fullName;
    }
    if (photoUrl != null) {
      updates['photoUrl'] = photoUrl;
    }
    if (city != null) {
      updates['city'] = city;
    }
    if (age != null) {
      updates['age'] = age;
    }
    if (gender != null) {
      updates['gender'] = gender;
    }
    if (basicMedicalInfo != null) {
      updates['basicMedicalInfo'] = basicMedicalInfo;
    }
    if (medicalHistory != null) {
      updates['medicalHistory'] = medicalHistory;
    }
    if (pastDiseases != null) {
      updates['pastDiseases'] = pastDiseases;
    }
    if (allergies != null) {
      updates['allergies'] = allergies;
    }
    if (treatments != null) {
      updates['treatments'] = treatments;
    }
    if (bloodTestResults != null) {
      updates['bloodTestResults'] = bloodTestResults;
    }
    if (notes != null) {
      updates['notes'] = notes;
    }
    if (isPremium != null) {
      updates['isPremium'] = isPremium;
    }
    if (subscriptionPlan != null) {
      updates['subscriptionPlan'] = subscriptionPlan.value;
      updates['isPremium'] = subscriptionPlan.isPremium;
    }
    if (usageDateKey != null) {
      updates['usageDateKey'] = usageDateKey;
    }
    if (photoAnalysesUsedToday != null) {
      updates['photoAnalysesUsedToday'] = photoAnalysesUsedToday;
    }
    if (aiAnalysesUsedToday != null) {
      updates['aiAnalysesUsedToday'] = aiAnalysesUsedToday;
    }

    if (updates.isEmpty) {
      debugPrint(
        'SAVE DETAIL: updateUserProfile skipped because no fields changed',
      );
      return;
    }

    if (isPreviewMode) {
      debugPrint(
        'SAVE DETAIL: updateUserProfile started in preview mode for uid=$uid',
      );
      final user = _previewStore!.users[uid];
      if (user == null) {
        debugPrint('SAVE DETAIL: preview user missing for uid=$uid');
        return;
      }
      _previewStore.users[uid] = user.copyWith(
        fullName: fullName,
        photoUrl: photoUrl,
        city: city,
        age: age,
        gender: gender,
        basicMedicalInfo: basicMedicalInfo,
        medicalHistory: medicalHistory,
        pastDiseases: pastDiseases,
        allergies: allergies,
        treatments: treatments,
        bloodTestResults: bloodTestResults,
        notes: notes,
        isPremium: subscriptionPlan?.isPremium ?? isPremium,
        subscriptionPlan: subscriptionPlan,
        usageDateKey: usageDateKey,
        photoAnalysesUsedToday: photoAnalysesUsedToday,
        aiAnalysesUsedToday: aiAnalysesUsedToday,
      );
      _previewStore.notify();
      debugPrint(
        'SAVE DETAIL: updateUserProfile finished in preview mode for uid=$uid',
      );
      return;
    }

    debugPrint(
      'SAVE DETAIL: updateUserProfile started for uid=$uid fields=${updates.keys.join(', ')}',
    );
    try {
      await _users!
          .doc(uid)
          .set(updates, SetOptions(merge: true))
          .timeout(_writeTimeout);
      debugPrint('SAVE DETAIL: updateUserProfile finished for uid=$uid');
    } on TimeoutException catch (error, stackTrace) {
      debugPrint(
        'SAVE DETAIL: updateUserProfile timed out for uid=$uid: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      throw Exception('Profile save timed out. Please try again.');
    } catch (error, stackTrace) {
      debugPrint('SAVE DETAIL: updateUserProfile failed for uid=$uid: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateVerificationStatus(String uid, bool isVerified) {
    if (isPreviewMode) {
      final user = _previewStore!.users[uid];
      if (user != null) {
        _previewStore.users[uid] = user.copyWith(isEmailVerified: isVerified);
        _previewStore.notify();
      }
      return Future.value();
    }

    return _users!.doc(uid).set({
      'isEmailVerified': isVerified,
    }, SetOptions(merge: true));
  }

  Future<void> saveFcmToken(String uid, String token) {
    if (isPreviewMode) {
      final user = _previewStore!.users[uid];
      if (user != null) {
        _previewStore.users[uid] = user.copyWith(fcmToken: token);
        _previewStore.notify();
      }
      return Future.value();
    }

    return _users!.doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }
}
