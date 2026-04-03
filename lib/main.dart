import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/bootstrap/app_environment.dart';
import 'firebase_options.dart';
import 'providers/auth_controller.dart';
import 'repositories/appointment_repository.dart';
import 'repositories/doctor_repository.dart';
import 'repositories/family_repository.dart';
import 'repositories/review_repository.dart';
import 'repositories/symptom_repository.dart';
import 'repositories/trusted_circle_repository.dart';
import 'repositories/user_repository.dart';
import 'services/ai_specialty_matcher_service.dart';
import 'services/auth_service.dart';
import 'services/care_recommendation_service.dart';
import 'services/emergency_triage_service.dart';
import 'services/family_health_digest_service.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';
import 'services/preview_data_store.dart';
import 'services/seed_service.dart';
import 'services/storage_service.dart';
import 'services/symptom_photo_triage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('ru_RU');

  const firebaseEnabled = true;

  final notificationService = NotificationService(enabled: firebaseEnabled);
  await notificationService.initialize();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Text(
              'Error:\n\n${details.exceptionAsString()}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    _MediTriageRoot(
      firebaseEnabled: firebaseEnabled,
      notificationService: notificationService,
    ),
  );
}

class _MediTriageRoot extends StatelessWidget {
  const _MediTriageRoot({
    required this.firebaseEnabled,
    required this.notificationService,
  });

  final bool firebaseEnabled;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final previewMode = !firebaseEnabled;
    final firestore = firebaseEnabled ? FirebaseFirestore.instance : null;
    final previewStore = !firebaseEnabled ? PreviewDataStore() : null;

    final environment = AppEnvironment(
      firebaseEnabled: firebaseEnabled,
      previewMode: previewMode,
    );

    return MultiProvider(
      providers: [
        Provider<AppEnvironment>.value(value: environment),

        Provider<AuthService>(
          create: (_) => AuthService(),
        ),

        Provider<NotificationService>.value(
          value: notificationService,
        ),

        Provider<UserRepository>(
          create: (_) => UserRepository(
            firestore: firestore,
            previewStore: previewStore,
          ),
        ),

        Provider<DoctorRepository>(
          create: (_) => DoctorRepository(
            firestore: firestore,
            previewStore: previewStore,
          ),
        ),

        Provider<AppointmentRepository>(
          create: (context) => AppointmentRepository(
            firestore: firestore,
            doctorRepository: context.read<DoctorRepository>(),
            previewStore: previewStore,
          ),
        ),

        Provider<FamilyRepository>(
          create: (_) => FamilyRepository(
            firestore: firestore,
            previewStore: previewStore,
          ),
        ),

        Provider<ReviewRepository>(
          create: (context) => ReviewRepository(
            firestore: firestore,
            doctorRepository: context.read<DoctorRepository>(),
            previewStore: previewStore,
          ),
        ),

        Provider<SymptomRepository>(
          create: (_) => SymptomRepository(
            firestore: firestore,
            previewStore: previewStore,
          ),
        ),

        Provider<TrustedCircleRepository>(
          create: (_) => TrustedCircleRepository(
            firestore: firestore,
            previewStore: previewStore,
          ),
        ),

        Provider<StorageService>(
          create: (_) => StorageService(enabled: firebaseEnabled),
        ),

        Provider<AiSpecialtyMatcherService>(
          create: (_) => AiSpecialtyMatcherService(),
        ),

        Provider<EmergencyTriageService>(
          create: (_) => EmergencyTriageService(),
        ),

        Provider<SymptomPhotoTriageService>(
          create: (_) => SymptomPhotoTriageService(),
        ),

        Provider<CareRecommendationService>(
          create: (context) => CareRecommendationService(
            specialtyMatcher: context.read<AiSpecialtyMatcherService>(),
            emergencyTriageService: context.read<EmergencyTriageService>(),
            symptomPhotoTriageService:
                context.read<SymptomPhotoTriageService>(),
          ),
        ),

        Provider<FamilyHealthDigestService>(
          create: (_) => FamilyHealthDigestService(),
        ),

        Provider<SeedService>(
          lazy: false,
          create: (context) => SeedService(
            doctorRepository: context.read<DoctorRepository>(),
            reviewRepository: context.read<ReviewRepository>(),
            trustedCircleRepository: context.read<TrustedCircleRepository>(),
          )..seedDemoDataIfNeeded(),
        ),

        ChangeNotifierProvider<OnboardingService>(
          create: (_) {
            final onboardingService = OnboardingService();
            onboardingService.load();
            return onboardingService;
          },
        ),

        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            authService: context.read<AuthService>(),
            userRepository: context.read<UserRepository>(),
            doctorRepository: context.read<DoctorRepository>(),
            notificationService: context.read<NotificationService>(),
            previewMode: previewMode,
          ),
        ),
      ],
      child: const MediTriageApp(),
    );
  }
}