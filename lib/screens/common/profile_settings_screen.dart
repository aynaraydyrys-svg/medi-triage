import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/subscription_plan.dart';
import '../../core/enums/user_role.dart';
import '../../core/utils/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_user.dart';
import '../../models/family_member.dart';
import '../../models/symptom_log.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/family_repository.dart';
import '../../repositories/symptom_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/adaptive_image.dart';
import '../../widgets/brand_badge.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/network_avatar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/urgency_chip.dart';
import 'plan_selection_screen.dart';
import '../doctor/doctor_profile_edit_screen.dart';
import '../doctor/doctor_reviews_screen.dart';
import '../doctor/slot_management_screen.dart';
import '../patient/family_health_passport_screen.dart';
import '../patient/patient_medical_details_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedCity;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _selectedCity = user != null && AppConstants.kzCities.contains(user.city)
        ? user.city
        : AppConstants.kzCities.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const EmptyStateCard(
        title: 'No profile',
        subtitle: 'Please login again',
        icon: Icons.person_off_outlined,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandBadge(),
          const SizedBox(height: 24),
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NetworkAvatar(
                        name: user.fullName,
                        imageUrl: user.photoUrl,
                        radius: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.role.label} • ${user.email}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      _PlanChip(plan: user.subscriptionPlan),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: _requiredName,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    items: AppConstants.kzCities
                        .map(
                          (city) => DropdownMenuItem<String>(
                            value: city,
                            child: Text(AppConstants.cityLabel(city)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedCity = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  if (user.role == UserRole.patient) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Medical details',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _medicalSummary(user),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: _openMedicalDetails,
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (user.role == UserRole.patient) ...[
            StreamBuilder<List<FamilyMember>>(
              stream: context.read<FamilyRepository>().streamFamilyMembers(
                user.uid,
              ),
              builder: (context, snapshot) {
                final familyMembers = snapshot.data ?? const <FamilyMember>[];
                return SectionCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundAlt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.groups_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Family',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              familyMembers.isEmpty
                                  ? 'Add family members'
                                  : '${familyMembers.length} on account',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _openFamily,
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.subscriptionPlan.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _planSubtitle(user.subscriptionPlan),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: _openPlans,
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PatientHistorySection(userId: user.uid),
            const SizedBox(height: 16),
          ],
          if (user.role == UserRole.doctor) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tools', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DoctorProfileEditScreen(),
                      ),
                    ),
                    child: const Text('Doctor profile'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SlotManagementScreen(),
                      ),
                    ),
                    child: const Text('Slots'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DoctorReviewsScreen(),
                      ),
                    ),
                    child: const Text('Reviews'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton(
            onPressed: auth.isBusy ? null : () => auth.signOut(),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    debugPrint('SAVE 1: button tapped');
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('SAVE 2: validation started');
      final isValid = _formKey.currentState?.validate() ?? false;
      if (!isValid) {
        _showSnackBar('Please enter your full name.');
        return;
      }

      final auth = context.read<AuthController>();
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('User profile unavailable. Please sign in again.');
      }

      final trimmedName = _nameController.text.trim();
      debugPrint('SAVE 3: validation passed');
      debugPrint('SAVE 4: firestore write started');
      await auth.updateProfile(fullName: trimmedName, city: _selectedCity);
      debugPrint('SAVE 5: firestore write finished');

      if (!mounted) {
        return;
      }

      setState(() {
        _nameController.text = trimmedName;
      });
      debugPrint('SAVE 6: local refresh finished');
      _showSnackBar('Profile saved');
      debugPrint('SAVE 7: done');
    } catch (error, stackTrace) {
      debugPrint('SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(_friendlyError(error, 'Unable to save profile.'));
      }
    } finally {
      debugPrint('SAVE 8: loading reset');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _openPlans() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PlanSelectionScreen()),
    );
  }

  void _openMedicalDetails() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PatientMedicalDetailsScreen(),
      ),
    );
  }

  void _openFamily() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FamilyHealthPassportScreen(),
      ),
    );
  }

  String _planSubtitle(SubscriptionPlan plan) {
    return switch (plan) {
      SubscriptionPlan.basic => 'AI, search, booking',
      SubscriptionPlan.plus => 'Photo, family, reminders',
      SubscriptionPlan.pro => 'AI summary, priority, family',
    };
  }

  String _medicalSummary(AppUser user) {
    final parts = <String>[
      if (user.age != null) '${user.age} yr',
      if (user.gender.trim().isNotEmpty) AppConstants.genderLabel(user.gender),
      if (user.allergies.isNotEmpty) 'Allergies: ${user.allergies.length}',
      if (user.pastDiseases.isNotEmpty)
        'Conditions: ${user.pastDiseases.length}',
    ];
    if (parts.isEmpty) {
      return 'Add if needed';
    }
    return parts.join(' • ');
  }

  String? _requiredName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object error, String fallback) {
    final raw = error.toString().trim();
    if (raw.isEmpty || raw.contains('TimeoutException')) {
      return fallback;
    }
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.isPremium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPremium ? AppColors.backgroundAlt : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        plan.label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: isPremium ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _PatientHistorySection extends StatelessWidget {
  const _PatientHistorySection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SymptomLog>>(
      stream: context.read<SymptomRepository>().streamPatientLogs(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!;
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Symptom history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              if (logs.isEmpty)
                const EmptyStateCard(
                  title: 'Nothing yet',
                  subtitle: 'Run an AI scan',
                  icon: Icons.monitor_heart_outlined,
                )
              else
                Column(
                  children: logs
                      .take(4)
                      .map((log) => _LogCard(log: log))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final SymptomLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppConstants.specialtyLabel(log.aiRecommendedSpecialty),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  AppFormatters.dateOnly.format(log.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (log.urgencyLevel != null) ...[
              const SizedBox(height: 10),
              UrgencyChip(urgencyLevel: log.urgencyLevel!),
            ],
            const SizedBox(height: 10),
            Text(
              log.symptomsText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (log.symptomImageUrl != null &&
                log.symptomImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AdaptiveImage(
                  imageUrl: log.symptomImageUrl!,
                  height: 120,
                  width: double.infinity,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
