import 'package:flutter/material.dart';

import '../../core/utils/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/appointment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/section_card.dart';
import '../../widgets/urgency_chip.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                colors: <Color>[
                                  AppColors.primary,
                                  Color(0xFF57B4FF),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Appointment booked',
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            appointment.doctorName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (appointment.isFamilyBooking) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${AppConstants.familyBookingLabel(appointment.careRecipientRelation ?? '')} • ${appointment.patientName}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            AppFormatters.appointment.format(
                              appointment.slotTime,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (appointment.urgencyLevel != null) ...[
                            const SizedBox(height: 14),
                            UrgencyChip(
                              urgencyLevel: appointment.urgencyLevel!,
                            ),
                          ],
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Check status in Visits',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
