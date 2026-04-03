import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/appointment_status.dart';
import '../../core/enums/urgency_level.dart';
import '../../core/utils/app_constants.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/appointment_repository.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/brand_badge.dart';
import '../../widgets/empty_state_card.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
      stream: context.read<AppointmentRepository>().streamDoctorAppointments(
        user.uid,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = [...snapshot.data!]
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
        if (appointments.isEmpty) {
          return const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandBadge(),
                SizedBox(height: 24),
                EmptyStateCard(
                  title: 'No visits',
                  subtitle: 'New requests appear here',
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return AppointmentCard(
              appointment: appointment,
              titleOverride: appointment.patientName,
              subtitleOverride: appointment.isFamilyBooking
                  ? '${AppConstants.specialtyLabel(appointment.specialty)} • ${AppConstants.familyBookingLabel(appointment.careRecipientRelation ?? '')}'
                  : null,
              showAiSummary: true,
              actions: [
                if (appointment.status == AppointmentStatus.pending)
                  ElevatedButton(
                    onPressed: () => context
                        .read<AppointmentRepository>()
                        .updateAppointmentStatus(
                          appointment,
                          AppointmentStatus.confirmed,
                        ),
                    child: const Text('Confirm'),
                  ),
                if (appointment.status == AppointmentStatus.pending)
                  OutlinedButton(
                    onPressed: () => context
                        .read<AppointmentRepository>()
                        .updateAppointmentStatus(
                          appointment,
                          AppointmentStatus.cancelled,
                        ),
                    child: const Text('Decline'),
                  ),
                if (appointment.status == AppointmentStatus.confirmed)
                  ElevatedButton(
                    onPressed: () => context
                        .read<AppointmentRepository>()
                        .updateAppointmentStatus(
                          appointment,
                          AppointmentStatus.completed,
                        ),
                    child: const Text('Complete'),
                  ),
              ],
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemCount: appointments.length,
        );
      },
    );
  }
}
