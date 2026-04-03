import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_constants.dart';
import '../../models/appointment.dart';
import '../../models/doctor_trust_insight.dart';
import '../../models/family_digest_item.dart';
import '../../models/family_member.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/doctor_repository.dart';
import '../../repositories/family_repository.dart';
import '../../repositories/trusted_circle_repository.dart';
import '../../services/family_health_digest_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/brand_badge.dart';
import '../../widgets/doctor_card.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_card.dart';
import 'booking_screen.dart';
import 'doctor_detail_screen.dart';
import 'family_health_passport_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({
    super.key,
    required this.onOpenSearch,
    required this.onOpenAi,
    required this.onOpenAiWithSymptoms,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAi;
  final ValueChanged<String> onOpenAiWithSymptoms;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final firstName = auth.currentUser?.fullName.split(' ').first ?? 'Friend';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandBadge(),
          const SizedBox(height: 24),
          _HeroPanel(firstName: firstName),
          const SizedBox(height: 18),
          const _FeatureStrip(),
          const SizedBox(height: 18),
          const _FamilyPassportPreview(),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 18),
               ElevatedButton.icon(
  onPressed: () async {
    print('AI CLICKED');

    try {
      await Future.delayed(const Duration(seconds: 1));

      print('AI DONE');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI works')),
      );
    } catch (e) {
      print('AI ERROR: $e');
    }
  },
  icon: const Icon(Icons.auto_awesome_rounded),
  label: const Text('AI Scan'),
),
                const SizedBox(height: 12),
                OutlinedButton.icon(
  onPressed: () {
    print('SEARCH CLICKED');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search works')),
    );
  },
  icon: const Icon(Icons.medical_services_outlined),
  label: const Text('Search'),
),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick start',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppConstants.symptomPrompts
                      .map(
                        (prompt) => ActionChip(
                          avatar: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(prompt),
                          onPressed: () {
  print('PROMPT CLICKED: $prompt');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Prompt: $prompt')),
  );
},
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  AppConstants.matchingDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Top doctors',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(onPressed: onOpenSearch, child: const Text('All')),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder(
            stream: context.read<DoctorRepository>().streamDoctors(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final userId = auth.currentUser?.uid;
              final doctors = [...snapshot.data!]
                ..sort((a, b) {
                  if (a.isAvailableToday != b.isAvailableToday) {
                    return a.isAvailableToday ? -1 : 1;
                  }
                  return b.ratingAverage.compareTo(a.ratingAverage);
                });
              final topDoctors = doctors.take(4).toList();
              if (topDoctors.isEmpty) {
                return const EmptyStateCard(
                  title: 'Loading doctors',
                  subtitle: 'Please wait',
                  icon: Icons.sync_rounded,
                );
              }

              return FutureBuilder<Map<String, DoctorTrustInsight>>(
                future: userId == null
                    ? Future.value(<String, DoctorTrustInsight>{
                        for (final doctor in topDoctors)
                          doctor.doctorId: DoctorTrustInsight.empty(
                            doctor.doctorId,
                          ),
                      })
                    : context
                          .read<TrustedCircleRepository>()
                          .fetchTrustInsights(
                            patientId: userId,
                            doctorIds: topDoctors.map(
                              (doctor) => doctor.doctorId,
                            ),
                          ),
                builder: (context, trustSnapshot) {
                  final trustMap =
                      trustSnapshot.data ??
                      <String, DoctorTrustInsight>{
                        for (final doctor in topDoctors)
                          doctor.doctorId: DoctorTrustInsight.empty(
                            doctor.doctorId,
                          ),
                      };
                  final sortedDoctors = [...topDoctors]
                    ..sort((a, b) {
                      final trustDiff =
                          (trustMap[b.doctorId]?.connectedPatientsCount ?? 0) -
                          (trustMap[a.doctorId]?.connectedPatientsCount ?? 0);
                      if (trustDiff != 0) {
                        return trustDiff;
                      }
                      if (a.isAvailableToday != b.isAvailableToday) {
                        return a.isAvailableToday ? -1 : 1;
                      }
                      return b.ratingAverage.compareTo(a.ratingAverage);
                    });

                  return Column(
                    children: sortedDoctors
                        .map(
                          (doctor) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: DoctorCard(
                              doctor: doctor,
                              trustInsight: trustMap[doctor.doctorId],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => DoctorDetailScreen(
                                    doctorId: doctor.doctorId,
                                  ),
                                ),
                              ),
                              onBookTap: doctor.availableSlots.isEmpty
                                  ? null
                                  : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => BookingScreen(
                                          doctor: doctor,
                                          selectedSlot:
                                              doctor.availableSlots.first,
                                          trustInsight:
                                              trustMap[doctor.doctorId],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FamilyPassportPreview extends StatelessWidget {
  const _FamilyPassportPreview();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<FamilyMember>>(
      stream: context.read<FamilyRepository>().streamFamilyMembers(user.uid),
      builder: (context, familySnapshot) {
        final familyMembers = familySnapshot.data ?? const <FamilyMember>[];

        return StreamBuilder<List<Appointment>>(
          stream: context
              .read<AppointmentRepository>()
              .streamPatientAppointments(user.uid),
          builder: (context, appointmentSnapshot) {
            final appointments =
                appointmentSnapshot.data ?? const <Appointment>[];
            final digest = context
                .read<FamilyHealthDigestService>()
                .buildDigest(
                  familyMembers: familyMembers,
                  appointments: appointments,
                );

            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Family passport',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FamilyHealthPassportScreen(),
                          ),
                        ),
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (familyMembers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Add family members',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else ...[
                    Text(
                      '${familyMembers.length} on account',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (digest.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundAlt,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('Reminders will appear here'),
                      )
                    else
                      Column(
                        children: digest
                            .take(2)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _HomeDigestTile(item: item),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeDigestTile extends StatelessWidget {
  const _HomeDigestTile({required this.item});

  final FamilyDigestItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.tone) {
      FamilyDigestTone.calm => AppColors.primary,
      FamilyDigestTone.action => AppColors.warning,
      FamilyDigestTone.alert => AppColors.danger,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.insights_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0F6FFF), Color(0xFF57B4FF)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.glowBlue,
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $firstName',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Find a doctor',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'AI. Urgency. Booking.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _FeatureTile(
            icon: Icons.emergency_outlined,
            title: 'Urgency',
            subtitle: '3 levels',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _FeatureTile(
            icon: Icons.photo_camera_back_outlined,
            title: 'Photo',
            subtitle: 'Camera',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _FeatureTile(
            icon: Icons.verified_user_outlined,
            title: 'Trust',
            subtitle: 'Circle',
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.backgroundAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
