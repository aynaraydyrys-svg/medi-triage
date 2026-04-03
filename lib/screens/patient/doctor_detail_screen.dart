import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/enums/user_role.dart';
import '../../core/enums/doctor_availability_status.dart';
import '../../core/enums/urgency_level.dart';
import '../../core/utils/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/doctor_trust_insight.dart';
import '../../models/review.dart';
import '../../models/symptom_log.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/doctor_repository.dart';
import '../../repositories/review_repository.dart';
import '../../repositories/trusted_circle_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/network_avatar.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/review_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/slot_chip.dart';
import '../../widgets/trust_badge.dart';
import '../../widgets/urgency_chip.dart';
import 'booking_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({
    super.key,
    required this.doctorId,
    this.symptomLog,
  });

  final String doctorId;
  final SymptomLog? symptomLog;

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  DateTime? _selectedSlot;
  int _ratingVersion = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final urgentOnly =
        widget.symptomLog?.urgencyLevel == UrgencyLevel.bookToday ||
        widget.symptomLog?.urgencyLevel == UrgencyLevel.emergency;

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: StreamBuilder(
            stream: context.read<DoctorRepository>().streamDoctor(
              widget.doctorId,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final doctor = snapshot.data;
              if (doctor == null) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: EmptyStateCard(
                    title: 'Not found',
                    subtitle: 'Try again',
                    icon: Icons.person_search_outlined,
                  ),
                );
              }

              final visibleSlots = urgentOnly
                  ? doctor.availableSlots
                        .where(
                          (slot) =>
                              doctor.nextAvailableTodaySlot != null &&
                              slot.year ==
                                  doctor.nextAvailableTodaySlot!.year &&
                              slot.month ==
                                  doctor.nextAvailableTodaySlot!.month &&
                              slot.day == doctor.nextAvailableTodaySlot!.day &&
                              slot.isAfter(DateTime.now()),
                        )
                        .toList()
                  : doctor.availableSlots;

              if (_selectedSlot != null &&
                  !visibleSlots.contains(_selectedSlot)) {
                _selectedSlot = null;
              }

              return FutureBuilder<Map<String, DoctorTrustInsight>>(
                future: auth.currentUser == null
                    ? Future.value(<String, DoctorTrustInsight>{
                        doctor.doctorId: DoctorTrustInsight.empty(
                          doctor.doctorId,
                        ),
                      })
                    : context
                          .read<TrustedCircleRepository>()
                          .fetchTrustInsights(
                            patientId: auth.currentUser!.uid,
                            doctorIds: <String>[doctor.doctorId],
                          ),
                builder: (context, trustSnapshot) {
                  final trustInsight =
                      trustSnapshot.data?[doctor.doctorId] ??
                      DoctorTrustInsight.empty(doctor.doctorId);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  NetworkAvatar(
                                    name: doctor.name,
                                    imageUrl: doctor.profileImageUrl,
                                    radius: 36,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctor.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppConstants.specialtyLabel(
                                            doctor.specialty,
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            _StatPill(
                                              icon: Icons.location_on_outlined,
                                              label: AppConstants.cityLabel(
                                                doctor.city,
                                              ),
                                            ),
                                            if (urgentOnly)
                                              _StatPill(
                                                icon: Icons.place_outlined,
                                                label: doctor.displayAddress,
                                              ),
                                            _StatPill(
                                              icon: Icons
                                                  .workspace_premium_outlined,
                                              label:
                                                  '${doctor.yearsExperience} yr',
                                            ),
                                            _StatPill(
                                              icon: doctor.isAvailableToday
                                                  ? Icons.bolt_rounded
                                                  : Icons.schedule_outlined,
                                              label: doctor.isAvailableToday
                                                  ? 'Today'
                                                  : doctor
                                                        .availabilityStatus
                                                        .label,
                                              color: doctor.isAvailableToday
                                                  ? AppColors.success
                                                  : AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  RatingStars(
                                    rating: doctor.ratingAverage,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${doctor.ratingAverage.toStringAsFixed(1)} rating',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              if (auth.currentUser?.role ==
                                  UserRole.patient) ...[
                                const SizedBox(height: 12),
                                FutureBuilder<Review?>(
                                  key: ValueKey(
                                    '${doctor.doctorId}_${auth.currentUser!.uid}_$_ratingVersion',
                                  ),
                                  future: context
                                      .read<ReviewRepository>()
                                      .fetchPatientReview(
                                        doctorId: doctor.doctorId,
                                        patientId: auth.currentUser!.uid,
                                      ),
                                  builder: (context, reviewSnapshot) {
                                    final review = reviewSnapshot.data;
                                    return OutlinedButton.icon(
                                      onPressed: () => _showRatingDialog(
                                        doctorId: doctor.doctorId,
                                        doctorName: doctor.name,
                                        existingReview: review,
                                      ),
                                      icon: const Icon(
                                        Icons.star_outline_rounded,
                                      ),
                                      label: Text(
                                        review == null ? 'Rate' : 'My rating',
                                      ),
                                    );
                                  },
                                ),
                              ],
                              if (trustInsight.hasTrustedVisits) ...[
                                const SizedBox(height: 16),
                                TrustBadge(insight: trustInsight),
                                const SizedBox(height: 8),
                                Text(
                                  'Your circle',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: trustInsight.connectedPatientNames
                                      .map((name) => Chip(label: Text(name)))
                                      .toList(),
                                ),
                              ],
                              if (doctor.statusNote != null &&
                                  doctor.statusNote!.trim().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  doctor.statusNote!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.symptomLog != null) ...[
                          const SizedBox(height: 16),
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Why',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  AppConstants.specialtyLabel(
                                    widget.symptomLog!.aiRecommendedSpecialty,
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                if (widget.symptomLog!.urgencyLevel !=
                                    null) ...[
                                  const SizedBox(height: 12),
                                  UrgencyChip(
                                    urgencyLevel:
                                        widget.symptomLog!.urgencyLevel!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available slots',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              if (urgentOnly && visibleSlots.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerSoft,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No slots today',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Use urgent care',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                )
                              else if (visibleSlots.isEmpty)
                                const EmptyStateCard(
                                  title: 'No slots',
                                  subtitle: 'Try later',
                                  icon: Icons.event_busy_outlined,
                                )
                              else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: visibleSlots
                                      .map(
                                        (slot) => SlotChip(
                                          slot: slot,
                                          isSelected: _selectedSlot == slot,
                                          onTap: () {
                                            setState(() {
                                              _selectedSlot = slot;
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 18),
                              if (urgentOnly &&
                                  doctor.nextAvailableTodaySlot != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Text(
                                    'Today ${AppFormatters.timeOnly.format(doctor.nextAvailableTodaySlot!)} • ${doctor.displayAddress}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed: _selectedSlot == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => BookingScreen(
                                            doctor: doctor,
                                            selectedSlot: _selectedSlot!,
                                            symptomLog: widget.symptomLog,
                                            trustInsight: trustInsight,
                                          ),
                                        ),
                                      ),
                                child: const Text('Book'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Reviews',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder(
                          stream: context
                              .read<ReviewRepository>()
                              .streamDoctorReviews(doctor.doctorId),
                          builder: (context, reviewSnapshot) {
                            if (!reviewSnapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final reviews = reviewSnapshot.data!;
                            if (reviews.isEmpty) {
                              return const EmptyStateCard(
                                title: 'No reviews',
                                subtitle: 'Be the first',
                                icon: Icons.reviews_outlined,
                              );
                            }

                            return Column(
                              children: reviews
                                  .take(4)
                                  .map(
                                    (review) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: ReviewCard(review: review),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showRatingDialog({
    required String doctorId,
    required String doctorName,
    Review? existingReview,
  }) async {
    final auth = context.read<AuthController>();
    final reviewRepository = context.read<ReviewRepository>();
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    var rating = existingReview?.rating ?? 5;
    final commentController = TextEditingController(
      text: existingReview?.comment ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var isSaving = false;
        String? successMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(doctorName),
              content: successMessage != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundAlt,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          successMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: List.generate(
                            5,
                            (index) => ChoiceChip(
                              label: Text('${index + 1}'),
                              selected: rating == index + 1,
                              onSelected: isSaving
                                  ? null
                                  : (_) {
                                      setDialogState(() {
                                        rating = index + 1;
                                      });
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Review',
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (successMessage != null)
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(successMessage),
                    child: const Text('Done'),
                  )
                else ...[
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setDialogState(() {
                              isSaving = true;
                            });
                            try {
                              final review = Review(
                                reviewId:
                                    existingReview?.reviewId ??
                                    const Uuid().v4(),
                                doctorId: doctorId,
                                patientId: user.uid,
                                patientName: user.fullName,
                                rating: rating,
                                comment: commentController.text.trim(),
                                createdAt: DateTime.now(),
                              );
                              await reviewRepository.addReview(review);
                              if (!dialogContext.mounted) {
                                return;
                              }
                              setDialogState(() {
                                isSaving = false;
                                successMessage = 'Rating saved';
                              });
                            } catch (error) {
                              if (!dialogContext.mounted) {
                                return;
                              }
                              ScaffoldMessenger.maybeOf(
                                dialogContext,
                              )?.showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                              setDialogState(() {
                                isSaving = false;
                              });
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    commentController.dispose();

    if (result != null && mounted) {
      setState(() {
        _ratingVersion++;
      });
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(result)));
    }
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    this.color = AppColors.primaryDark,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
