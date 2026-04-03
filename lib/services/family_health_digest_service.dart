import '../core/enums/appointment_status.dart';
import '../core/utils/app_constants.dart';
import '../models/appointment.dart';
import '../models/family_digest_item.dart';
import '../models/family_member.dart';

class FamilyHealthDigestService {
  List<FamilyDigestItem> buildDigest({
    required List<FamilyMember> familyMembers,
    required List<Appointment> appointments,
  }) {
    if (familyMembers.isEmpty) {
      return const <FamilyDigestItem>[];
    }

    final now = DateTime.now();
    final digest = <FamilyDigestItem>[];

    for (final member in familyMembers) {
      final memberAppointments =
          appointments
              .where(
                (appointment) => appointment.familyMemberId == member.memberId,
              )
              .toList()
            ..sort((a, b) => a.slotTime.compareTo(b.slotTime));

      final pending = memberAppointments.cast<Appointment?>().firstWhere(
        (appointment) =>
            appointment != null &&
            appointment.status == AppointmentStatus.pending &&
            appointment.slotTime.isAfter(now),
        orElse: () => null,
      );
      if (pending != null) {
        digest.add(
          FamilyDigestItem(
            id: 'pending_${member.memberId}',
            title: 'Confirm visit?',
            subtitle: '${member.name} • ${_daysLabel(now, pending.slotTime)}',
            tone: FamilyDigestTone.alert,
            memberId: member.memberId,
          ),
        );
        continue;
      }

      final upcoming = memberAppointments.cast<Appointment?>().firstWhere(
        (appointment) =>
            appointment != null &&
            appointment.status != AppointmentStatus.cancelled &&
            appointment.slotTime.isAfter(now),
        orElse: () => null,
      );
      if (upcoming != null) {
        digest.add(
          FamilyDigestItem(
            id: 'upcoming_${member.memberId}',
            title: '${member.name}: visit soon',
            subtitle: _daysLabel(now, upcoming.slotTime),
            tone: FamilyDigestTone.action,
            memberId: member.memberId,
          ),
        );
        continue;
      }

      final lastVisit = memberAppointments.reversed
          .cast<Appointment?>()
          .firstWhere(
            (appointment) =>
                appointment != null &&
                appointment.status != AppointmentStatus.cancelled &&
                appointment.slotTime.isBefore(now),
            orElse: () => null,
          );

      if (lastVisit == null) {
        digest.add(
          FamilyDigestItem(
            id: 'empty_${member.memberId}',
            title: '${member.name}: no visits',
            subtitle:
                '${AppConstants.relationLabel(member.relation)} • time to check in',
            tone: FamilyDigestTone.calm,
            memberId: member.memberId,
          ),
        );
        continue;
      }

      final daysSinceVisit = now.difference(lastVisit.slotTime).inDays;
      if (daysSinceVisit >= 180) {
        digest.add(
          FamilyDigestItem(
            id: 'stale_${member.memberId}',
            title: '${member.name}: no visits',
            subtitle: '${daysSinceVisit ~/ 30} mo',
            tone: FamilyDigestTone.action,
            memberId: member.memberId,
          ),
        );
        continue;
      }

      if (member.chronicConditions.isNotEmpty) {
        digest.add(
          FamilyDigestItem(
            id: 'care_${member.memberId}',
            title: '${member.name}: follow-up',
            subtitle: member.chronicConditions.first,
            tone: FamilyDigestTone.calm,
            memberId: member.memberId,
          ),
        );
      }
    }

    return digest.take(4).toList();
  }

  String _daysLabel(DateTime now, DateTime appointmentDate) {
    final days = appointmentDate.difference(now).inDays;
    if (days <= 0) {
      return 'Today';
    }
    if (days == 1) {
      return 'Tomorrow';
    }
    if (days <= 14) {
      return 'In $days days';
    }
    return 'In ${days ~/ 7} weeks';
  }
}
