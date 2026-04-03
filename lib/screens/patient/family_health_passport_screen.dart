import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/enums/appointment_status.dart';
import '../../core/enums/subscription_plan.dart';
import '../../core/utils/app_constants.dart';
import '../../models/appointment.dart';
import '../../models/family_digest_item.dart';
import '../../models/family_member.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/family_repository.dart';
import '../../services/family_health_digest_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_card.dart';
import '../common/plan_selection_screen.dart';

class FamilyHealthPassportScreen extends StatelessWidget {
  const FamilyHealthPassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: StreamBuilder<List<FamilyMember>>(
            stream: context.read<FamilyRepository>().streamFamilyMembers(
              user.uid,
            ),
            builder: (context, familySnapshot) {
              if (!familySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final familyMembers = familySnapshot.data!;
              return StreamBuilder<List<Appointment>>(
                stream: context
                    .read<AppointmentRepository>()
                    .streamPatientAppointments(user.uid),
                builder: (context, appointmentSnapshot) {
                  final appointments =
                      appointmentSnapshot.data ?? const <Appointment>[];
                  final digest = context
                      .read<FamilyHealthDigestService>()
                      .buildDigest(
                        familyMembers: familyMembers,
                        appointments: appointments,
                      );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(
                          familyCount: familyMembers.length,
                          planLabel: auth.subscriptionPlan.label,
                          familyLimitLabel:
                              auth.subscriptionPlan.familyMemberLimit == null
                              ? 'No limit'
                              : 'Up to ${auth.subscriptionPlan.familyMemberLimit}',
                          onAdd: () => _openEditor(context),
                        ),
                        const SizedBox(height: 18),
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Family digest',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _openEditor(context),
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (familyMembers.isEmpty)
                                const EmptyStateCard(
                                  title: 'No members',
                                  subtitle: 'Add family',
                                  icon: Icons.groups_2_outlined,
                                )
                              else if (digest.isEmpty)
                                const _DigestPlaceholder()
                              else
                                Column(
                                  children: digest
                                      .map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _DigestCard(item: item),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Family members',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () => _openEditor(context),
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (familyMembers.isEmpty)
                                const _FamilyEmptyState()
                              else
                                Column(
                                  children: familyMembers
                                      .map(
                                        (member) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _FamilyMemberCard(
                                            member: member,
                                            appointmentCount: appointments
                                                .where(
                                                  (appointment) =>
                                                      appointment
                                                              .familyMemberId ==
                                                          member.memberId &&
                                                      appointment.status !=
                                                          AppointmentStatus
                                                              .cancelled,
                                                )
                                                .length,
                                            onEdit: () => _openEditor(
                                              context,
                                              member: member,
                                            ),
                                            onDelete: () =>
                                                _deleteMember(context, member),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
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

  Future<void> _openEditor(BuildContext context, {FamilyMember? member}) async {
    final auth = context.read<AuthController>();
    final owner = auth.currentUser;
    if (owner == null) {
      return;
    }

    if (member == null) {
      final members = await context.read<FamilyRepository>().fetchFamilyMembers(
        owner.uid,
      );
      if (!context.mounted) {
        return;
      }
      final familyLimit = auth.subscriptionPlan.familyMemberLimit;
      if (familyLimit != null && members.length >= familyLimit) {
        final openPlans = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final target = auth.upgradeTargetPlan;
            return AlertDialog(
              title: const Text('Limit reached'),
              content: Text('Family: up to $familyLimit'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Later'),
                ),
                if (target != null)
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text('Upgrade to ${target.label}'),
                  ),
              ],
            );
          },
        );
        if (openPlans == true && context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PlanSelectionScreen(),
            ),
          );
        }
        return;
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FamilyMemberFormScreen(member: member),
      ),
    );
  }

  Future<void> _deleteMember(BuildContext context, FamilyMember member) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete'),
          content: Text(member.name),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (approved != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    await context.read<FamilyRepository>().deleteFamilyMember(member.memberId);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.familyCount,
    required this.planLabel,
    required this.familyLimitLabel,
    required this.onAdd,
  });

  final int familyCount;
  final String planLabel;
  final String familyLimitLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0F6FFF), Color(0xFF57B4FF)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.glowBlue,
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family Passport',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            familyCount == 0
                ? 'One account for the family'
                : '$familyCount managed',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(label: planLabel),
              _HeroPill(label: 'Limit: $familyLimitLabel'),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DigestPlaceholder extends StatelessWidget {
  const _DigestPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Reminders appear here',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _FamilyEmptyState extends StatelessWidget {
  const _FamilyEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      title: 'Family is empty',
      subtitle: 'Add a child or parent',
      icon: Icons.group_add_outlined,
    );
  }
}

