import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/appointment_status.dart';
import '../../models/review.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/review_repository.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/brand_badge.dart';
import '../../widgets/empty_state_card.dart';
import 'leave_review_screen.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
      stream: context.read<AppointmentRepository>().streamPatientAppointments(
        user.uid,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data!;
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
                  subtitle: 'Find a doctor',
                  icon: Icons.event_busy_outlined,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return FutureBuilder<Review?>(
              future: context.read<ReviewRepository>().fetchPatientReview(
                doctorId: appointment.doctorId,
                patientId: user.uid,
              ),
              builder: (context, reviewSnapshot) {
                final review = reviewSnapshot.data;

                return AppointmentCard(
                  appointment: appointment,
                  actions: [
                    if (appointment.status == AppointmentStatus.pending ||
                        appointment.status == AppointmentStatus.confirmed)
                      OutlinedButton(
                        onPressed: () async {
                          final approved = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Cancel appointment'),
                                content: const Text(
                                  'Are you sure you want to cancel this appointment?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (approved != true) return;
                          if (!context.mounted) return;

                          await context
                              .read<AppointmentRepository>()
                              .updateAppointmentStatus(
                                appointment,
                                AppointmentStatus.cancelled,
                              );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment cancelled'),
                            ),
                          );
                        },
                        child: const Text('Cancel'),
                      ),
                    if (appointment.status == AppointmentStatus.completed &&
                        review == null)
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.of(context)
                              .push<String>(
                                MaterialPageRoute<String>(
                                  builder: (_) => LeaveReviewScreen(
                                    appointment: appointment,
                                  ),
                                ),
                              );
                          if (result == null || !context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(result)));
                        },
                        child: const Text('Review'),
                      ),
                    if (review != null)
                      OutlinedButton(
                        onPressed: () async {
                          final approved = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Delete review'),
                                content: const Text(
                                  'Are you sure you want to delete this review?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (approved != true) return;
                          if (!context.mounted) return;

                          await context.read<ReviewRepository>().deleteReview(
                            reviewId: review.reviewId,
                            doctorId: review.doctorId,
                          );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Review deleted')),
                          );
                        },
                        child: const Text('Delete review'),
                      ),
                    if (appointment.status == AppointmentStatus.cancelled ||
                        appointment.status == AppointmentStatus.completed)
                      FilledButton.tonal(
                        onPressed: () async {
                          final approved = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Delete appointment'),
                                content: const Text(
                                  'Are you sure you want to permanently delete this appointment?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (approved != true) return;
                          if (!context.mounted) return;

                          await context
                              .read<AppointmentRepository>()
                              .deleteAppointment(appointment.appointmentId);

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment deleted'),
                            ),
                          );
                        },
                        child: const Text('Delete booking'),
                      ),
                  ],
                );
              },
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemCount: appointments.length,
        );
      },
    );
  }
}