import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_controller.dart';
import '../../repositories/doctor_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_card.dart';

class SlotManagementScreen extends StatelessWidget {
  const SlotManagementScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final content = StreamBuilder(
      stream: context.read<DoctorRepository>().streamDoctor(user.uid),
      builder: (context, snapshot) {
        final doctor = snapshot.data;
        if (doctor == null) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: EmptyStateCard(
              title: 'Profile first',
              subtitle: 'Save your profile',
              icon: Icons.schedule_outlined,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slots',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Available time',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _pickDateTimeAndAddSlot(context, doctor.doctorId),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (doctor.availableSlots.isEmpty)
              const EmptyStateCard(
                title: 'No slots',
                subtitle: 'Add a slot',
                icon: Icons.event_available_outlined,
              )
            else
              ...doctor.availableSlots.map(
                (slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
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
                            Icons.schedule_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${slot.day}/${slot.month}/${slot.year} • ${TimeOfDay.fromDateTime(slot).format(context)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => context
                              .read<DoctorRepository>()
                              .removeAvailableSlot(doctor.doctorId, slot),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Slots')),
      body: AppGradientBackground(child: SafeArea(top: false, child: content)),
    );
  }

  Future<void> _pickDateTimeAndAddSlot(
    BuildContext context,
    String doctorId,
  ) async {
    final doctorRepository = context.read<DoctorRepository>();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (date == null || !context.mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) {
      return;
    }

    final slot = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    await doctorRepository.addAvailableSlot(doctorId, slot);
  }
}