class _DigestCard extends StatelessWidget {
  const _DigestCard({required this.item});

  final FamilyDigestItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (item.tone) {
      FamilyDigestTone.calm => (
        Icons.favorite_border_rounded,
        AppColors.primary,
        AppColors.backgroundAlt,
      ),
      FamilyDigestTone.action => (
        Icons.schedule_rounded,
        AppColors.warning,
        AppColors.warningSoft,
      ),
      FamilyDigestTone.alert => (
        Icons.notifications_active_outlined,
        AppColors.danger,
        AppColors.dangerSoft,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
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
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({
    required this.member,
    required this.appointmentCount,
    required this.onEdit,
    required this.onDelete,
  });

  final FamilyMember member;
  final int appointmentCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppConstants.relationLabel(member.relation)} • ${member.age} yr • ${AppConstants.genderLabel(member.gender)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$appointmentCount visits',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (member.chronicConditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: member.chronicConditions
                  .take(2)
                  .map((condition) => Chip(label: Text(condition)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            member.visitHistory.isEmpty
                ? 'History: none yet'
                : 'History: ${member.visitHistory.first}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (member.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(member.notes, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              TextButton(onPressed: onDelete, child: const Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FamilyMemberFormScreen extends StatefulWidget {
  const _FamilyMemberFormScreen({this.member});

  final FamilyMember? member;

  @override
  State<_FamilyMemberFormScreen> createState() =>
      _FamilyMemberFormScreenState();
}

class _FamilyMemberFormScreenState extends State<_FamilyMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _notesController;
  late String _selectedGender;
  late String _selectedRelation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _ageController = TextEditingController(
      text: widget.member == null ? '' : '${widget.member!.age}',
    );
    _conditionsController = TextEditingController(
      text: widget.member?.chronicConditions.join(', ') ?? '',
    );
    _notesController = TextEditingController(text: widget.member?.notes ?? '');
    _selectedGender =
        widget.member != null &&
            AppConstants.patientGenders.contains(widget.member!.gender)
        ? widget.member!.gender
        : AppConstants.patientGenders.first;
    _selectedRelation =
        widget.member != null &&
            AppConstants.familyRelations.contains(widget.member!.relation)
        ? widget.member!.relation
        : AppConstants.familyRelations.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.member == null ? 'Add' : 'Edit')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SectionCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.member == null
                          ? 'New family member'
                          : 'Family member',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age'),
                      validator: (value) {
                        final age = int.tryParse((value ?? '').trim());
                        if (age == null || age < 0 || age > 120) {
                          return 'Age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      items: AppConstants.patientGenders
                          .map(
                            (gender) => DropdownMenuItem<String>(
                              value: gender,
                              child: Text(AppConstants.genderLabel(gender)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRelation,
                      items: AppConstants.familyRelations
                          .map(
                            (relation) => DropdownMenuItem<String>(
                              value: relation,
                              child: Text(AppConstants.relationLabel(relation)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedRelation = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Relation'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _conditionsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Conditions',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text('History appears after visits'),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(onPressed: _save, child: const Text('Save')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final owner = context.read<AuthController>().currentUser;
    if (owner == null) {
      return;
    }

    final now = DateTime.now();
    final member = FamilyMember(
      memberId: widget.member?.memberId ?? const Uuid().v4(),
      ownerId: owner.uid,
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _selectedGender,
      relation: _selectedRelation,
      chronicConditions: AppConstants.parseItems(_conditionsController.text),
      notes: _notesController.text.trim(),
      visitHistory: widget.member?.visitHistory ?? const <String>[],
      createdAt: widget.member?.createdAt ?? now,
      updatedAt: now,
    );

    await context.read<FamilyRepository>().upsertFamilyMember(member);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}
