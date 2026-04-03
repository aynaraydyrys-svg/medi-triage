import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/enums/subscription_plan.dart';
import '../core/enums/user_role.dart';
import '../core/utils/app_constants.dart';
import '../models/app_user.dart';
import '../models/doctor_profile.dart';
import '../repositories/doctor_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
    required UserRepository userRepository,
    required DoctorRepository doctorRepository,
    required NotificationService notificationService,
    bool previewMode = false,
  }) : _authService = authService,
       _userRepository = userRepository,
       _doctorRepository = doctorRepository,
       _notificationService = notificationService,
       _previewMode = previewMode {
    if (_previewMode) {
      _isInitializing = false;
    } else {
      _bindAuthState();
    }
  }

  final AuthService _authService;
  final UserRepository _userRepository;
  final DoctorRepository _doctorRepository;
  final NotificationService _notificationService;
  final bool _previewMode;

  StreamSubscription<User?>? _authSubscription;

  bool _isInitializing = true;
  bool _isBusy = false;
  String? _errorMessage;
  AppUser? _currentUser;
  User? _firebaseUser;

  bool get isInitializing => _isInitializing;
  bool get isBusy => _isBusy;
  bool get isPreviewMode => _previewMode;
  bool get isAuthenticated => _currentUser != null || _firebaseUser != null;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;

  SubscriptionPlan get subscriptionPlan =>
      _currentUser?.subscriptionPlan ?? SubscriptionPlan.basic;

  String get currentPlanLabel => 'Current plan: ${subscriptionPlan.label}';
  SubscriptionPlan? get upgradeTargetPlan => subscriptionPlan.upgradeTarget;

  int get remainingPhotoAnalyses {
    final user = _currentUser;
    final limit = subscriptionPlan.photoAnalysisLimit;
    if (user == null || limit == null) {
      return 999;
    }
    return math.max(limit - _resolvedPhotoUsage(user), 0);
  }

  int get remainingAiAnalyses {
    final user = _currentUser;
    final limit = subscriptionPlan.aiAnalysisLimit;
    if (user == null || limit == null) {
      return 999;
    }
    return math.max(limit - _resolvedAiUsage(user), 0);
  }

  bool get canAddFamilyMember {
    final limit = subscriptionPlan.familyMemberLimit;
    return limit == null || limit > 0;
  }

  bool get requiresEmailVerification {
    if (_previewMode || _firebaseUser == null) {
      return false;
    }

    final signedInWithPassword = _firebaseUser!.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    return signedInWithPassword && !_firebaseUser!.emailVerified;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (_previewMode) {
      return _runGuarded(() async {
        _validateLocalCredentials(email: normalizedEmail, password: password);

        final user = await _userRepository.authenticateLocalUser(
          email: normalizedEmail,
          password: password,
        );

        if (user == null) {
          if (!await _userRepository.userExistsByEmail(normalizedEmail)) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'Account not found',
            );
          }

          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Wrong password',
          );
        }

        _currentUser = user;
        _firebaseUser = null;
        _isInitializing = false;

        await _ensureDoctorProfileIfNeeded(user);
        notifyListeners();
        return true;
      });
    }

    return _runGuarded(() async {
      debugPrint('SIGN IN STEP 1: checking Firestore email $normalizedEmail');

      if (!await _userRepository.userExistsByEmail(normalizedEmail)) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Account not found',
        );
      }

      debugPrint('SIGN IN STEP 2: Firebase email sign in');
      await _authService.signInWithEmail(
        email: normalizedEmail,
        password: password,
      );

      debugPrint('SIGN IN STEP 3: success');
      return true;
    });
  }

  Future<bool> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    required String city,
    int? age,
    String gender = '',
    String basicMedicalInfo = '',
    List<String> medicalHistory = const <String>[],
    List<String> pastDiseases = const <String>[],
    List<String> allergies = const <String>[],
    List<String> treatments = const <String>[],
    List<String> bloodTestResults = const <String>[],
    String notes = '',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (_previewMode) {
      return _runGuarded(() async {
        _validateLocalCredentials(email: normalizedEmail, password: password);

        if (await _userRepository.userExistsByEmail(normalizedEmail)) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Account already exists',
          );
        }

        final localUser = AppUser(
          uid: 'local_${role.value}_${DateTime.now().millisecondsSinceEpoch}',
          fullName: fullName.trim(),
          email: normalizedEmail,
          role: role,
          createdAt: DateTime.now(),
          isEmailVerified: true,
          city: city.trim(),
          age: age,
          gender: gender.trim(),
          basicMedicalInfo: basicMedicalInfo.trim(),
          medicalHistory: medicalHistory,
          pastDiseases: pastDiseases,
          allergies: allergies,
          treatments: treatments,
          bloodTestResults: bloodTestResults,
          notes: notes.trim(),
        );

        await _userRepository.createUserDocument(localUser);
        await _userRepository.saveLocalPassword(
          email: normalizedEmail,
          password: password,
        );
        await _ensureDoctorProfileIfNeeded(localUser);

        _currentUser = localUser;
        _firebaseUser = null;
        _isInitializing = false;
        notifyListeners();
        return true;
      });
    }

    return _runGuarded(() async {
      debugPrint('SIGNUP STEP 1: entered Firebase sign up');
      debugPrint('SIGNUP EMAIL: $normalizedEmail');
      debugPrint('SIGNUP ROLE: ${role.value}');
      debugPrint('SIGNUP CITY: $city');

      final credential = await _authService.registerWithEmail(
        email: normalizedEmail,
        password: password,
      );

      debugPrint('SIGNUP STEP 2: registerWithEmail finished');

      final user = credential.user;
      debugPrint(
        'SIGNUP STEP 3: firebase user = ${user?.uid}, email = ${user?.email}',
      );

      if (user == null) {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Unable to create the account right now.',
        );
      }

      final appUser = AppUser(
        uid: user.uid,
        fullName: fullName.trim(),
        email: normalizedEmail,
        role: role,
        createdAt: DateTime.now(),
        isEmailVerified: false,
        photoUrl: user.photoURL,
        city: city.trim(),
        age: age,
        gender: gender.trim(),
        basicMedicalInfo: basicMedicalInfo.trim(),
        medicalHistory: medicalHistory,
        pastDiseases: pastDiseases,
        allergies: allergies,
        treatments: treatments,
        bloodTestResults: bloodTestResults,
        notes: notes.trim(),
      );

      debugPrint('SIGNUP STEP 4: creating Firestore user document');
      await _userRepository.createUserDocument(appUser);

      debugPrint('SIGNUP STEP 5: updating local auth state immediately');
      _firebaseUser = user;
      _currentUser = appUser;
      _isInitializing = false;
      notifyListeners();

      unawaited(_ensureDoctorProfileIfNeeded(appUser));
      unawaited(_authService.sendEmailVerification());

      debugPrint('SIGNUP STEP 6: sign up completed successfully');
      return true;
    });
  }

  Future<bool> signInWithGoogle({
    UserRole? roleForNewUser,
    String? previewEmail,
    String? previewPassword,
  }) async {
    if (_previewMode) {
      throw FirebaseAuthException(
        code: 'missing-role',
        message: 'Use email and password',
      );
    }

    return _runGuarded(() async {
      final credential = await _authService.signInWithGoogle();
      final user = credential?.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      final existingUser = await _userRepository.fetchUser(user.uid);
      if (existingUser != null) {
        _firebaseUser = user;
        _currentUser = existingUser.copyWith(
          uid: user.uid,
          isEmailVerified: true,
          photoUrl: user.photoURL,
        );
        _isInitializing = false;
        notifyListeners();
        return true;
      }

      final resolvedRole = roleForNewUser ?? UserRole.patient;

      final appUser = AppUser(
        uid: user.uid,
        fullName: (user.displayName ?? 'MediTriage User').trim(),
        email: (user.email ?? '').trim().toLowerCase(),
        role: resolvedRole,
        createdAt: DateTime.now(),
        isEmailVerified: true,
        photoUrl: user.photoURL,
        city: '',
      );

      await _userRepository.createUserDocument(appUser);
      await _ensureDoctorProfileIfNeeded(appUser);

      _firebaseUser = user;
      _currentUser = appUser;
      _isInitializing = false;
      notifyListeners();

      return true;
    });
  }

  Future<void> resendVerificationEmail() async {
    if (_previewMode) return;

    await _runGuarded(() async {
      await _authService.sendEmailVerification();
    });
  }

  Future<void> refreshVerificationStatus() async {
    if (_previewMode) return;

    await _runGuarded(() async {
      await _authService.reloadCurrentUser();
      final refreshedUser = _authService.currentUser;
      _firebaseUser = refreshedUser;

      if (refreshedUser != null) {
        await _userRepository.updateVerificationStatus(
          refreshedUser.uid,
          refreshedUser.emailVerified,
        );

        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            isEmailVerified: refreshedUser.emailVerified,
          );
        }
      }
    });
  }

  Future<void> updateProfile({
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
  }) async {
    final user = _currentUser;
    final safeUid = _resolvedUid();

    if (user == null) return;
    if (safeUid == null) {
      throw Exception('User ID is missing. Please log in again.');
    }

    await _runGuarded(() async {
      await _userRepository.updateUserProfile(
        uid: safeUid,
        fullName: fullName?.trim(),
        photoUrl: photoUrl ?? user.photoUrl,
        city: city?.trim(),
        age: age,
        gender: gender?.trim(),
        basicMedicalInfo: basicMedicalInfo?.trim(),
        medicalHistory: medicalHistory,
        pastDiseases: pastDiseases,
        allergies: allergies,
        treatments: treatments,
        bloodTestResults: bloodTestResults,
        notes: notes?.trim(),
        isPremium: subscriptionPlan?.isPremium ?? isPremium,
        subscriptionPlan: subscriptionPlan,
      );

      _currentUser = user.copyWith(
        uid: safeUid,
        fullName: fullName?.trim(),
        photoUrl: photoUrl ?? user.photoUrl,
        city: city?.trim(),
        age: age,
        gender: gender?.trim(),
        basicMedicalInfo: basicMedicalInfo?.trim(),
        medicalHistory: medicalHistory,
        pastDiseases: pastDiseases,
        allergies: allergies,
        treatments: treatments,
        bloodTestResults: bloodTestResults,
        notes: notes?.trim(),
        isPremium: subscriptionPlan?.isPremium ?? isPremium,
        subscriptionPlan: subscriptionPlan,
      );
    });
  }

  Future<void> updateSubscriptionPlan(SubscriptionPlan plan) async {
    final user = _currentUser;
    final safeUid = _resolvedUid();

    if (user == null) {
      throw Exception('No current user');
    }
    if (safeUid == null) {
      throw Exception('User ID is missing. Please log in again.');
    }
    if (user.subscriptionPlan == plan) {
      return;
    }

    await updateProfile(subscriptionPlan: plan);

    _currentUser = _currentUser?.copyWith(
      uid: safeUid,
      subscriptionPlan: plan,
      isPremium: plan.isPremium,
    );

    notifyListeners();
  }

  bool canRunAnalysis({required bool withPhoto}) {
    if (subscriptionPlan.aiAnalysisLimit != null && remainingAiAnalyses <= 0) {
      return false;
    }

    if (withPhoto &&
        subscriptionPlan.photoAnalysisLimit != null &&
        remainingPhotoAnalyses <= 0) {
      return false;
    }

    return true;
  }

  String? analysisLimitCtaLabel({required bool withPhoto}) {
    if (canRunAnalysis(withPhoto: withPhoto)) {
      return null;
    }
    final target = upgradeTargetPlan;
    if (target == null) {
      return null;
    }
    return 'Upgrade to ${target.label}';
  }

  Future<void> recordAnalysisUsage({required bool withPhoto}) async {
    final user = _currentUser;
    final safeUid = _resolvedUid();

    if (user == null) return;
    if (safeUid == null) {
      debugPrint('recordAnalysisUsage skipped: missing uid');
      return;
    }

    final todayKey = _todayKey();
    final nextAi = _resolvedAiUsage(user) + 1;
    final nextPhoto = _resolvedPhotoUsage(user) + (withPhoto ? 1 : 0);

    await _userRepository.updateUserProfile(
      uid: safeUid,
      usageDateKey: todayKey,
      aiAnalysesUsedToday: nextAi,
      photoAnalysesUsedToday: nextPhoto,
    );

    _currentUser = user.copyWith(
      uid: safeUid,
      usageDateKey: todayKey,
      aiAnalysesUsedToday: nextAi,
      photoAnalysesUsedToday: nextPhoto,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await _runGuarded(() async {
      if (_previewMode) {
        _currentUser = null;
        _firebaseUser = null;
        return;
      }

      await _authService.signOut();
      _currentUser = null;
      _firebaseUser = null;
    });
  }

  void _validateLocalCredentials({
    required String email,
    required String password,
  }) {
    if (email.isEmpty || !email.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Invalid email',
      );
    }

    if (password.trim().length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password 6+',
      );
    }
  }

  void _bindAuthState() {
    _authSubscription = _authService.authStateChanges().listen((user) async {
      _firebaseUser = user;

      if (user == null) {
        _currentUser = null;
        _isInitializing = false;
        notifyListeners();
        return;
      }

      AppUser? appUser;

      for (var i = 0; i < 10; i++) {
        appUser = await _userRepository.fetchUser(user.uid);
        if (appUser != null) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      if (appUser == null) {
        if (_currentUser != null && _currentUser!.uid == user.uid) {
          _isInitializing = false;
          notifyListeners();
          return;
        }

        _errorMessage = 'Profile not found';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _currentUser = appUser.copyWith(
        uid: user.uid,
        isEmailVerified: user.emailVerified,
      );

      await _userRepository.updateVerificationStatus(
        user.uid,
        user.emailVerified,
      );

      _isInitializing = false;
      notifyListeners();

      unawaited(_ensureDoctorProfileIfNeeded(_currentUser!));

      if (!kIsWeb) {
        unawaited(
          _notificationService.syncTokenToUser(
            uid: user.uid,
            userRepository: _userRepository,
          ),
        );
      }
    });
  }

  Future<T> _runGuarded<T>(Future<T> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await action();
      return result;
    } on FirebaseAuthException catch (error) {
      debugPrint('FIREBASE AUTH ERROR CODE: ${error.code}');
      debugPrint('FIREBASE AUTH ERROR MESSAGE: ${error.message}');
      _errorMessage = _mapAuthError(error);
      rethrow;
    } catch (error) {
      debugPrint('GENERAL AUTH ERROR: $error');
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Invalid email';
      case 'invalid-credential':
        return 'Wrong password';
      case 'wrong-password':
        return 'Wrong password';
      case 'user-not-found':
        return 'Account not found';
      case 'email-already-in-use':
        return 'Account already exists';
      case 'weak-password':
        return 'Password 6+';
      case 'network-request-failed':
        return 'No network';
      case 'google-sign-in-cancelled':
        return 'Google cancelled';
      case 'missing-role':
        return error.message ?? 'Choose role';
      default:
        return error.message ?? 'Error';
    }
  }

  Future<void> _ensureDoctorProfileIfNeeded(AppUser user) async {
    if (user.role != UserRole.doctor) {
      return;
    }

    final existingProfile = await _doctorRepository.fetchDoctor(user.uid);
    if (existingProfile != null) {
      return;
    }

    final now = DateTime.now();
    await _doctorRepository.upsertDoctorProfile(
      DoctorProfile(
        doctorId: user.uid,
        uid: user.uid,
        name: user.fullName,
        specialty: 'General Practitioner',
        bio: 'New doctor',
        clinicName: user.city.isEmpty
            ? 'MediTriage Clinic'
            : 'Clinic ${AppConstants.cityLabel(user.city)}',
        address: user.city.isEmpty
            ? 'Abay St. 10'
            : 'Abay St. 10, ${AppConstants.cityLabel(user.city)}',
        city: user.city.isEmpty ? AppConstants.kzCities.first : user.city,
        yearsExperience: 1,
        ratingAverage: 0.0,
        reviewCount: 0,
        profileImageUrl: user.photoUrl,
        availableSlots: _starterSlots(now),
        createdAt: now,
        updatedAt: now,
        statusNote: 'Complete your profile',
      ),
    );
  }

  List<DateTime> _starterSlots(DateTime now) {
    return <DateTime>[
      now.add(const Duration(days: 1, hours: 10)),
      now.add(const Duration(days: 1, hours: 14)),
      now.add(const Duration(days: 2, hours: 11)),
    ];
  }

  String _todayKey([DateTime? now]) {
    final value = now ?? DateTime.now();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  int _resolvedAiUsage(AppUser user) {
    return user.usageDateKey == _todayKey() ? user.aiAnalysesUsedToday : 0;
  }

  int _resolvedPhotoUsage(AppUser user) {
    return user.usageDateKey == _todayKey() ? user.photoAnalysesUsedToday : 0;
  }

  String? _resolvedUid() {
    final currentUid = _currentUser?.uid.trim();
    if (currentUid != null && currentUid.isNotEmpty) {
      return currentUid;
    }

    final firebaseUid = _firebaseUser?.uid.trim();
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      return firebaseUid;
    }

    return null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}