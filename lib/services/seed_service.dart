import '../models/doctor_profile.dart';
import '../models/review.dart';
import '../models/trusted_connection.dart';
import '../repositories/doctor_repository.dart';
import '../repositories/review_repository.dart';
import '../repositories/trusted_circle_repository.dart';

class SeedService {
  SeedService({
    required DoctorRepository doctorRepository,
    required ReviewRepository reviewRepository,
    required TrustedCircleRepository trustedCircleRepository,
  }) : _doctorRepository = doctorRepository,
       _reviewRepository = reviewRepository,
       _trustedCircleRepository = trustedCircleRepository;

  final DoctorRepository _doctorRepository;
  final ReviewRepository _reviewRepository;
  final TrustedCircleRepository _trustedCircleRepository;

  Future<void> seedDemoDataIfNeeded() async {
    try {
      await _seedTrustedCircle();
      final now = DateTime.now();
      final doctors = <DoctorProfile>[
        _doctor(
          doctorId: 'seed_cardiologist',
          name: 'Aisha Rakhman',
          specialty: 'Cardiologist',
          city: 'Алматы',
          clinicName: 'Alma Heart',
          yearsExperience: 11,
          ratingAverage: 4.8,
          reviewCount: 2,
          slotOffsets: const [20, 45, 70],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_dermatologist_almaty',
          name: 'Dina Omarova',
          specialty: 'Dermatologist',
          city: 'Алматы',
          clinicName: 'Skin Point',
          yearsExperience: 9,
          ratingAverage: 4.9,
          reviewCount: 2,
          slotOffsets: const [22, 47, 94],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_ent_almaty',
          name: 'Erlan Sadykov',
          specialty: 'ENT',
          city: 'Алматы',
          clinicName: 'Alem Clinic',
          yearsExperience: 10,
          ratingAverage: 4.7,
          reviewCount: 1,
          slotOffsets: const [26, 51, 99],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_gp_almaty',
          name: 'Arman Yelubayev',
          specialty: 'General Practitioner',
          city: 'Алматы',
          clinicName: 'City Med',
          yearsExperience: 8,
          ratingAverage: 4.6,
          reviewCount: 1,
          slotOffsets: const [31, 63, 118],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_pediatrician_almaty',
          name: 'Liliya Akhmetova',
          specialty: 'Pediatrician',
          city: 'Алматы',
          clinicName: 'Kids Point',
          yearsExperience: 12,
          ratingAverage: 4.8,
          reviewCount: 2,
          slotOffsets: const [38, 69, 123],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_dermatologist_astana',
          name: 'Madina Serik',
          specialty: 'Dermatologist',
          city: 'Астана',
          clinicName: 'Derma Lab',
          yearsExperience: 8,
          ratingAverage: 4.7,
          reviewCount: 1,
          slotOffsets: const [28, 54, 100],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_gynecologist_astana',
          name: 'Aliya Nurpeisova',
          specialty: 'Gynecologist',
          city: 'Астана',
          clinicName: 'Family Care',
          yearsExperience: 12,
          ratingAverage: 4.8,
          reviewCount: 2,
          slotOffsets: const [30, 57, 104],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_surgeon_astana',
          name: 'Timur Zhaksylyk',
          specialty: 'Surgeon',
          city: 'Астана',
          clinicName: 'Central Med',
          yearsExperience: 15,
          ratingAverage: 4.6,
          reviewCount: 1,
          slotOffsets: const [34, 60, 108],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_cardiologist_astana',
          name: 'Daniyar Kassymov',
          specialty: 'Cardiologist',
          city: 'Астана',
          clinicName: 'Heart Point',
          yearsExperience: 10,
          ratingAverage: 4.7,
          reviewCount: 2,
          slotOffsets: const [37, 71, 125],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_ent_astana',
          name: 'Marina Sokol',
          specialty: 'ENT',
          city: 'Астана',
          clinicName: 'North Care',
          yearsExperience: 9,
          ratingAverage: 4.5,
          reviewCount: 1,
          slotOffsets: const [41, 75, 129],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_neurologist_shymkent',
          name: 'Mira Sokolova',
          specialty: 'Neurologist',
          city: 'Шымкент',
          clinicName: 'Neuro Step',
          yearsExperience: 13,
          ratingAverage: 4.9,
          reviewCount: 2,
          slotOffsets: const [24, 58, 112],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_dermatologist_shymkent',
          name: 'Rauan Abdiyev',
          specialty: 'Dermatologist',
          city: 'Шымкент',
          clinicName: 'Skin Care',
          yearsExperience: 7,
          ratingAverage: 4.5,
          reviewCount: 1,
          slotOffsets: const [36, 64, 116],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_pediatrician_shymkent',
          name: 'Samal Tursyn',
          specialty: 'Pediatrician',
          city: 'Шымкент',
          clinicName: 'Kids Med',
          yearsExperience: 10,
          ratingAverage: 4.8,
          reviewCount: 2,
          slotOffsets: const [40, 68, 120],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_gp_shymkent',
          name: 'Bauyrzhan Saparov',
          specialty: 'General Practitioner',
          city: 'Шымкент',
          clinicName: 'South Med',
          yearsExperience: 9,
          ratingAverage: 4.6,
          reviewCount: 1,
          slotOffsets: const [43, 80, 132],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_cardiologist_shymkent',
          name: 'Alma Isina',
          specialty: 'Cardiologist',
          city: 'Шымкент',
          clinicName: 'Pulse Care',
          yearsExperience: 11,
          ratingAverage: 4.7,
          reviewCount: 2,
          slotOffsets: const [46, 84, 136],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_gp_taraz',
          name: 'Sara Bekenova',
          specialty: 'General Practitioner',
          city: 'Тараз',
          clinicName: 'Taraz Health',
          yearsExperience: 9,
          ratingAverage: 4.6,
          reviewCount: 1,
          slotOffsets: const [18, 42, 66],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_dermatologist_taraz',
          name: 'Gaukhar Imanova',
          specialty: 'Dermatologist',
          city: 'Тараз',
          clinicName: 'Skin Vita',
          yearsExperience: 6,
          ratingAverage: 4.5,
          reviewCount: 1,
          slotOffsets: const [44, 72, 126],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_gastro_taraz',
          name: 'Nurlan Abilkairov',
          specialty: 'Gastroenterologist',
          city: 'Тараз',
          clinicName: 'Digestive Care',
          yearsExperience: 11,
          ratingAverage: 4.7,
          reviewCount: 2,
          slotOffsets: const [48, 76, 130],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_ent_taraz',
          name: 'Zhazira Kuanysh',
          specialty: 'ENT',
          city: 'Тараз',
          clinicName: 'Taraz Med',
          yearsExperience: 8,
          ratingAverage: 4.5,
          reviewCount: 1,
          slotOffsets: const [50, 88, 140],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_neurologist_taraz',
          name: 'Roman Kim',
          specialty: 'Neurologist',
          city: 'Тараз',
          clinicName: 'Neuro Line',
          yearsExperience: 10,
          ratingAverage: 4.6,
          reviewCount: 1,
          slotOffsets: const [54, 92, 144],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_dermatologist_aktobe',
          name: 'Zhanel Kuat',
          specialty: 'Dermatologist',
          city: 'Актобе',
          clinicName: 'West Skin',
          yearsExperience: 8,
          ratingAverage: 4.6,
          reviewCount: 1,
          slotOffsets: const [25, 50, 74],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_cardiologist_aktobe',
          name: 'Ruslan Adil',
          specialty: 'Cardiologist',
          city: 'Актобе',
          clinicName: 'Heart Line',
          yearsExperience: 12,
          ratingAverage: 4.7,
          reviewCount: 2,
          slotOffsets: const [52, 79, 132],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_surgeon_aktobe',
          name: 'Kirill Savchenko',
          specialty: 'Surgeon',
          city: 'Актобе',
          clinicName: 'Aktobe Med',
          yearsExperience: 14,
          ratingAverage: 4.5,
          reviewCount: 1,
          slotOffsets: const [56, 83, 136],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_dermatologist_karaganda',
          name: 'Viktoriya Alimova',
          specialty: 'Dermatologist',
          city: 'Караганда',
          clinicName: 'Derma City',
          yearsExperience: 9,
          ratingAverage: 4.8,
          reviewCount: 2,
          slotOffsets: const [27, 53, 78],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_therapist_karaganda',
          name: 'Sergey Melnikov',
          specialty: 'General Practitioner',
          city: 'Караганда',
          clinicName: 'Central Care',
          yearsExperience: 10,
          ratingAverage: 4.6,
          reviewCount: 1,
          slotOffsets: const [59, 87, 140],
          now: now,
        ),
        _doctor(
          doctorId: 'seed_neurologist_karaganda',
          name: 'Laura Yermek',
          specialty: 'Neurologist',
          city: 'Караганда',
          clinicName: 'Neuro Med',
          yearsExperience: 12,
          ratingAverage: 4.7,
          reviewCount: 2,
          slotOffsets: const [62, 90, 144],
          now: now,
        ),
      ];

      for (final doctor in doctors) {
        await _doctorRepository.upsertDoctorProfile(doctor);
      }

      final reviews = <Review>[
        Review(
          reviewId: 'seed_review_1',
          doctorId: 'seed_cardiologist',
          patientId: 'seed_patient_1',
          patientName: 'Leila M.',
          rating: 5,
          comment: 'Clear advice and quick help.',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        Review(
          reviewId: 'seed_review_2',
          doctorId: 'seed_cardiologist',
          patientId: 'seed_patient_2',
          patientName: 'Marat T.',
          rating: 4,
          comment: 'Clear visit and calm tone.',
          createdAt: now.subtract(const Duration(days: 11)),
        ),
        Review(
          reviewId: 'seed_review_3',
          doctorId: 'seed_dermatologist_astana',
          patientId: 'seed_patient_3',
          patientName: 'Nina K.',
          rating: 5,
          comment: 'Treatment helped quickly.',
          createdAt: now.subtract(const Duration(days: 7)),
        ),
        Review(
          reviewId: 'seed_review_4',
          doctorId: 'seed_neurologist_shymkent',
          patientId: 'seed_patient_4',
          patientName: 'David P.',
          rating: 5,
          comment: 'Very attentive and careful.',
          createdAt: now.subtract(const Duration(days: 9)),
        ),
        Review(
          reviewId: 'seed_review_5',
          doctorId: 'seed_neurologist_shymkent',
          patientId: 'seed_patient_5',
          patientName: 'Ainur S.',
          rating: 5,
          comment: 'Helped me understand the next step fast.',
          createdAt: now.subtract(const Duration(days: 13)),
        ),
        Review(
          reviewId: 'seed_review_6',
          doctorId: 'seed_gp_taraz',
          patientId: 'seed_patient_6',
          patientName: 'Olga S.',
          rating: 4,
          comment: 'Smooth first visit and clear advice.',
          createdAt: now.subtract(const Duration(days: 6)),
        ),
        Review(
          reviewId: 'seed_review_7',
          doctorId: 'seed_dermatologist_almaty',
          patientId: 'seed_patient_7',
          patientName: 'Aigerim K.',
          rating: 5,
          comment: 'Handled the skin issue very well.',
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        Review(
          reviewId: 'seed_review_8',
          doctorId: 'seed_gastro_taraz',
          patientId: 'seed_patient_8',
          patientName: 'Bekzat N.',
          rating: 5,
          comment: 'The visit was very clear.',
          createdAt: now.subtract(const Duration(days: 8)),
        ),
        Review(
          reviewId: 'seed_review_9',
          doctorId: 'seed_dermatologist_karaganda',
          patientId: 'seed_patient_9',
          patientName: 'Madina A.',
          rating: 5,
          comment: 'Good treatment plan.',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        Review(
          reviewId: 'seed_review_10',
          doctorId: 'seed_cardiologist_aktobe',
          patientId: 'seed_patient_10',
          patientName: 'Ruslan E.',
          rating: 4,
          comment: 'Really liked the clear consultation.',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      ];

      for (final review in reviews) {
        await _reviewRepository.addReview(review, recalculateOnly: true);
      }
    } catch (_) {
      // Seeding should never block app launch.
    }
  }

  Future<void> _seedTrustedCircle() {
    return _trustedCircleRepository.saveConnections('preview_patient', const [
      TrustedConnection(
        ownerId: 'preview_patient',
        connectionUserId: 'seed_patient_1',
        displayName: 'Leila',
        relationshipLabel: 'Sister',
      ),
      TrustedConnection(
        ownerId: 'preview_patient',
        connectionUserId: 'seed_patient_5',
        displayName: 'Ainur',
        relationshipLabel: 'Friend',
      ),
      TrustedConnection(
        ownerId: 'preview_patient',
        connectionUserId: 'seed_patient_6',
        displayName: 'Olga',
        relationshipLabel: 'Colleague',
      ),
    ]);
  }

  DoctorProfile _doctor({
    required String doctorId,
    required String name,
    required String specialty,
    required String city,
    required String clinicName,
    String address = '',
    required int yearsExperience,
    required double ratingAverage,
    required int reviewCount,
    required List<int> slotOffsets,
    required DateTime now,
  }) {
    return DoctorProfile(
      doctorId: doctorId,
      uid: doctorId,
      name: name,
      specialty: specialty,
      bio: '${_doctorFocus(specialty)} Short and clear visit.',
      clinicName: clinicName,
      address: address.isEmpty ? _addressFor(city, clinicName) : address,
      city: city,
      yearsExperience: yearsExperience,
      ratingAverage: ratingAverage,
      reviewCount: reviewCount,
      profileImageUrl: null,
      availableSlots: slotOffsets
          .map((offset) => now.add(Duration(hours: offset)))
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
  }

  String _doctorFocus(String specialty) {
    switch (specialty) {
      case 'Dermatologist':
        return 'Skin, rash, inflammation.';
      case 'Cardiologist':
        return 'Heart, blood pressure, rhythm.';
      case 'Neurologist':
        return 'Headache, nerves, dizziness.';
      case 'ENT':
        return 'Ear, throat, nose.';
      case 'Gastroenterologist':
        return 'Stomach, digestion, nutrition.';
      case 'Gynecologist':
        return 'Women’s health.';
      case 'Pediatrician':
        return 'Children’s care.';
      case 'Surgeon':
        return 'Exam and surgical consult.';
      default:
        return 'First visit and routing.';
    }
  }

  String _addressFor(String city, String clinicName) {
    final street = switch (city) {
      'Алматы' => 'Tole Bi St. 45',
      'Астана' => 'Kabanbay Batyr Ave. 18',
      'Шымкент' => 'Tauke Khan Ave. 92',
      'Тараз' => 'Aitiev St. 33',
      'Актобе' => 'Abulkhair Khan Ave. 57',
      'Караганда' => 'Bukhar Zhyrau Ave. 61',
      _ => 'Abay St. 10',
    };
    return '$street, $city';
  }
}
