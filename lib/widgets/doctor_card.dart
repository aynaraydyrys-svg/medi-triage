import 'package:flutter/material.dart';

import '../core/enums/doctor_availability_status.dart';
import '../core/utils/app_constants.dart';
import '../core/utils/formatters.dart';
import '../models/doctor_trust_insight.dart';
import '../models/doctor_profile.dart';
import '../theme/app_colors.dart';
import 'network_avatar.dart';
import 'rating_stars.dart';
import 'section_card.dart';
import 'trust_badge.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.onBookTap,
    this.trustInsight,
    this.showUrgentDetails = false,
  });

  final DoctorProfile doctor;
  final VoidCallback onTap;
  final VoidCallback? onBookTap;
  final DoctorTrustInsight? trustInsight;
  final bool showUrgentDetails;

  @override
  Widget build(BuildContext context) {
    final nextSlot = showUrgentDetails
        ? doctor.nextAvailableTodaySlot
        : doctor.nextAvailableSlot;
    final availabilityLabel = nextSlot == null
        ? doctor.availabilityStatus.label
        : showUrgentDetails || doctor.isAvailableToday
        ? 'Today ${AppFormatters.timeOnly.format(nextSlot)}'
        : AppFormatters.timeOnly.format(nextSlot);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NetworkAvatar(
                  name: doctor.name,
                  imageUrl: doctor.profileImageUrl,
                  radius: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.specialtyLabel(doctor.specialty),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoTag(
                  icon: Icons.bolt_rounded,
                  label: availabilityLabel,
                  color: doctor.isAvailableToday
                      ? AppColors.success
                      : AppColors.primary,
                  background: doctor.isAvailableToday
                      ? AppColors.successSoft
                      : AppColors.backgroundAlt,
                ),
                if (doctor.offersTelehealth)
                  const _InfoTag(
                    icon: Icons.videocam_outlined,
                    label: 'Online',
                    color: AppColors.primary,
                    background: AppColors.backgroundAlt,
                  ),
                if (trustInsight != null && trustInsight!.hasTrustedVisits)
                  TrustBadge(insight: trustInsight!, compact: true),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetaPill(
                  icon: Icons.location_on_outlined,
                  label: AppConstants.cityLabel(doctor.city),
                ),
                _MetaPill(
                  icon: Icons.workspace_premium_outlined,
                  label: '${doctor.yearsExperience} yr',
                ),
              ],
            ),
            if (showUrgentDetails) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.clinicName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.displayAddress,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                RatingStars(rating: doctor.ratingAverage),
                const SizedBox(width: 8),
                Text(
                  '${doctor.ratingAverage.toStringAsFixed(1)} rating',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.backgroundAlt,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Profile'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBookTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

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
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
