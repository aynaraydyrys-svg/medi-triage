import 'package:flutter/material.dart';

import '../core/enums/urgency_level.dart';
import '../core/utils/app_constants.dart';
import '../core/utils/formatters.dart';
import '../models/appointment.dart';
import '../theme/app_colors.dart';
import 'adaptive_image.dart';
import 'network_avatar.dart';
import 'section_card.dart';
import 'status_chip.dart';
import 'urgency_chip.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.actions,
    this.titleOverride,
    this.subtitleOverride,
    this.showAiSummary = false,
  });

  final Appointment appointment;
  final List<Widget> actions;
  final String? titleOverride;
  final String? subtitleOverride;
  final bool showAiSummary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NetworkAvatar(
                name: titleOverride ?? appointment.doctorName,
                imageUrl: titleOverride == null
                    ? appointment.doctorImageUrl
                    : null,
                radius: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleOverride ?? appointment.doctorName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleOverride ??
                          AppConstants.specialtyLabel(appointment.specialty),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: appointment.status),
                  if (appointment.urgencyLevel != null) ...[
                    const SizedBox(height: 8),
                    UrgencyChip(
                      urgencyLevel: appointment.urgencyLevel!,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  AppFormatters.appointment.format(appointment.slotTime),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (appointment.isFamilyBooking ||
              (appointment.bookedByName?.trim().isNotEmpty ?? false) ||
              appointment.urgencyLevel == UrgencyLevel.bookToday ||
              appointment.urgencyLevel == UrgencyLevel.emergency) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (appointment.isFamilyBooking)
                  _InfoPill(
                    label:
                        '${AppConstants.familyBookingLabel(appointment.careRecipientRelation ?? '')} • ${appointment.patientName}',
                  ),
                if (appointment.bookedByName?.trim().isNotEmpty == true)
                  _InfoPill(label: 'Booked by: ${appointment.bookedByName}'),
                if (appointment.urgencyLevel == UrgencyLevel.bookToday ||
                    appointment.urgencyLevel == UrgencyLevel.emergency)
                  const _InfoPill(label: 'Priority'),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            appointment.symptomsText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (showAiSummary && appointment.aiSummary != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundAlt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appointment.aiSummary!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (appointment.symptomImageUrl != null &&
                      appointment.symptomImageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AdaptiveImage(
                        imageUrl: appointment.symptomImageUrl!,
                        height: 120,
                        width: double.infinity,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(spacing: 12, runSpacing: 12, children: actions),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
