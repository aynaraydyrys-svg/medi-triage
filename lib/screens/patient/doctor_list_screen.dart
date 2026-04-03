import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/urgency_level.dart';
import '../../core/utils/app_constants.dart';
import '../../models/doctor_profile.dart';
import '../../models/doctor_trust_insight.dart';
import '../../models/symptom_log.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/doctor_repository.dart';
import '../../repositories/trusted_circle_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/doctor_card.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/urgency_chip.dart';
import 'booking_screen.dart';
import 'doctor_detail_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({
    super.key,
    this.specialty,
    this.symptomLog,
    this.embedded = false,
  });

  final String? specialty;
  final SymptomLog? symptomLog;
  final bool embedded;

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  late String _selectedCity;
  late String _selectedSpecialty;

  @override
  void initState() {
    super.initState();
    _selectedCity = '';
    _selectedSpecialty = widget.specialty ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.embedded ? 'Search' : 'Doctors',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              _FilterPanel(
                selectedCity: _selectedCity,
                selectedSpecialty: _selectedSpecialty,
                onCityChanged: (value) => setState(() => _selectedCity = value),
                onSpecialtyChanged: (value) =>
                    setState(() => _selectedSpecialty = value),
              ),
              if (widget.symptomLog != null) ...[
                const SizedBox(height: 14),
                SectionCard(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundAlt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.specialtyLabel(
                                widget.symptomLog!.aiRecommendedSpecialty,
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (widget.symptomLog!.urgencyLevel != null) ...[
                              const SizedBox(height: 8),
                              UrgencyChip(
                                urgencyLevel: widget.symptomLog!.urgencyLevel!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: context.read<DoctorRepository>().streamDoctors(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final auth = context.watch<AuthController>();
              final allDoctors = snapshot.data!;
              if (allDoctors.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: EmptyStateCard(
                    title: 'Loading doctors',
                    subtitle: 'Please wait',
                    icon: Icons.sync_rounded,
                  ),
                );
              }
              final searchResult = _resolveDoctors(allDoctors);
              final doctors = searchResult.doctors;

              return FutureBuilder<Map<String, DoctorTrustInsight>>(
                future: auth.currentUser == null
                    ? Future.value(<String, DoctorTrustInsight>{
                        for (final doctor in doctors)
                          doctor.doctorId: DoctorTrustInsight.empty(
                            doctor.doctorId,
                          ),
                      })
                    : context
                          .read<TrustedCircleRepository>()
                          .fetchTrustInsights(
                            patientId: auth.currentUser!.uid,
                            doctorIds: doctors.map((doctor) => doctor.doctorId),
                          ),
                builder: (context, trustSnapshot) {
                  final trustMap =
                      trustSnapshot.data ??
                      <String, DoctorTrustInsight>{
                        for (final doctor in doctors)
                          doctor.doctorId: DoctorTrustInsight.empty(
                            doctor.doctorId,
                          ),
                      };
                  final sortedDoctors = [...doctors]
                    ..sort((a, b) {
                      return _compareDoctors(
                        a,
                        b,
                        trustMap,
                        preferredCity: _selectedCity.isNotEmpty
                            ? _selectedCity
                            : (auth.currentUser?.city ?? ''),
                        urgentOnly: searchResult.isUrgent,
                      );
                    });

                  return Column(
                    children: [
                      if (searchResult.message != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: SectionCard(
                            backgroundColor: AppColors.backgroundAlt,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.tune_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    searchResult.message!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (sortedDoctors.isEmpty &&
                          searchResult.emptyStateTitle != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: EmptyStateCard(
                              title: searchResult.emptyStateTitle!,
                              subtitle:
                                  searchResult.emptyStateSubtitle ??
                                  'Check later',
                              icon: Icons.local_hospital_outlined,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemBuilder: (context, index) {
                              final doctor = sortedDoctors[index];
                              final bookableSlot = _resolveBookableSlot(
                                doctor,
                                urgentOnly: searchResult.isUrgent,
                              );
                              return DoctorCard(
                                doctor: doctor,
                                trustInsight: trustMap[doctor.doctorId],
                                showUrgentDetails: searchResult.isUrgent,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => DoctorDetailScreen(
                                      doctorId: doctor.doctorId,
                                      symptomLog: widget.symptomLog,
                                    ),
                                  ),
                                ),
                                onBookTap: bookableSlot == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => BookingScreen(
                                            doctor: doctor,
                                            selectedSlot: bookableSlot,
                                            symptomLog: widget.symptomLog,
                                            trustInsight:
                                                trustMap[doctor.doctorId],
                                          ),
                                        ),
                                      ),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemCount: sortedDoctors.length,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: AppGradientBackground(child: SafeArea(top: false, child: content)),
    );
  }

  _DoctorSearchResult _resolveDoctors(List<DoctorProfile> doctors) {
    final urgentLevel = widget.symptomLog?.urgencyLevel;
    final urgentOnly =
        urgentLevel == UrgencyLevel.bookToday ||
        urgentLevel == UrgencyLevel.emergency;
    if (urgentOnly) {
      return _resolveUrgentDoctors(doctors);
    }

    bool matchesCity(DoctorProfile doctor) =>
        _selectedCity.isEmpty || doctor.city == _selectedCity;
    bool matchesSpecialty(DoctorProfile doctor) =>
        _selectedSpecialty.isEmpty || doctor.specialty == _selectedSpecialty;

    final exactMatches = doctors
        .where((doctor) => matchesCity(doctor) && matchesSpecialty(doctor))
        .toList();
    if (exactMatches.isNotEmpty) {
      return _DoctorSearchResult(doctors: exactMatches);
    }

    final fallbackDoctors = <DoctorProfile>[];
    final seenDoctorIds = <String>{};

    if (_selectedCity.isNotEmpty) {
      for (final doctor in doctors.where(
        (doctor) => doctor.city == _selectedCity,
      )) {
        if (seenDoctorIds.add(doctor.doctorId)) {
          fallbackDoctors.add(doctor);
        }
      }
    }

    if (_selectedSpecialty.isNotEmpty) {
      for (final doctor in doctors.where(
        (doctor) => doctor.specialty == _selectedSpecialty,
      )) {
        if (seenDoctorIds.add(doctor.doctorId)) {
          fallbackDoctors.add(doctor);
        }
      }
    }

    if (fallbackDoctors.isNotEmpty) {
      return _DoctorSearchResult(
        doctors: fallbackDoctors,
        message: 'Showing the closest match',
      );
    }

    return _DoctorSearchResult(
      doctors: doctors,
      message: (_selectedCity.isNotEmpty || _selectedSpecialty.isNotEmpty)
          ? 'Showing all available doctors'
          : null,
    );
  }

  _DoctorSearchResult _resolveUrgentDoctors(List<DoctorProfile> doctors) {
    bool matchesCity(DoctorProfile doctor) =>
        _selectedCity.isEmpty || doctor.city == _selectedCity;
    bool matchesSpecialty(DoctorProfile doctor) =>
        _selectedSpecialty.isEmpty || doctor.specialty == _selectedSpecialty;

    final todayDoctors = doctors
        .where((doctor) => doctor.hasUrgentSlotToday)
        .toList();
    final exactToday = todayDoctors
        .where((doctor) => matchesCity(doctor) && matchesSpecialty(doctor))
        .toList();
    if (exactToday.isNotEmpty) {
      return const _DoctorSearchResult(doctors: <DoctorProfile>[]).copyWith(
        doctors: exactToday,
        message: 'Showing doctors for today',
        isUrgent: true,
      );
    }

    final cityToday = todayDoctors.where(matchesCity).toList();
    if (cityToday.isNotEmpty) {
      return const _DoctorSearchResult(doctors: <DoctorProfile>[]).copyWith(
        doctors: cityToday,
        message: 'Showing the nearest slots today',
        isUrgent: true,
      );
    }

    final specialtyToday = todayDoctors.where(matchesSpecialty).toList();
    if (specialtyToday.isNotEmpty) {
      return const _DoctorSearchResult(doctors: <DoctorProfile>[]).copyWith(
        doctors: specialtyToday,
        message: 'Showing today slots',
        isUrgent: true,
      );
    }

    if (todayDoctors.isNotEmpty) {
      return const _DoctorSearchResult(doctors: <DoctorProfile>[]).copyWith(
        doctors: todayDoctors,
        message: 'Showing doctors for today',
        isUrgent: true,
      );
    }

    return const _DoctorSearchResult(
      doctors: <DoctorProfile>[],
      message: 'No slots today',
      emptyStateTitle: 'No slots today',
      emptyStateSubtitle: 'Use urgent care',
      isUrgent: true,
    );
  }

  int _compareDoctors(
    DoctorProfile a,
    DoctorProfile b,
    Map<String, DoctorTrustInsight> trustMap, {
    required String preferredCity,
    required bool urgentOnly,
  }) {
    if (urgentOnly) {
      final aInPreferred = preferredCity.isNotEmpty && a.city == preferredCity;
      final bInPreferred = preferredCity.isNotEmpty && b.city == preferredCity;
      if (aInPreferred != bInPreferred) {
        return aInPreferred ? -1 : 1;
      }

      final aTime = a.nextAvailableTodaySlot;
      final bTime = b.nextAvailableTodaySlot;
      if (aTime != null && bTime != null) {
        final timeDiff = aTime.compareTo(bTime);
        if (timeDiff != 0) {
          return timeDiff;
        }
      }
    }

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
  }

  DateTime? _resolveBookableSlot(
    DoctorProfile doctor, {
    required bool urgentOnly,
  }) {
    return urgentOnly
        ? doctor.nextAvailableTodaySlot
        : doctor.nextAvailableSlot;
  }
}

class _DoctorSearchResult {
  const _DoctorSearchResult({
    required this.doctors,
    this.message,
    this.emptyStateTitle,
    this.emptyStateSubtitle,
    this.isUrgent = false,
  });

  final List<DoctorProfile> doctors;
  final String? message;
  final String? emptyStateTitle;
  final String? emptyStateSubtitle;
  final bool isUrgent;

  _DoctorSearchResult copyWith({
    List<DoctorProfile>? doctors,
    String? message,
    String? emptyStateTitle,
    String? emptyStateSubtitle,
    bool? isUrgent,
  }) {
    return _DoctorSearchResult(
      doctors: doctors ?? this.doctors,
      message: message ?? this.message,
      emptyStateTitle: emptyStateTitle ?? this.emptyStateTitle,
      emptyStateSubtitle: emptyStateSubtitle ?? this.emptyStateSubtitle,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.selectedCity,
    required this.selectedSpecialty,
    required this.onCityChanged,
    required this.onSpecialtyChanged,
  });

  final String selectedCity;
  final String selectedSpecialty;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onSpecialtyChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedCity,
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('All cities'),
              ),
              ...AppConstants.kzCities.map(
                (city) => DropdownMenuItem<String>(
                  value: city,
                  child: Text(AppConstants.cityLabel(city)),
                ),
              ),
            ],
            onChanged: (value) => onCityChanged(value ?? ''),
            decoration: const InputDecoration(labelText: 'City'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedSpecialty,
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('All specialties'),
              ),
              ...AppConstants.specialties.map(
                (specialty) => DropdownMenuItem<String>(
                  value: specialty,
                  child: Text(AppConstants.specialtyLabel(specialty)),
                ),
              ),
            ],
            onChanged: (value) => onSpecialtyChanged(value ?? ''),
            decoration: const InputDecoration(labelText: 'Specialty'),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.backgroundAlt,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Map',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedCity.isEmpty
                            ? 'Kazakhstan'
                            : AppConstants.cityLabel(selectedCity),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
