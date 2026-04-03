import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/enums/appointment_status.dart';
import '../../core/enums/subscription_plan.dart';
import '../../core/enums/urgency_level.dart';
import '../../core/utils/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/appointment.dart';
import '../../models/doctor_profile.dart';
import '../../models/doctor_trust_insight.dart';
import '../../models/family_member.dart';
import '../../models/symptom_log.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/family_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/section_card.dart';
import '../../widgets/trust_badge.dart';
import '../../widgets/urgency_chip.dart';
import 'booking_confirmation_screen.dart';
import 'family_health_passport_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.doctor,
    required this.selectedSlot,
    this.symptomLog,
    this.trustInsight,
  });

  final DoctorProfile doctor;
  final DateTime selectedSlot;
  final SymptomLog? symptomLog;
  final DoctorTrustInsight? trustInsight;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const String _selfRecipientId = 'self';

  bool _isSubmitting = false;
  String _selectedRecipientId = _selfRecipientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: StreamBuilder<List<FamilyMember>>(
            stream: context.read<FamilyRepository>().streamFamilyMembers(
              context.read<AuthController>().currentUser?.uid ?? '',
            ),
            builder: (context, snapshot) {
              final familyMembers = snapshot.data ?? const <FamilyMember>[];
              final selectedFamilyMember = _resolveSelectedFamilyMember(
                familyMembers,
              );

              if (_selectedRecipientId != _selfRecipientId &&
                  selectedFamilyMember == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedRecipientId = _selfRecipientId;
                    });
                  }
                });
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.doctor.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              if (widget.trustInsight != null &&
                                  widget.trustInsight!.hasTrustedVisits)
                                TrustBadge(
                                  insight: widget.trustInsight!,
                                  compact: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow(
                            icon: Icons.schedule_rounded,
                            label: 'Time',
                            value: AppFormatters.appointment.format(
                              widget.selectedSlot,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            icon: Icons.location_on_outlined,
                            label: 'Clinic',
                            value: widget.doctor.clinicName,
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            icon: Icons.medical_services_outlined,
                            label: 'Doctor',
                            value: AppConstants.specialtyLabel(
                              widget.doctor.specialty,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'For',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const FamilyHealthPassportScreen(),
                                  ),
                                ),
                                child: const Text('Family'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ChoiceChip(
                                label: const Text('Myself'),
                                selected:
                                    _selectedRecipientId == _selfRecipientId,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedRecipientId = _selfRecipientId;
                                  });
                                },
                              ),
                              ...familyMembers.map(
                                (member) => ChoiceChip(
                                  label: Text(
                                    '${AppConstants.familyBookingLabel(member.relation)} • ${member.name}',
                                  ),
                                  selected:
                                      _selectedRecipientId == member.memberId,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedRecipientId = member.memberId;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (selectedFamilyMember != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '${selectedFamilyMember.name} • ${selectedFamilyMember.age} yr • ${AppConstants.genderLabel(selectedFamilyMember.gender)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          if (widget.symptomLog?.urgencyLevel != null) ...[
                            UrgencyChip(
                              urgencyLevel: widget.symptomLog!.urgencyLevel!,
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            _buildAiSummary(
                              context.read<AuthController>(),
                              selectedFamilyMember,
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      backgroundColor: AppColors.surfaceMuted,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          const Text('After booking: Busy'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _bookAppointment,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  FamilyMember? _resolveSelectedFamilyMember(List<FamilyMember> familyMembers) {
    if (_selectedRecipientId == _selfRecipientId) {
      return null;
    }
    for (final member in familyMembers) {
      if (member.memberId == _selectedRecipientId) {
        return member;
      }
    }
    return null;
  }

  String _buildAiSummary(AuthController auth, FamilyMember? familyMember) {
    final user = auth.currentUser;
    final isUrgent = _isUrgentCase;
    final history = familyMember?.chronicConditions.isNotEmpty == true
        ? familyMember!.chronicConditions.take(2).toList()
        : <String>[
            ...?user?.medicalHistory.take(2),
            ...?user?.pastDiseases.take(2),
          ];

    final summaryParts = <String>[
      if (familyMember != null)
        'For: ${familyMember.name} • ${AppConstants.relationLabel(familyMember.relation)}',
      if (widget.symptomLog?.symptomsText.isNotEmpty == true)
        'Symptoms: ${widget.symptomLog!.symptomsText}',
      if (widget.symptomLog?.urgencyLevel != null)
        'Urgency: ${widget.symptomLog!.urgencyLevel!.label}',
      if (user?.city.isNotEmpty == true)
        'City: ${AppConstants.cityLabel(user!.city)}',
      if (familyMember != null)
        'Age: ${familyMember.age}'
      else if (user?.age != null)
        'Age: ${user!.age}',
      if (familyMember != null && familyMember.gender.trim().isNotEmpty)
        'Gender: ${AppConstants.genderLabel(familyMember.gender)}'
      else if (user?.gender.isNotEmpty == true)
        'Gender: ${AppConstants.genderLabel(user!.gender)}',
      if (familyMember == null &&
          user?.basicMedicalInfo.isNotEmpty == true &&
          auth.subscriptionPlan != SubscriptionPlan.basic)
        'Medical note: ${user!.basicMedicalInfo}',
      if (history.isNotEmpty && auth.subscriptionPlan != SubscriptionPlan.basic)
        'History: ${history.join(', ')}',
      if (familyMember == null &&
          user?.allergies.isNotEmpty == true &&
          auth.subscriptionPlan != SubscriptionPlan.basic)
        'Allergies: ${user!.allergies.take(2).join(', ')}',
      if (familyMember != null &&
          familyMember.notes.trim().isNotEmpty &&
          auth.subscriptionPlan != SubscriptionPlan.basic)
        'Notes: ${familyMember.notes}'
      else if (user?.notes.isNotEmpty == true &&
          auth.subscriptionPlan != SubscriptionPlan.basic)
        'Notes: ${user!.notes}',
      if (widget.symptomLog?.symptomImageUrl != null &&
          auth.subscriptionPlan.hasAdvancedAiSummary)
        'Photo: added',
      if (isUrgent && auth.subscriptionPlan.hasPriorityUrgentMatching)
        'Priority: high',
    ];

    if (summaryParts.isEmpty) {
      return 'Direct doctor choice';
    }

    return summaryParts.join(' • ');
  }

  Future<void> _bookAppointment() async {
    final auth = context.read<AuthController>();
    final appointmentRepository = context.read<AppointmentRepository>();
    final familyRepository = context.read<FamilyRepository>();
    final notificationService = context.read<NotificationService>();
    final user = auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isUrgentCase && !_isToday(widget.selectedSlot)) {
        throw Exception('Today only');
      }

      final familyMembers = await familyRepository.fetchFamilyMembers(user.uid);
      final familyMember = _resolveSelectedFamilyMember(familyMembers);
      final patientName = familyMember?.name ?? user.fullName;

      final appointment = Appointment(
        appointmentId: const Uuid().v4(),
        patientId: user.uid,
        patientName: patientName,
        doctorId: widget.doctor.doctorId,
        doctorName: widget.doctor.name,
        doctorImageUrl: widget.doctor.profileImageUrl,
        specialty: widget.doctor.specialty,
        symptomsText: widget.symptomLog?.symptomsText.isNotEmpty == true
            ? widget.symptomLog!.symptomsText
            : 'Direct choice',
        symptomImageUrl: widget.symptomLog?.symptomImageUrl,
        slotTime: widget.selectedSlot,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        urgencyLevel: widget.symptomLog?.urgencyLevel,
        aiSummary: _buildAiSummary(auth, familyMember),
        familyMemberId: familyMember?.memberId,
        careRecipientRelation: familyMember?.relation,
        bookedByName: familyMember == null ? null : user.fullName,
      );

      await appointmentRepository.createAppointment(appointment);

      if (familyMember != null) {
        await familyRepository.appendVisitHistory(
          memberId: familyMember.memberId,
          entry:
              '${AppConstants.specialtyLabel(widget.doctor.specialty)} • ${AppFormatters.dateOnly.format(widget.selectedSlot)}',
        );
      }

      await _createDoctorNotification(
        appointment: appointment,
        bookedByUserName: user.fullName,
        patientName: patientName,
      );

      try {
        await notificationService.triggerBookingConfirmation(
          doctorName: widget.doctor.name,
          slotTime: widget.selectedSlot,
        );
      } catch (_) {}

      try {
        await notificationService.scheduleReminderPlaceholder(
          doctorName: widget.doctor.name,
          slotTime: widget.selectedSlot,
        );
      } catch (_) {}

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BookingConfirmationScreen(appointment: appointment),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().contains('Slot already booked')
          ? 'Busy'
          : error.toString();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createDoctorNotification({
    required Appointment appointment,
    required String bookedByUserName,
    required String patientName,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final notificationId = const Uuid().v4();

    await firestore
        .collection('doctor_notifications')
        .doc(notificationId)
        .set({
      'notificationId': notificationId,
      'doctorId': appointment.doctorId,
      'appointmentId': appointment.appointmentId,
      'patientId': appointment.patientId,
      'patientName': patientName,
      'bookedByName': bookedByUserName,
      'doctorName': appointment.doctorName,
      'specialty': appointment.specialty,
      'slotTime': Timestamp.fromDate(appointment.slotTime),
      'urgencyLevel': appointment.urgencyLevel?.value,
      'type': 'new_booking',
      'title': 'New booking',
      'body':
          '$patientName booked ${AppFormatters.appointment.format(appointment.slotTime)}',
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  bool get _isUrgentCase =>
      widget.symptomLog?.urgencyLevel == UrgencyLevel.bookToday ||
      widget.symptomLog?.urgencyLevel == UrgencyLevel.emergency;

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}