import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/appointment_status.dart';
import '../../core/enums/doctor_availability_status.dart';
import '../../core/enums/urgency_level.dart';
import '../../core/utils/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/doctor_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/brand_badge.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_card.dart';
import 'doctor_profile_edit_screen.dart';
import 'doctor_reviews_screen.dart';
import 'slot_management_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
      stream: context.read<DoctorRepository>().streamDoctor(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final doctor = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandBadge(),
              const SizedBox(height: 24),
              if (doctor == null)
                const _DoctorHero(
                  title: 'Create profile',
                  subtitle: 'Start visits',
                )
              else
                _DoctorHero(
                  title: doctor.name,
                  subtitle:
                      '${AppConstants.specialtyLabel(doctor.specialty)} • ${doctor.availabilityStatus.label}',
                ),
              const SizedBox(height: 20),
              if (doctor == null)
                EmptyStateCard(
                  title: 'No profile',
                  subtitle: 'Add your profile',
                  icon: Icons.medical_information_outlined,
                  action: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DoctorProfileEditScreen(),
                      ),
                    ),
                    child: const Text('Create profile'),
                  ),
                )
              else ...[
                StreamBuilder(
                  stream: context
                      .read<AppointmentRepository>()
                      .streamDoctorAppointments(user.uid),
                  builder: (context, appointmentSnapshot) {
                    if (!appointmentSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final appointments = appointmentSnapshot.data!;
                    final patientCount = appointments
                        .map((appointment) => appointment.patientId)
                        .toSet()
                        .length;
                    final pendingAppointments =
                        appointments
                            .where(
                              (appointment) =>
                                  appointment.status ==
                                  AppointmentStatus.pending,
                            )
                            .toList()
                          ..sort((a, b) {
                            final aUrgent =
                                a.urgencyLevel == UrgencyLevel.emergency ||
                                a.urgencyLevel == UrgencyLevel.bookToday;
                            final bUrgent =
                                b.urgencyLevel == UrgencyLevel.emergency ||
                                b.urgencyLevel == UrgencyLevel.bookToday;
                            if (aUrgent != bUrgent) {
                              return aUrgent ? -1 : 1;
                            }
                            return a.slotTime.compareTo(b.slotTime);
                          });
                    final upcomingAppointments = appointments.take(3).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetricCard(
                              title: 'Specialty',
                              value: AppConstants.specialtyLabel(
                                doctor.specialty,
                              ),
                              icon: Icons.medical_services_outlined,
                            ),
                            _MetricCard(
                              title: 'Rating',
                              value: doctor.ratingAverage.toStringAsFixed(1),
                              icon: Icons.star_rounded,
                            ),
                            _MetricCard(
                              title: 'Slots',
                              value: '${doctor.availableSlots.length}',
                              icon: Icons.event_available_outlined,
                            ),
                            _MetricCard(
                              title: 'Patients',
                              value: '$patientCount',
                              icon: Icons.groups_2_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tools',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const DoctorProfileEditScreen(),
                                  ),
                                ),
                                child: const Text('Profile'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const SlotManagementScreen(),
                                  ),
                                ),
                                child: const Text('Slots'),
                              ),
                              const SizedBox(height: 10),
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
                        const SizedBox(height: 20),
                        Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (pendingAppointments.isEmpty)
                          const EmptyStateCard(
                            title: 'No new items',
                            subtitle: 'Requests appear here',
                            icon: Icons.notifications_none_rounded,
                          )
                        else
                          Column(
                            children: pendingAppointments
                                .map(
                                  (appointment) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _DoctorNotificationCard(
                                      title:
                                          appointment.urgencyLevel ==
                                                  UrgencyLevel.emergency ||
                                              appointment.urgencyLevel ==
                                                  UrgencyLevel.bookToday
                                          ? 'New urgent booking'
                                          : 'New booking',
                                      subtitle:
                                          appointment.urgencyLevel ==
                                                  UrgencyLevel.emergency ||
                                              appointment.urgencyLevel ==
                                                  UrgencyLevel.bookToday
                                          ? 'Urgent patient for today'
                                          : appointment.isFamilyBooking
                                          ? AppConstants.familyBookingLabel(
                                              appointment
                                                      .careRecipientRelation ??
                                                  '',
                                            )
                                          : 'A patient booked with you',
                                      patientName: appointment.patientName,
                                      timeLabel: AppFormatters.appointment
                                          .format(appointment.slotTime),
                                      isUrgent:
                                          appointment.urgencyLevel ==
                                              UrgencyLevel.emergency ||
                                          appointment.urgencyLevel ==
                                              UrgencyLevel.bookToday,
                                    ),
                                  ),
                                )
                                .take(3)
                                .toList(),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Upcoming',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (upcomingAppointments.isEmpty)
                          const EmptyStateCard(
                            title: 'No visits',
                            subtitle: 'New requests appear here',
                            icon: Icons.calendar_today_outlined,
                          )
                        else
                          Column(
                            children: upcomingAppointments
                                .map(
                                  (appointment) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AppointmentCard(
                                      appointment: appointment,
                                      titleOverride: appointment.patientName,
                                      subtitleOverride:
                                          appointment.isFamilyBooking
                                          ? '${AppConstants.specialtyLabel(appointment.specialty)} • ${AppConstants.familyBookingLabel(appointment.careRecipientRelation ?? '')}'
                                          : null,
                                      showAiSummary: true,
                                      actions: const [],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DoctorNotificationCard extends StatelessWidget {
  const _DoctorNotificationCard({
    required this.title,
    required this.subtitle,
    required this.patientName,
    required this.timeLabel,
    this.isUrgent = false,
  });

  final String title;
  final String subtitle;
  final String patientName;
  final String timeLabel;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      backgroundColor: isUrgent ? AppColors.dangerSoft : AppColors.surfaceMuted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: isUrgent ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Priority',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  '$patientName • $timeLabel',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorHero extends StatelessWidget {
  const _DoctorHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: SectionCard(
        padding: const EdgeInsets.all(18),
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
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
